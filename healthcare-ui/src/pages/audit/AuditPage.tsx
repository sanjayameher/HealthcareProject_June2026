import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { PageWrapper } from '@/components/layout/PageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { DataTable } from '@/components/common/DataTable';
import { FormField } from '@/components/common/FormField';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { usePatientAuditTrail, useUserAuditTrail } from '@/hooks/useAudit';
import { formatDateTime } from '@/utils/formatters';
import type { AuditEvent } from '@/types';

type SearchForm = {
  patientId: string;
  userId: string;
  from: string;
  to: string;
};

type SearchMode = 'patient' | 'user' | null;

export function AuditPage() {
  const [searchMode, setSearchMode] = useState<SearchMode>(null);
  const [submitted, setSubmitted] = useState<SearchForm | null>(null);

  const { register, handleSubmit } = useForm<SearchForm>();

  const patientQuery = usePatientAuditTrail(
    submitted?.patientId ?? '',
    submitted
      ? { from: submitted.from || undefined, to: submitted.to || undefined }
      : undefined
  );

  const userQuery = useUserAuditTrail(
    submitted?.userId ?? '',
    submitted
      ? { from: submitted.from || undefined, to: submitted.to || undefined }
      : undefined
  );

  const activeQuery = searchMode === 'patient' ? patientQuery : userQuery;

  const onSubmit = (values: SearchForm) => {
    setSubmitted(values);
    setSearchMode(values.patientId ? 'patient' : 'user');
  };

  const columns = [
    {
      key: 'time',
      header: 'Time',
      render: (row: AuditEvent) => (
        <span className="text-xs font-mono">{formatDateTime(row.occurredAt)}</span>
      ),
    },
    {
      key: 'action',
      header: 'Action',
      render: (row: AuditEvent) => <span className="font-medium">{row.action}</span>,
    },
    {
      key: 'entity',
      header: 'Entity',
      render: (row: AuditEvent) => (
        <span>
          {row.entityType} {row.entityId ? `(${row.entityId.slice(0, 8)}...)` : ''}
        </span>
      ),
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
    {
      key: 'ip',
      header: 'IP Address',
      render: (row: AuditEvent) => (
        <span className="font-mono text-xs text-gray-500">{row.ipAddress ?? '—'}</span>
      ),
    },
  ];

  return (
    <PageWrapper title="Audit Trail">
      <PageHeader
        title="Audit Trail"
        subtitle="HIPAA-compliant access log for PHI — who accessed what and when"
      />

      <Card className="mb-6">
        <CardContent className="pt-4">
          <form onSubmit={handleSubmit(onSubmit)} className="grid grid-cols-2 gap-4">
            <FormField label="Patient ID" hint="Search audit events for a patient">
              <Input placeholder="Patient UUID" {...register('patientId')} />
            </FormField>

            <FormField label="User ID" hint="Search audit events by user">
              <Input placeholder="User UUID" {...register('userId')} />
            </FormField>

            <FormField label="From Date">
              <Input type="datetime-local" {...register('from')} />
            </FormField>

            <FormField label="To Date">
              <Input type="datetime-local" {...register('to')} />
            </FormField>

            <div className="col-span-2 flex justify-end gap-2">
              <Button
                type="button"
                variant="ghost"
                onClick={() => {
                  setSubmitted(null);
                  setSearchMode(null);
                }}
              >
                Clear
              </Button>
              <Button type="submit">Search Audit Trail</Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {searchMode && (
        <DataTable
          columns={columns}
          data={activeQuery.data ?? []}
          loading={activeQuery.isLoading}
          keyExtractor={(e) => e.id}
          emptyMessage="No audit events found for this query."
        />
      )}

      {!searchMode && (
        <div className="text-center py-16 text-gray-400">
          <p className="text-sm">Enter a Patient ID or User ID above to search audit events.</p>
        </div>
      )}
    </PageWrapper>
  );
}
