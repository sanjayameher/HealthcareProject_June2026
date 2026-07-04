import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Users, UserCheck, CalendarDays, ClipboardList, Plus } from 'lucide-react';
import { portalApi } from '@/api/portalApi';
import { useAuthStore } from '@/store/authStore';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { DataTable } from '@/components/common/DataTable';
import { StatusBadge } from '@/components/common/StatusBadge';
import type { PortalAppointment } from '@/types';
import { format } from 'date-fns';

function StatCard({ icon: Icon, label, value, color }: { icon: React.ElementType; label: string; value: number | string; color: string }) {
  return (
    <Card>
      <CardContent className="flex items-center gap-4 p-6">
        <div className={`flex items-center justify-center w-12 h-12 rounded-lg ${color}`}>
          <Icon className="w-6 h-6 text-white" />
        </div>
        <div>
          <p className="text-sm text-gray-500">{label}</p>
          <p className="text-2xl font-bold text-gray-900">{value}</p>
        </div>
      </CardContent>
    </Card>
  );
}

export function AdminDashboard() {
  const navigate = useNavigate();
  const { user } = useAuthStore();

  const { data: queue = [] } = useQuery({
    queryKey: ['admin-queue'],
    queryFn: portalApi.getAdminQueue,
    refetchInterval: 30_000,
  });

  const { data: stats } = useQuery({
    queryKey: ['admin-stats'],
    queryFn: portalApi.getAdminStats,
    refetchInterval: 60_000,
  });

  const columns = [
    {
      key: 'time', header: 'Time',
      render: (a: PortalAppointment) => format(new Date(a.startTime), 'HH:mm'),
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
    <PortalPageWrapper title={`Welcome, ${user?.fullName}`}>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard icon={ClipboardList} label="In Queue Today" value={queue.length} color="bg-violet-600" />
        <StatCard icon={Users}         label="Patients"        value={stats?.patients  ?? '—'} color="bg-sky-500" />
        <StatCard icon={UserCheck}     label="Doctors"         value={stats?.doctors   ?? '—'} color="bg-emerald-500" />
        <StatCard icon={CalendarDays}  label="Upcoming"        value={stats?.upcoming  ?? '—'} color="bg-amber-500" />
      </div>

      <Card className="mb-8">
        <CardHeader><CardTitle className="text-base">Quick Actions</CardTitle></CardHeader>
        <CardContent className="flex flex-wrap gap-3">
          <Button onClick={() => navigate('/admin/appointments/new')} className="gap-2 bg-violet-600 hover:bg-violet-700">
            <Plus className="w-4 h-4" /> Book Appointment
          </Button>
          <Button variant="outline" onClick={() => navigate('/admin/doctors/new')} className="gap-2">
            <Plus className="w-4 h-4" /> Add Doctor
          </Button>
          <Button variant="outline" onClick={() => navigate('/admin/doctors')} className="gap-2">
            <UserCheck className="w-4 h-4" /> Manage Doctors
          </Button>
          <Button variant="outline" onClick={() => navigate('/admin/queue')} className="gap-2">
            <ClipboardList className="w-4 h-4" /> Today's Queue
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-base">Today's Appointment Queue</CardTitle>
          <Button variant="ghost" size="sm" onClick={() => navigate('/admin/queue')}>View all</Button>
        </CardHeader>
        <CardContent className="p-0 pb-4">
          <DataTable
            columns={columns}
            data={queue.slice(0, 8)}
            keyExtractor={(a) => a.id}
            emptyMessage="No appointments scheduled for today."
          />
        </CardContent>
      </Card>
    </PortalPageWrapper>
  );
}