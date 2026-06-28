import { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { UserPlus, Search } from 'lucide-react';
import { PageWrapper } from '@/components/layout/PageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { DataTable } from '@/components/common/DataTable';
import { ActiveBadge } from '@/components/common/StatusBadge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { usePatients } from '@/hooks/usePatients';
import { formatDate, formatPatientName } from '@/utils/formatters';
import type { Patient } from '@/types';

export function PatientListPage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [searchInput, setSearchInput] = useState(searchParams.get('search') ?? '');
  const [activeSearch, setActiveSearch] = useState(searchParams.get('search') ?? '');

  const isLikelyMrn = /^\d/.test(activeSearch);
  const { data, isLoading } = usePatients(
    activeSearch
      ? isLikelyMrn
        ? { mrn: activeSearch }
        : { name: activeSearch }
      : undefined
  );

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setActiveSearch(searchInput.trim());
  };

  const columns = [
    {
      key: 'mrn',
      header: 'MRN',
      render: (row: Patient) => (
        <span className="font-mono text-xs font-semibold text-medical-600 bg-medical-50 px-2 py-1 rounded">
          {row.mrn ?? '—'}
        </span>
      ),
    },
    {
      key: 'name',
      header: 'Patient Name',
      render: (row: Patient) => (
        <span className="font-medium text-gray-900">{formatPatientName(row.names)}</span>
      ),
    },
    {
      key: 'gender',
      header: 'Gender',
      render: (row: Patient) =>
        row.gender ? row.gender.charAt(0).toUpperCase() + row.gender.slice(1) : '—',
    },
    {
      key: 'dob',
      header: 'Date of Birth',
      render: (row: Patient) => formatDate(row.birthDate),
    },
    {
      key: 'status',
      header: 'Status',
      render: (row: Patient) => <ActiveBadge active={row.active} />,
    },
    {
      key: 'actions',
      header: '',
      render: (row: Patient) => (
        <Button
          size="sm"
          variant="ghost"
          onClick={(e) => {
            e.stopPropagation();
            navigate(`/patients/${row.id}`);
          }}
        >
          View
        </Button>
      ),
    },
  ];

  return (
    <PageWrapper title="Patients">
      <PageHeader
        title="Patients"
        subtitle="Search and manage patient records"
        actions={
          <Button onClick={() => navigate('/patients/new')} className="gap-2">
            <UserPlus className="w-4 h-4" />
            Register Patient
          </Button>
        }
      />

      <form onSubmit={handleSearch} className="flex gap-2 mb-4">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <Input
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            placeholder="Search by name or MRN..."
            className="pl-9"
          />
        </div>
        <Button type="submit" variant="outline">
          Search
        </Button>
        {activeSearch && (
          <Button
            type="button"
            variant="ghost"
            onClick={() => {
              setSearchInput('');
              setActiveSearch('');
            }}
          >
            Clear
          </Button>
        )}
      </form>

      <DataTable
        columns={columns}
        data={data ?? []}
        loading={isLoading}
        keyExtractor={(p) => p.id}
        onRowClick={(p) => navigate(`/patients/${p.id}`)}
        emptyMessage={
          activeSearch ? `No patients found for "${activeSearch}"` : 'No patients registered yet.'
        }
      />
    </PageWrapper>
  );
}
