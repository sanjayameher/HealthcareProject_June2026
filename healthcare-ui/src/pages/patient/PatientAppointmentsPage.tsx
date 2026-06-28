import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { format } from 'date-fns';
import { Plus } from 'lucide-react';
import { portalApi } from '@/api/portalApi';
import { useAuthStore } from '@/store/authStore';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { DataTable } from '@/components/common/DataTable';
import { StatusBadge } from '@/components/common/StatusBadge';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import type { PortalAppointment, AvailabilitySlot, Practitioner } from '@/types';

export function PatientAppointmentsPage() {
  const { user } = useAuthStore();
  const patientId = user?.userId ?? '';
  const qc = useQueryClient();
  const [cancelTarget, setCancelTarget] = useState<PortalAppointment | null>(null);
  const [bookOpen, setBookOpen] = useState(false);

  // Booking wizard state
  const [doctorSearch, setDoctorSearch] = useState('');
  const [selectedDoctor, setSelectedDoctor] = useState<Practitioner | null>(null);
  const [selectedDate, setSelectedDate] = useState('');
  const [selectedSlot, setSelectedSlot] = useState<AvailabilitySlot | null>(null);

  const { data: appointments = [], isLoading } = useQuery({
    queryKey: ['patient-appointments', patientId],
    queryFn: () => portalApi.getPatientAppointments(patientId),
    enabled: !!patientId,
  });

  const { data: doctors = [] } = useQuery({
    queryKey: ['browse-doctors', doctorSearch],
    queryFn: () => portalApi.browseDoctors(doctorSearch || undefined),
    enabled: bookOpen,
  });

  const { data: slots = [] } = useQuery({
    queryKey: ['patient-slots', selectedDoctor?.id, selectedDate],
    queryFn: () => portalApi.getDoctorAvailability(selectedDoctor!.id, selectedDate),
    enabled: !!selectedDoctor && !!selectedDate,
  });

  const cancelMutation = useMutation({
    mutationFn: () => portalApi.cancelAppointmentPatient(cancelTarget!.id),
    onSuccess: () => {
      toast.success('Appointment cancelled');
      qc.invalidateQueries({ queryKey: ['patient-appointments'] });
      setCancelTarget(null);
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const bookMutation = useMutation({
    mutationFn: () => portalApi.bookAppointmentPatient(patientId, {
      patientId,
      practitionerId: selectedDoctor!.id,
      slotId: selectedSlot!.id,
      startTime: `${selectedDate}T${selectedSlot!.startTime}Z`,
      endTime:   `${selectedDate}T${selectedSlot!.endTime}Z`,
      appointmentTypeCode: 'ROUTINE',
    }),
    onSuccess: () => {
      toast.success('Appointment booked');
      qc.invalidateQueries({ queryKey: ['patient-appointments'] });
      setBookOpen(false);
      setSelectedDoctor(null);
      setSelectedDate('');
      setSelectedSlot(null);
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const columns = [
    {
      key: 'date', header: 'Date & Time',
      render: (a: PortalAppointment) => (
        <div>
          <p className="font-medium">{format(new Date(a.startTime), 'EEE, MMM d, yyyy')}</p>
          <p className="text-xs text-gray-500">{format(new Date(a.startTime), 'h:mm a')}</p>
        </div>
      ),
    },
    {
      key: 'type', header: 'Type',
      render: (a: PortalAppointment) => a.appointmentTypeCode ?? 'Routine',
    },
    {
      key: 'status', header: 'Status',
      render: (a: PortalAppointment) => <StatusBadge status={a.status} />,
    },
    {
      key: 'actions', header: '',
      render: (a: PortalAppointment) =>
        a.status === 'booked' || a.status === 'pending' ? (
          <Button size="sm" variant="destructive"
            onClick={(e) => { e.stopPropagation(); setCancelTarget(a); }}>
            Cancel
          </Button>
        ) : null,
    },
  ];

  return (
    <PortalPageWrapper title="My Appointments">
      <PageHeader
        title="My Appointments"
        subtitle="Your upcoming and past appointments"
        actions={
          <Button onClick={() => setBookOpen(true)} className="gap-2 bg-sky-600 hover:bg-sky-700">
            <Plus className="w-4 h-4" /> Book Appointment
          </Button>
        }
      />

      <DataTable
        columns={columns}
        data={appointments}
        loading={isLoading}
        keyExtractor={(a) => a.id}
        emptyMessage="No appointments found."
      />

      <ConfirmDialog
        open={!!cancelTarget}
        title="Cancel this appointment?"
        description="This action cannot be undone. The time slot will be released."
        confirmLabel="Cancel Appointment"
        variant="destructive"
        onConfirm={() => cancelMutation.mutate()}
        onCancel={() => setCancelTarget(null)}
      />

      {/* Book appointment dialog */}
      <Dialog open={bookOpen} onOpenChange={(o) => { if (!o) { setBookOpen(false); setSelectedDoctor(null); setSelectedDate(''); setSelectedSlot(null); } }}>
        <DialogContent className="max-w-lg">
          <DialogHeader><DialogTitle>Book an Appointment</DialogTitle></DialogHeader>
          <div className="space-y-4">
            {/* Doctor selection */}
            <div className="space-y-2">
              <Label>Find a Doctor</Label>
              <Input placeholder="Search by name…" value={doctorSearch}
                onChange={(e) => { setDoctorSearch(e.target.value); setSelectedDoctor(null); }} />
              {!selectedDoctor && doctors.length > 0 && (
                <div className="border rounded divide-y max-h-40 overflow-y-auto text-sm">
                  {doctors.map((d) => (
                    <button key={d.id} onClick={() => setSelectedDoctor(d)}
                      className="w-full text-left px-3 py-2 hover:bg-sky-50">
                      {d.givenName} {d.familyName}
                    </button>
                  ))}
                </div>
              )}
              {selectedDoctor && (
                <div className="flex items-center justify-between rounded border bg-sky-50 px-3 py-2 text-sm">
                  <span className="font-medium text-sky-800">{selectedDoctor.givenName} {selectedDoctor.familyName}</span>
                  <button className="text-xs text-gray-500 hover:text-red-500"
                    onClick={() => { setSelectedDoctor(null); setSelectedDate(''); setSelectedSlot(null); }}>
                    Change
                  </button>
                </div>
              )}
            </div>

            {/* Date selection */}
            {selectedDoctor && (
              <div className="space-y-1">
                <Label>Select Date</Label>
                <Input type="date" value={selectedDate}
                  onChange={(e) => { setSelectedDate(e.target.value); setSelectedSlot(null); }} />
              </div>
            )}

            {/* Slot selection */}
            {selectedDate && slots.length > 0 && (
              <div className="space-y-1">
                <Label>Available Times</Label>
                <div className="grid grid-cols-3 gap-2">
                  {slots.map((s) => (
                    <button key={s.id} onClick={() => setSelectedSlot(s)}
                      className={`px-2 py-1.5 rounded border text-sm text-center hover:bg-sky-50
                        ${selectedSlot?.id === s.id ? 'border-sky-500 bg-sky-50 font-medium' : ''}`}>
                      {s.startTime.substring(0, 5)}
                    </button>
                  ))}
                </div>
              </div>
            )}
            {selectedDate && slots.length === 0 && (
              <p className="text-sm text-gray-500 text-center py-2">No available slots for this date.</p>
            )}

            <div className="flex justify-end gap-2 pt-2">
              <Button variant="outline" onClick={() => setBookOpen(false)}>Cancel</Button>
              <Button disabled={!selectedSlot || bookMutation.isPending}
                onClick={() => bookMutation.mutate()}
                className="bg-sky-600 hover:bg-sky-700">
                {bookMutation.isPending ? 'Booking…' : 'Confirm Booking'}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </PortalPageWrapper>
  );
}