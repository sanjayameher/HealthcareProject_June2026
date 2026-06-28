import { useParams, useNavigate } from 'react-router-dom';
import {
  Edit,
  Trash2,
  User,
  Phone,
  Mail,
  MapPin,
  Stethoscope,
  CreditCard,
  Shield,
} from 'lucide-react';
import { PageWrapper } from '@/components/layout/PageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { DataTable } from '@/components/common/DataTable';
import { EncounterStatusBadge, CoverageStatusBadge, ActiveBadge } from '@/components/common/StatusBadge';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';
import { Badge } from '@/components/ui/badge';
import { usePatient, useDeletePatient } from '@/hooks/usePatients';
import { usePatientEncounters } from '@/hooks/useEncounters';
import { usePatientCoverage, useRemoveCoverage } from '@/hooks/useBilling';
import { usePatientAuditTrail } from '@/hooks/useAudit';
import {
  formatPatientName,
  formatDate,
  formatDateTime,
  calculateAge,
  formatGender,
} from '@/utils/formatters';
import type { Encounter, Coverage, AuditEvent } from '@/types';
import { useState } from 'react';
import { Plus } from 'lucide-react';

export function PatientDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [removeCoverageId, setRemoveCoverageId] = useState<string | null>(null);

  const { data: patient, isLoading } = usePatient(id!);
  const { data: encounters, isLoading: encLoading } = usePatientEncounters(id!);
  const { data: coverage, isLoading: covLoading } = usePatientCoverage(id!);
  const { data: auditEvents, isLoading: auditLoading } = usePatientAuditTrail(id!);

  const deletePatient = useDeletePatient();
  const removeCoverage = useRemoveCoverage(id!);

  const handleDelete = async () => {
    await deletePatient.mutateAsync(id!);
    navigate('/patients');
  };

  const handleRemoveCoverage = async () => {
    if (removeCoverageId) {
      await removeCoverage.mutateAsync(removeCoverageId);
      setRemoveCoverageId(null);
    }
  };

  if (isLoading) {
    return (
      <PageWrapper title="Patient">
        <div className="space-y-4">
          <Skeleton className="h-24 w-full" />
          <Skeleton className="h-64 w-full" />
        </div>
      </PageWrapper>
    );
  }

  if (!patient) {
    return (
      <PageWrapper title="Patient">
        <div className="text-center py-12 text-gray-500">Patient not found.</div>
      </PageWrapper>
    );
  }

  const displayName = formatPatientName(patient.names);
  const primaryTelecom = patient.telecoms?.find((t) => t.system === 'phone');
  const email = patient.telecoms?.find((t) => t.system === 'email');
  const address = patient.addresses?.[0];

  const encounterCols = [
    {
      key: 'status',
      header: 'Status',
      render: (row: Encounter) => <EncounterStatusBadge status={row.status} />,
    },
    {
      key: 'class',
      header: 'Class',
      render: (row: Encounter) => (
        <span className="capitalize">{row.encounterClass.replace('_', ' ')}</span>
      ),
    },
    {
      key: 'type',
      header: 'Type',
      render: (row: Encounter) => row.typeDisplay ?? '—',
    },
    {
      key: 'start',
      header: 'Start',
      render: (row: Encounter) => formatDateTime(row.periodStart),
    },
    {
      key: 'complaint',
      header: 'Chief Complaint',
      render: (row: Encounter) => row.chiefComplaint ?? '—',
    },
  ];

  const auditCols = [
    {
      key: 'time',
      header: 'Time',
      render: (row: AuditEvent) => formatDateTime(row.occurredAt),
    },
    {
      key: 'action',
      header: 'Action',
      render: (row: AuditEvent) => row.action,
    },
    {
      key: 'type',
      header: 'Entity Type',
      render: (row: AuditEvent) => row.entityType ?? '—',
    },
    {
      key: 'user',
      header: 'User',
      render: (row: AuditEvent) => row.userId ?? '—',
    },
    {
      key: 'outcome',
      header: 'Outcome',
      render: (row: AuditEvent) => (
        <Badge variant={row.outcome === 'success' ? 'success' : 'destructive'} className="text-xs">
          {row.outcome ?? '—'}
        </Badge>
      ),
    },
  ];

  return (
    <PageWrapper title="Patient">
      <PageHeader
        title={displayName}
        subtitle={`MRN: ${patient.mrn ?? '—'} · Age: ${calculateAge(patient.birthDate)} · ${formatGender(patient.gender)}`}
        backTo="/patients"
        actions={
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => navigate(`/patients/${id}/edit`)}
              className="gap-1"
            >
              <Edit className="w-4 h-4" />
              Edit
            </Button>
            <Button
              variant="destructive"
              size="sm"
              onClick={() => setDeleteOpen(true)}
              className="gap-1"
            >
              <Trash2 className="w-4 h-4" />
              Delete
            </Button>
          </div>
        }
      />

      {/* Status banner */}
      <div className="flex items-center gap-3 mb-6">
        <ActiveBadge active={patient.active} />
        {patient.mrn && (
          <span className="font-mono text-sm font-semibold text-medical-600 bg-medical-50 border border-medical-200 px-3 py-1 rounded-full">
            MRN: {patient.mrn}
          </span>
        )}
      </div>

      <Tabs defaultValue="demographics">
        <TabsList className="mb-4">
          <TabsTrigger value="demographics" className="gap-1.5">
            <User className="w-4 h-4" />Demographics
          </TabsTrigger>
          <TabsTrigger value="encounters" className="gap-1.5">
            <Stethoscope className="w-4 h-4" />Encounters
          </TabsTrigger>
          <TabsTrigger value="coverage" className="gap-1.5">
            <CreditCard className="w-4 h-4" />Coverage
          </TabsTrigger>
          <TabsTrigger value="audit" className="gap-1.5">
            <Shield className="w-4 h-4" />Audit
          </TabsTrigger>
        </TabsList>

        {/* Demographics */}
        <TabsContent value="demographics">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <Card>
              <CardHeader><CardTitle className="text-sm font-semibold text-gray-500 uppercase">Personal Info</CardTitle></CardHeader>
              <CardContent className="space-y-3">
                <div className="grid grid-cols-2 gap-y-3">
                  <span className="text-sm text-gray-500">Full Name</span>
                  <span className="text-sm font-medium">{displayName}</span>

                  <span className="text-sm text-gray-500">Gender</span>
                  <span className="text-sm font-medium">{formatGender(patient.gender)}</span>

                  <span className="text-sm text-gray-500">Date of Birth</span>
                  <span className="text-sm font-medium">{formatDate(patient.birthDate)}</span>

                  <span className="text-sm text-gray-500">Age</span>
                  <span className="text-sm font-medium">{calculateAge(patient.birthDate)}</span>

                  <span className="text-sm text-gray-500">Org</span>
                  <span className="text-sm font-medium">{patient.managingOrganizationName ?? '—'}</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader><CardTitle className="text-sm font-semibold text-gray-500 uppercase">Contact Info</CardTitle></CardHeader>
              <CardContent className="space-y-3">
                {primaryTelecom && (
                  <div className="flex items-center gap-2 text-sm">
                    <Phone className="w-4 h-4 text-gray-400" />
                    <span>{primaryTelecom.value}</span>
                  </div>
                )}
                {email && (
                  <div className="flex items-center gap-2 text-sm">
                    <Mail className="w-4 h-4 text-gray-400" />
                    <span>{email.value}</span>
                  </div>
                )}
                {address && (
                  <div className="flex items-start gap-2 text-sm">
                    <MapPin className="w-4 h-4 text-gray-400 mt-0.5" />
                    <div>
                      {[address.line1, address.line2].filter(Boolean).join(', ')}
                      {(address.line1 || address.line2) && <br />}
                      {[address.city, address.state, address.postalCode].filter(Boolean).join(', ')}
                      {address.country && `, ${address.country}`}
                    </div>
                  </div>
                )}
                {!primaryTelecom && !email && !address && (
                  <p className="text-sm text-gray-400">No contact info on record.</p>
                )}
              </CardContent>
            </Card>

          </div>
        </TabsContent>

        {/* Encounters */}
        <TabsContent value="encounters">
          <div className="flex justify-between items-center mb-3">
            <h3 className="text-sm font-medium text-gray-700">
              {encounters?.length ?? 0} encounter(s)
            </h3>
            <Button
              size="sm"
              className="gap-1"
              onClick={() => navigate(`/encounters/new?patientId=${id}`)}
            >
              <Plus className="w-4 h-4" />New Encounter
            </Button>
          </div>
          <DataTable
            columns={encounterCols}
            data={encounters ?? []}
            loading={encLoading}
            keyExtractor={(e) => e.id}
            emptyMessage="No encounters on record."
          />
        </TabsContent>

        {/* Coverage */}
        <TabsContent value="coverage">
          <div className="flex justify-between items-center mb-3">
            <h3 className="text-sm font-medium text-gray-700">
              {coverage?.length ?? 0} coverage plan(s)
            </h3>
            <Button
              size="sm"
              className="gap-1"
              onClick={() => navigate(`/billing/coverage/new?patientId=${id}`)}
            >
              <Plus className="w-4 h-4" />Add Coverage
            </Button>
          </div>
          {covLoading ? (
            <div className="space-y-2">
              {[1, 2].map((i) => <Skeleton key={i} className="h-24 w-full" />)}
            </div>
          ) : coverage?.length === 0 ? (
            <p className="text-sm text-gray-400 py-8 text-center">No insurance coverage on record.</p>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {coverage?.map((cov) => (
                <Card key={cov.id}>
                  <CardContent className="p-4">
                    <div className="flex justify-between items-start mb-3">
                      <div>
                        <p className="font-semibold text-gray-900">{cov.planName}</p>
                        <p className="text-sm text-gray-500">{cov.payerName ?? 'Unknown Payer'}</p>
                      </div>
                      <CoverageStatusBadge status={cov.status} />
                    </div>
                    <div className="grid grid-cols-2 gap-y-1.5 text-xs">
                      <span className="text-gray-500">Type</span>
                      <span className="capitalize">{cov.type}</span>
                      <span className="text-gray-500">Subscriber ID</span>
                      <span className="font-mono">{cov.subscriberId}</span>
                      <span className="text-gray-500">Group #</span>
                      <span>{cov.groupNumber ?? '—'}</span>
                      <span className="text-gray-500">Period</span>
                      <span>
                        {formatDate(cov.periodStart)} – {cov.periodEnd ? formatDate(cov.periodEnd) : 'Ongoing'}
                      </span>
                    </div>
                    <div className="mt-3 flex justify-end">
                      <Button
                        size="sm"
                        variant="ghost"
                        className="text-red-500 hover:text-red-700 hover:bg-red-50 text-xs"
                        onClick={() => setRemoveCoverageId(cov.id)}
                      >
                        Remove
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* Audit */}
        <TabsContent value="audit">
          <DataTable
            columns={auditCols}
            data={auditEvents ?? []}
            loading={auditLoading}
            keyExtractor={(e) => e.id}
            emptyMessage="No audit events found for this patient."
          />
        </TabsContent>
      </Tabs>

      <ConfirmDialog
        open={deleteOpen}
        onOpenChange={setDeleteOpen}
        title="Delete Patient"
        description={`Are you sure you want to remove ${displayName}? This action will soft-delete the patient record.`}
        confirmLabel="Delete Patient"
        onConfirm={handleDelete}
        loading={deletePatient.isPending}
      />

      <ConfirmDialog
        open={!!removeCoverageId}
        onOpenChange={(o) => !o && setRemoveCoverageId(null)}
        title="Remove Coverage"
        description="Are you sure you want to remove this insurance coverage plan?"
        confirmLabel="Remove Coverage"
        onConfirm={handleRemoveCoverage}
        loading={removeCoverage.isPending}
      />
    </PageWrapper>
  );
}
