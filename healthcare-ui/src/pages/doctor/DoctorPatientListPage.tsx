import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, Stethoscope } from 'lucide-react';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { DataTable } from '@/components/common/DataTable';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { usePatients } from '@/hooks/usePatients';
import { formatDate, formatPatientName, calculateAge } from '@/utils/formatters';
import type { Patient } from '@/types';

export function DoctorPatientListPage() {
  const navigate = useNavigate();
  const [searchInput, setSearchInput] = useState('');
  const [activeSearch, setActiveSearch] = useState('');

  const isLikelyMrn = /^\d/.test(activeSearch);
  const { data, isLoading } = usePatients(
    activeSearch ? (isLikelyMrn ? { mrn: activeSearch } : { name: activeSearch }) : undefined
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
        <span className="font-mono text-xs font-semibold text-emerald-700 bg-emerald-50 px-2 py-1 rounded">
          {row.mrn ?? '—'}
        </span>
      ),
    },
    {
      key: 'name',
      header: 'Patient Name',
      render: (row: Patient) => <span className="font-medium text-gray-900">{formatPatientName(row.names)}</span>,
    },
    { key: 'age', header: 'Age', render: (row: Patient) => calculateAge(row.birthDate) },
    { key: 'dob', header: 'Date of Birth', render: (row: Patient) => formatDate(row.birthDate) },
    {
      key: 'actions',
      header: '',
      render: (row: Patient) => (
        <Button
          size="sm"
          variant="ghost"
          className="gap-1.5"
          onClick={(e) => {
            e.stopPropagation();
            navigate(`/doctor/chart/${row.id}`);
          }}
        >
          <Stethoscope className="w-3.5 h-3.5" /> Open Chart
        </Button>
      ),
    },
  ];

  return (
    <PortalPageWrapper title="Patients">
      <PageHeader title="Patients" subtitle="Search patients and open a clinical chart" />

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
        <Button type="submit" variant="outline">Search</Button>
        {activeSearch && (
          <Button type="button" variant="ghost" onClick={() => { setSearchInput(''); setActiveSearch(''); }}>
            Clear
          </Button>
        )}
      </form>

      <DataTable
        columns={columns}
        data={data ?? []}
        loading={isLoading}
        keyExtractor={(p) => p.id}
        onRowClick={(p) => navigate(`/doctor/chart/${p.id}`)}
        emptyMessage={activeSearch ? `No patients found for "${activeSearch}"` : 'No patients registered yet.'}
      />
    </PortalPageWrapper>
  );
}
