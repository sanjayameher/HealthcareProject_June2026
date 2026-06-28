import { useNavigate } from 'react-router-dom';
import { Plus, UserCheck } from 'lucide-react';
import { PageWrapper } from '@/components/layout/PageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { DataTable } from '@/components/common/DataTable';
import { ActiveBadge } from '@/components/common/StatusBadge';
import { Button } from '@/components/ui/button';
import { usePractitioners } from '@/hooks/usePractitioners';
import type { Practitioner } from '@/types';
import { formatDate, formatGender } from '@/utils/formatters';

function getPractitionerDisplayName(p: Practitioner): string {
  return p.fullNameDisplay ?? `${p.familyName}, ${p.givenName}`;
}

export function PractitionerListPage() {
  const navigate = useNavigate();
  const { data, isLoading } = usePractitioners();

  const columns = [
    {
      key: 'name',
      header: 'Name',
      render: (row: Practitioner) => (
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-medical-100 flex items-center justify-center">
            <UserCheck className="w-4 h-4 text-medical-600" />
          </div>
          <span className="font-medium">{getPractitionerDisplayName(row)}</span>
        </div>
      ),
    },
    {
      key: 'npi',
      header: 'NPI',
      render: (row: Practitioner) =>
        row.npi ? (
          <span className="font-mono text-xs text-gray-600">{row.npi}</span>
        ) : (
          '—'
        ),
    },
    {
      key: 'gender',
      header: 'Gender',
      render: (row: Practitioner) => formatGender(row.gender),
    },
    {
      key: 'status',
      header: 'Status',
      render: (row: Practitioner) => <ActiveBadge active={row.active} />,
    },
    {
      key: 'created',
      header: 'Registered',
      render: (row: Practitioner) => formatDate(row.createdAt),
    },
  ];

  return (
    <PageWrapper title="Practitioners">
      <PageHeader
        title="Practitioners"
        subtitle="Manage clinical staff and providers"
        actions={
          <Button onClick={() => navigate('/practitioners/new')} className="gap-2">
            <Plus className="w-4 h-4" />
            Register Practitioner
          </Button>
        }
      />
      <DataTable
        columns={columns}
        data={data ?? []}
        loading={isLoading}
        keyExtractor={(p) => p.id}
        onRowClick={(p) => navigate(`/practitioners/${p.id}`)}
        emptyMessage="No practitioners registered."
      />
    </PageWrapper>
  );
}
