import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { CalendarDays, ClipboardList, Pill, Search } from 'lucide-react';
import { format } from 'date-fns';
import { portalApi } from '@/api/portalApi';
import { useAuthStore } from '@/store/authStore';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { DataTable } from '@/components/common/DataTable';
import { StatusBadge } from '@/components/common/StatusBadge';
import type { PortalAppointment } from '@/types';

export function PatientDashboard() {
  const navigate = useNavigate();
  const { user } = useAuthStore();
  const patientId = user?.userId ?? '';

  const { data: upcoming = [] } = useQuery({
    queryKey: ['patient-upcoming', patientId],
    queryFn: () => portalApi.getPatientUpcoming(patientId),
    enabled: !!patientId,
  });

  const apptColumns = [
    {
      key: 'date', header: 'Date',
      render: (a: PortalAppointment) => format(new Date(a.startTime), 'EEE, MMM d'),
    },
    {
      key: 'time', header: 'Time',
      render: (a: PortalAppointment) => format(new Date(a.startTime), 'h:mm a'),
    },
    {
      key: 'status', header: 'Status',
      render: (a: PortalAppointment) => <StatusBadge status={a.status} />,
    },
    {
      key: 'type', header: 'Type',
      render: (a: PortalAppointment) => a.appointmentTypeCode ?? 'Routine',
    },
  ];

  return (
    <PortalPageWrapper title="My Health">
      <h1 className="text-2xl font-bold text-gray-900 mb-2">Hello, {user?.fullName}</h1>
      <p className="text-gray-500 mb-8">Welcome to your patient portal.</p>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
        {[
          { label: 'Upcoming Appointments', value: upcoming.length, icon: CalendarDays, color: 'bg-sky-500' },
          { label: 'Prescriptions',          value: '—',            icon: Pill,         color: 'bg-emerald-500' },
          { label: 'Past Visits',            value: '—',            icon: ClipboardList, color: 'bg-violet-500' },
        ].map(({ label, value, icon: Icon, color }) => (
          <Card key={label}>
            <CardContent className="flex items-center gap-4 p-5">
              <div className={`w-10 h-10 rounded-lg ${color} flex items-center justify-center flex-shrink-0`}>
                <Icon className="w-5 h-5 text-white" />
              </div>
              <div>
                <p className="text-sm text-gray-500">{label}</p>
                <p className="text-2xl font-bold">{value}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle className="text-base">Upcoming Appointments</CardTitle>
            <Button variant="ghost" size="sm" onClick={() => navigate('/patient/appointments')}>View all</Button>
          </CardHeader>
          <CardContent className="p-0 pb-4">
            <DataTable
              columns={apptColumns}
              data={upcoming.slice(0, 5)}
              keyExtractor={(a) => a.id}
              emptyMessage="No upcoming appointments."
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Quick Actions</CardTitle></CardHeader>
          <CardContent className="flex flex-col gap-2">
            <Button onClick={() => navigate('/patient/appointments')} className="gap-2 bg-sky-600 hover:bg-sky-700">
              <CalendarDays className="w-4 h-4" /> My Appointments
            </Button>
            <Button variant="outline" onClick={() => navigate('/patient/doctors')} className="gap-2">
              <Search className="w-4 h-4" /> Find a Doctor
            </Button>
            <Button variant="outline" onClick={() => navigate('/patient/prescriptions')} className="gap-2">
              <Pill className="w-4 h-4" /> My Prescriptions
            </Button>
          </CardContent>
        </Card>
      </div>
    </PortalPageWrapper>
  );
}