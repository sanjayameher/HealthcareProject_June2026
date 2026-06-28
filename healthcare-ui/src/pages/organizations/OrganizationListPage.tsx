import { useNavigate } from 'react-router-dom';
import { Plus, Building2 } from 'lucide-react';
import { PageWrapper } from '@/components/layout/PageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { DataTable } from '@/components/common/DataTable';
import { ActiveBadge } from '@/components/common/StatusBadge';
import { Button } from '@/components/ui/button';
import { useOrganizations } from '@/hooks/useOrganizations';
import type { Organization } from '@/types';
import { formatDate } from '@/utils/formatters';

export function OrganizationListPage() {
  const navigate = useNavigate();
  const { data, isLoading } = useOrganizations();

  const columns = [
    {
      key: 'name',
      header: 'Organization Name',
      render: (row: Organization) => (
        <div className="flex items-center gap-2">
          <Building2 className="w-4 h-4 text-gray-400" />
          <span className="font-medium text-gray-900">{row.name}</span>
        </div>
      ),
    },
    {
      key: 'type',
      header: 'Type',
      render: (row: Organization) => row.typeDisplay ?? row.typeCode ?? '—',
    },
    {
      key: 'location',
      header: 'Location',
      render: (row: Organization) =>
        [row.city, row.state].filter(Boolean).join(', ') || '—',
    },
    {
      key: 'phone',
      header: 'Phone',
      render: (row: Organization) => row.phone ?? '—',
    },
    {
      key: 'status',
      header: 'Status',
      render: (row: Organization) => <ActiveBadge active={row.active} />,
    },
    {
      key: 'created',
      header: 'Created',
      render: (row: Organization) => formatDate(row.createdAt),
    },
  ];

  return (
    <PageWrapper title="Organizations">
      <PageHeader
        title="Organizations"
        subtitle="Manage healthcare organizations"
        actions={
          <Button onClick={() => navigate('/organizations/new')} className="gap-2">
            <Plus className="w-4 h-4" />
            New Organization
          </Button>
        }
      />
      <DataTable
        columns={columns}
        data={data ?? []}
        loading={isLoading}
        keyExtractor={(o) => o.id}
        onRowClick={(o) => navigate(`/organizations/${o.id}`)}
        emptyMessage="No organizations found."
      />
    </PageWrapper>
  );
}
