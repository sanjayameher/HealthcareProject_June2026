import { useNavigate } from 'react-router-dom';
import { Plus } from 'lucide-react';
import { PageWrapper } from '@/components/layout/PageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { DataTable } from '@/components/common/DataTable';
import { ActiveBadge } from '@/components/common/StatusBadge';
import { Button } from '@/components/ui/button';
import { usePayers } from '@/hooks/useBilling';
import type { Payer } from '@/types';
import { formatDate } from '@/utils/formatters';

export function PayerListPage() {
  const navigate = useNavigate();
  const { data, isLoading } = usePayers();

  const columns = [
    {
      key: 'name',
      header: 'Payer Name',
      render: (row: Payer) => <span className="font-medium">{row.name}</span>,
    },
    {
      key: 'type',
      header: 'Type',
      render: (row: Payer) => row.type ?? '—',
    },
    {
      key: 'payerId',
      header: 'Payer ID',
      render: (row: Payer) => (
        <span className="font-mono text-xs">{row.payerId ?? '—'}</span>
      ),
    },
    {
      key: 'phone',
      header: 'Phone',
      render: (row: Payer) => row.phone ?? '—',
    },
    {
      key: 'status',
      header: 'Status',
      render: (row: Payer) => <ActiveBadge active={row.active} />,
    },
    {
      key: 'created',
      header: 'Created',
      render: (row: Payer) => formatDate(row.createdAt),
    },
  ];

  return (
    <PageWrapper title="Payers">
      <PageHeader
        title="Insurance Payers"
        subtitle="Manage insurance payers and providers"
        actions={
          <>
            <Button variant="outline" onClick={() => navigate('/billing/coverage/new')} className="gap-2">
              <Plus className="w-4 h-4" />Add Coverage
            </Button>
            <Button onClick={() => navigate('/billing/payers/new')} className="gap-2">
              <Plus className="w-4 h-4" />Add Payer
            </Button>
          </>
        }
      />
      <DataTable
        columns={columns}
        data={data ?? []}
        loading={isLoading}
        keyExtractor={(p) => p.id}
        emptyMessage="No payers registered."
      />
    </PageWrapper>
  );
}
