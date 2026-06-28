import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { CalendarDays, ClipboardList, Pill, Plus } from 'lucide-react';
import { format } from 'date-fns';
import { portalApi } from '@/api/portalApi';
import { useAuthStore } from '@/store/authStore';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { DataTable } from '@/components/common/DataTable';
import { StatusBadge } from '@/components/common/StatusBadge';
import type { PortalAppointment } from '@/types';

export function DoctorDashboard() {
  const navigate = useNavigate();
  const { user } = useAuthStore();
  const practitionerId = user?.userId ?? '';

  const { data: queue = [] } = useQuery({
    queryKey: ['doctor-queue', practitionerId],
    queryFn: () => portalApi.getDoctorQueue(practitionerId),
    enabled: !!practitionerId,
    refetchInterval: 30_000,
  });

  const { data: upcoming = [] } = useQuery({
    queryKey: ['doctor-upcoming', practitionerId],
    queryFn: () => portalApi.getDoctorUpcoming(practitionerId),
    enabled: !!practitionerId,
  });

  const queueColumns = [
    {
      key: 'time', header: 'Time',
      render: (a: PortalAppointment) => <span className="font-mono">{format(new Date(a.startTime), 'HH:mm')}</span>,
    },
    {
      key: 'status', header: 'Status',
      render: (a: PortalAppointment) => <StatusBadge status={a.status} />,
    },
    {
      key: 'type', header: 'Type',
      render: (a: PortalAppointment) => a.appointmentTypeCode ?? '—',
    },
  ];

  return (
    <PortalPageWrapper title="Dashboard">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Good {getGreeting()}, {user?.fullName}</h1>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
        {[
          { label: "Today's Patients", value: queue.length, icon: ClipboardList, color: 'bg-emerald-600' },
          { label: 'Upcoming (7d)',    value: upcoming.length, icon: CalendarDays, color: 'bg-sky-500' },
          { label: 'Prescriptions',   value: '—',           icon: Pill,         color: 'bg-amber-500' },
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
            <CardTitle className="text-base">Today's Queue</CardTitle>
            <Button variant="ghost" size="sm" onClick={() => navigate('/doctor/queue')}>View all</Button>
          </CardHeader>
          <CardContent className="p-0 pb-4">
            <DataTable
              columns={queueColumns}
              data={queue.slice(0, 5)}
              keyExtractor={(a) => a.id}
              emptyMessage="No appointments today."
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle className="text-base">Quick Actions</CardTitle></CardHeader>
          <CardContent className="flex flex-col gap-2">
            <Button onClick={() => navigate('/doctor/queue')} className="gap-2 bg-emerald-600 hover:bg-emerald-700">
              <ClipboardList className="w-4 h-4" /> View My Queue
            </Button>
            <Button variant="outline" onClick={() => navigate('/doctor/calendar')} className="gap-2">
              <CalendarDays className="w-4 h-4" /> Manage Calendar
            </Button>
            <Button variant="outline" onClick={() => navigate('/doctor/prescriptions')} className="gap-2">
              <Pill className="w-4 h-4" /> Write Prescription
            </Button>
          </CardContent>
        </Card>
      </div>
    </PortalPageWrapper>
  );
}

function getGreeting() {
  const h = new Date().getHours();
  if (h < 12) return 'morning';
  if (h < 17) return 'afternoon';
  return 'evening';
}