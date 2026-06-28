import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { format } from 'date-fns';
import { RefreshCw } from 'lucide-react';
import { portalApi } from '@/api/portalApi';
import { useAuthStore } from '@/store/authStore';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { DataTable } from '@/components/common/DataTable';
import { StatusBadge } from '@/components/common/StatusBadge';
import { Button } from '@/components/ui/button';
import type { PortalAppointment, AppointmentStatus } from '@/types';

const NEXT_STATUS: Record<string, AppointmentStatus> = {
  booked:      'arrived',
  arrived:     'checked_in',
  checked_in:  'fulfilled',
};

export function DoctorQueuePage() {
  const { user } = useAuthStore();
  const practitionerId = user?.userId ?? '';
  const qc = useQueryClient();

  const { data: queue = [], isLoading, refetch } = useQuery({
    queryKey: ['doctor-queue', practitionerId],
    queryFn: () => portalApi.getDoctorQueue(practitionerId),
    enabled: !!practitionerId,
    refetchInterval: 30_000,
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: string }) =>
      portalApi.updateAppointmentStatusDoctor(id, status),
    onSuccess: () => { toast.success('Status updated'); qc.invalidateQueries({ queryKey: ['doctor-queue'] }); },
    onError: (e: Error) => toast.error(e.message),
  });

  const columns = [
    {
      key: 'time', header: 'Time',
      render: (a: PortalAppointment) => (
        <span className="font-mono text-sm">{format(new Date(a.startTime), 'HH:mm')}</span>
      ),
    },
    {
      key: 'type', header: 'Type',
      render: (a: PortalAppointment) => a.appointmentTypeCode ?? 'ROUTINE',
    },
    {
      key: 'status', header: 'Status',
      render: (a: PortalAppointment) => <StatusBadge status={a.status} />,
    },
    {
      key: 'actions', header: '',
      render: (a: PortalAppointment) => {
        const next = NEXT_STATUS[a.status];
        return next ? (
          <Button size="sm" className="bg-emerald-600 hover:bg-emerald-700 text-xs"
            onClick={() => statusMutation.mutate({ id: a.id, status: next })}>
            Mark {next.replace('_', ' ')}
          </Button>
        ) : null;
      },
    },
  ];

  return (
    <PortalPageWrapper title="My Queue">
      <PageHeader
        title="Today's Queue"
        subtitle={`${format(new Date(), 'EEEE, MMMM d')} — ${queue.length} appointment(s)`}
        actions={
          <Button variant="outline" onClick={() => refetch()} className="gap-2">
            <RefreshCw className="w-4 h-4" /> Refresh
          </Button>
        }
      />
      <DataTable
        columns={columns}
        data={queue}
        loading={isLoading}
        keyExtractor={(a) => a.id}
        emptyMessage="No appointments in your queue today."
      />
    </PortalPageWrapper>
  );
}