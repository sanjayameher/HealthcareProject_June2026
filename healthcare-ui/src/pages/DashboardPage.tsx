import { useNavigate } from 'react-router-dom';
import { Users, Stethoscope, CreditCard, ShieldCheck, Plus, UserPlus } from 'lucide-react';
import { PageWrapper } from '@/components/layout/PageWrapper';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { DataTable } from '@/components/common/DataTable';
import { ActiveBadge } from '@/components/common/StatusBadge';
import { usePatients } from '@/hooks/usePatients';
import { formatPatientName, formatDate } from '@/utils/formatters';
import type { Patient } from '@/types';

function StatCard({
  icon: Icon,
  label,
  value,
  color,
  loading,
}: {
  icon: React.ElementType;
  label: string;
  value: number | string;
  color: string;
  loading?: boolean;
}) {
  return (
    <Card>
      <CardContent className="flex items-center gap-4 p-6">
        <div className={`flex items-center justify-center w-12 h-12 rounded-lg ${color}`}>
          <Icon className="w-6 h-6 text-white" />
        </div>
        <div>
          <p className="text-sm text-gray-500">{label}</p>
          {loading ? (
            <Skeleton className="h-7 w-16 mt-1" />
          ) : (
            <p className="text-2xl font-bold text-gray-900">{value}</p>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

export function DashboardPage() {
  const navigate = useNavigate();
  const { data: patients, isLoading } = usePatients();

  const totalPatients = patients?.length ?? 0;
  const activePatients = patients?.filter((p) => p.active).length ?? 0;

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
      header: 'Name',
      render: (row: Patient) => (
        <span className="font-medium">{formatPatientName(row.names)}</span>
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
  ];

  return (
    <PageWrapper title="Dashboard">
      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard
          icon={Users}
          label="Total Patients"
          value={totalPatients}
          color="bg-medical-500"
          loading={isLoading}
        />
        <StatCard
          icon={Stethoscope}
          label="Active Patients"
          value={activePatients}
          color="bg-emerald-500"
          loading={isLoading}
        />
        <StatCard
          icon={CreditCard}
          label="Active Coverage"
          value="—"
          color="bg-violet-500"
        />
        <StatCard
          icon={ShieldCheck}
          label="Audit Events"
          value="—"
          color="bg-amber-500"
        />
      </div>

      {/* Quick Actions */}
      <Card className="mb-8">
        <CardHeader>
          <CardTitle className="text-base">Quick Actions</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-wrap gap-3">
          <Button onClick={() => navigate('/patients/new')} className="gap-2">
            <UserPlus className="w-4 h-4" />
            Register Patient
          </Button>
          <Button
            variant="outline"
            onClick={() => navigate('/encounters/new')}
            className="gap-2"
          >
            <Stethoscope className="w-4 h-4" />
            New Encounter
          </Button>
          <Button
            variant="outline"
            onClick={() => navigate('/billing/coverage/new')}
            className="gap-2"
          >
            <Plus className="w-4 h-4" />
            Add Coverage
          </Button>
          <Button
            variant="outline"
            onClick={() => navigate('/organizations/new')}
            className="gap-2"
          >
            <Plus className="w-4 h-4" />
            New Organization
          </Button>
        </CardContent>
      </Card>

      {/* Recent Patients */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-base">Recent Patients</CardTitle>
          <Button variant="ghost" size="sm" onClick={() => navigate('/patients')}>
            View all
          </Button>
        </CardHeader>
        <CardContent className="p-0 pb-4">
          <DataTable
            columns={columns}
            data={patients?.slice(0, 10) ?? []}
            loading={isLoading}
            keyExtractor={(p) => p.id}
            onRowClick={(p) => navigate(`/patients/${p.id}`)}
            emptyMessage="No patients registered yet."
          />
        </CardContent>
      </Card>
    </PageWrapper>
  );
}
