import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation } from '@tanstack/react-query';
import { toast } from 'sonner';
import { format } from 'date-fns';
import { ChevronRight } from 'lucide-react';
import { portalApi } from '@/api/portalApi';
import { patientApi } from '@/api/patientApi';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import type { Patient, Practitioner, AvailabilitySlot } from '@/types';

type Step = 1 | 2 | 3 | 4;

export function BookAppointmentPage() {
  const navigate = useNavigate();
  const [step, setStep] = useState<Step>(1);
  const [patientSearch, setPatientSearch] = useState('');
  const [doctorSearch, setDoctorSearch] = useState('');
  const [selectedPatient, setSelectedPatient] = useState<Patient | null>(null);
  const [selectedDoctor, setSelectedDoctor] = useState<Practitioner | null>(null);
  const [selectedDate, setSelectedDate] = useState('');
  const [selectedSlot, setSelectedSlot] = useState<AvailabilitySlot | null>(null);
  const [apptType, setApptType] = useState('ROUTINE');
  const [description, setDescription] = useState('');

  const isMrnSearch = /^(MRN|mrn|\d)/i.test(patientSearch);
  const { data: patients = [] } = useQuery({
    queryKey: ['patient-search', patientSearch],
    queryFn: () => patientApi.searchPatients(
      isMrnSearch ? { mrn: patientSearch.toUpperCase() } : { name: patientSearch }
    ),
    enabled: patientSearch.trim().length > 1,
  });

  const { data: doctors = [] } = useQuery({
    queryKey: ['doctor-search', doctorSearch],
    queryFn: () => doctorSearch ? portalApi.searchDoctors(doctorSearch) : portalApi.listDoctors(),
  });

  const { data: slots = [] } = useQuery({
    queryKey: ['slots-date', selectedDoctor?.id, selectedDate],
    queryFn: () => portalApi.getAvailableSlots(selectedDoctor!.id, selectedDate),
    enabled: !!selectedDoctor && !!selectedDate,
  });

  const bookMutation = useMutation({
    mutationFn: () => portalApi.bookAppointmentAdmin({
      patientId: selectedPatient!.id,
      practitionerId: selectedDoctor!.id,
      slotId: selectedSlot!.id,
      startTime: `${selectedDate}T${selectedSlot!.startTime}Z`,
      endTime:   `${selectedDate}T${selectedSlot!.endTime}Z`,
      appointmentTypeCode: apptType,
      description,
    }),
    onSuccess: () => { toast.success('Appointment booked successfully'); navigate('/admin/queue'); },
    onError: (e: Error) => toast.error(e.message),
  });

  return (
    <PortalPageWrapper title="Book Appointment">
      {/* Step indicator */}
      <div className="flex items-center gap-2 mb-8 text-sm">
        {(['Select Patient', 'Select Doctor', 'Select Slot', 'Confirm'] as const).map((label, i) => (
          <div key={label} className="flex items-center gap-2">
            <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold
              ${step > i + 1 ? 'bg-emerald-500 text-white' : step === i + 1 ? 'bg-violet-600 text-white' : 'bg-gray-200 text-gray-500'}`}>
              {i + 1}
            </div>
            <span className={step === i + 1 ? 'font-medium' : 'text-gray-400'}>{label}</span>
            {i < 3 && <ChevronRight className="w-4 h-4 text-gray-300" />}
          </div>
        ))}
      </div>

      {/* Step 1: Select Patient */}
      {step === 1 && (
        <Card>
          <CardHeader><CardTitle>Step 1 — Select Patient</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            <Input placeholder="Search by name or MRN…" value={patientSearch}
              onChange={(e) => setPatientSearch(e.target.value)} />
            <div className="space-y-1 max-h-72 overflow-y-auto">
              {patients.map((p) => (
                <button key={p.id} onClick={() => { setSelectedPatient(p); setStep(2); }}
                  className="w-full text-left px-3 py-2 rounded border hover:bg-violet-50 text-sm flex justify-between">
                  <span>{p.names?.[0]?.given?.join(' ')} {p.names?.[0]?.family}</span>
                  <span className="text-gray-400 font-mono">{p.mrn}</span>
                </button>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Step 2: Select Doctor */}
      {step === 2 && (
        <Card>
          <CardHeader><CardTitle>Step 2 — Select Doctor</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            <Input placeholder="Search by name…" value={doctorSearch}
              onChange={(e) => setDoctorSearch(e.target.value)} />
            <div className="space-y-1 max-h-72 overflow-y-auto">
              {doctors.map((d) => (
                <button key={d.id} onClick={() => { setSelectedDoctor(d); setStep(3); }}
                  className="w-full text-left px-3 py-2 rounded border hover:bg-violet-50 text-sm flex justify-between">
                  <span className="font-medium">{d.givenName} {d.familyName}</span>
                  <span className="text-gray-400">{d.npi ?? 'No NPI'}</span>
                </button>
              ))}
            </div>
            <Button variant="ghost" onClick={() => setStep(1)}>← Back</Button>
          </CardContent>
        </Card>
      )}

      {/* Step 3: Select Slot */}
      {step === 3 && (
        <Card>
          <CardHeader><CardTitle>Step 3 — Select Date & Slot</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            <div className="space-y-1">
              <Label>Date</Label>
              <Input type="date" value={selectedDate} onChange={(e) => setSelectedDate(e.target.value)} />
            </div>
            {slots.length > 0 ? (
              <div className="grid grid-cols-3 gap-2 mt-3">
                {slots.map((s) => (
                  <button key={s.id} onClick={() => { setSelectedSlot(s); setStep(4); }}
                    className={`px-3 py-2 rounded border text-sm text-center hover:bg-violet-50
                      ${selectedSlot?.id === s.id ? 'border-violet-600 bg-violet-50' : ''}`}>
                    {s.startTime.substring(0, 5)} – {s.endTime.substring(0, 5)}
                  </button>
                ))}
              </div>
            ) : selectedDate ? (
              <p className="text-sm text-gray-500 py-4 text-center">No available slots for this date.</p>
            ) : null}
            <Button variant="ghost" onClick={() => setStep(2)}>← Back</Button>
          </CardContent>
        </Card>
      )}

      {/* Step 4: Confirm */}
      {step === 4 && selectedPatient && selectedDoctor && selectedSlot && (
        <Card>
          <CardHeader><CardTitle>Step 4 — Confirm Booking</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <p className="text-gray-500">Patient</p>
                <p className="font-medium">{selectedPatient.names?.[0]?.given?.join(' ')} {selectedPatient.names?.[0]?.family}</p>
                <p className="text-gray-400 font-mono text-xs">{selectedPatient.mrn}</p>
              </div>
              <div>
                <p className="text-gray-500">Doctor</p>
                <p className="font-medium">{selectedDoctor.givenName} {selectedDoctor.familyName}</p>
              </div>
              <div>
                <p className="text-gray-500">Date & Time</p>
                <p className="font-medium">{format(new Date(selectedDate), 'PPP')}</p>
                <p className="text-gray-400">{selectedSlot.startTime.substring(0, 5)} – {selectedSlot.endTime.substring(0, 5)}</p>
              </div>
              <div className="space-y-1">
                <Label>Appointment Type</Label>
                <select className="w-full border rounded px-2 py-1 text-sm"
                  value={apptType} onChange={(e) => setApptType(e.target.value)}>
                  <option value="ROUTINE">Routine</option>
                  <option value="FOLLOWUP">Follow-up</option>
                  <option value="EMERGENCY">Emergency</option>
                  <option value="CHECKUP">Check-up</option>
                </select>
              </div>
            </div>
            <div className="space-y-1">
              <Label>Notes / Description</Label>
              <textarea className="w-full border rounded px-3 py-2 text-sm" rows={3}
                placeholder="Chief complaint or visit reason…"
                value={description} onChange={(e) => setDescription(e.target.value)} />
            </div>
            <div className="flex gap-3">
              <Button variant="ghost" onClick={() => setStep(3)}>← Back</Button>
              <Button onClick={() => bookMutation.mutate()} disabled={bookMutation.isPending}
                className="bg-violet-600 hover:bg-violet-700">
                {bookMutation.isPending ? 'Booking…' : 'Confirm Booking'}
              </Button>
            </div>
          </CardContent>
        </Card>
      )}
    </PortalPageWrapper>
  );
}