import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { format } from 'date-fns';
import { RefreshCw } from 'lucide-react';
import { portalApi } from '@/api/portalApi';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { DataTable } from '@/components/common/DataTable';
import { StatusBadge } from '@/components/common/StatusBadge';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import type { PortalAppointment, AppointmentStatus } from '@/types';

const NEXT_STATUS: Record<string, AppointmentStatus> = {
  booked:     'arrived',
  arrived:    'checked_in',
  checked_in: 'fulfilled',
};

export function AdminQueuePage() {
  const qc = useQueryClient();

  const { data: queue = [], isLoading, refetch } = useQuery({
    queryKey: ['admin-queue'],
    queryFn: portalApi.getAdminQueue,
    refetchInterval: 30_000,
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, status }: { id: string; status: AppointmentStatus }) =>
      portalApi.updateAppointmentStatus(id, { status }),
    onSuccess: () => { toast.success('Status updated'); qc.invalidateQueries({ queryKey: ['admin-queue'] }); },
    onError: (e: Error) => toast.error(e.message),
  });

  const cancelMutation = useMutation({
    mutationFn: portalApi.cancelAppointmentAdmin,
    onSuccess: () => { toast.success('Appointment cancelled'); qc.invalidateQueries({ queryKey: ['admin-queue'] }); },
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
      key: 'actions', header: 'Actions',
      render: (a: PortalAppointment) => {
        const next = NEXT_STATUS[a.status];
        return (
          <div className="flex items-center gap-2">
            {next && (
              <Button size="sm" variant="outline"
                onClick={() => statusMutation.mutate({ id: a.id, status: next })}>
                → {next.replace('_', ' ')}
              </Button>
            )}
            {a.status !== 'cancelled' && a.status !== 'fulfilled' && (
              <Button size="sm" variant="destructive"
                onClick={() => cancelMutation.mutate(a.id)}>
                Cancel
              </Button>
            )}
          </div>
        );
      },
    },
  ];

  return (
    <PortalPageWrapper title="Today's Queue">
      <PageHeader
        title="Appointment Queue"
        subtitle={`${format(new Date(), 'EEEE, MMMM d, yyyy')} — ${queue.length} appointments`}
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
        emptyMessage="No appointments in today's queue."
      />
    </PortalPageWrapper>
  );
}