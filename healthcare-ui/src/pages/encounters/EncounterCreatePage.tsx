import { useNavigate, useSearchParams } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useState } from 'react';
import { PageWrapper } from '@/components/layout/PageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { FormField } from '@/components/common/FormField';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useCreateEncounter } from '@/hooks/useEncounters';
import { usePatients } from '@/hooks/usePatients';
import type { EncounterClass, EncounterStatus } from '@/types';
import { formatPatientName } from '@/utils/formatters';

const schema = z.object({
  patientId: z.string().min(1, 'Patient is required'),
  status: z.enum(['planned', 'arrived', 'in_progress', 'finished', 'cancelled']),
  encounterClass: z.enum(['outpatient', 'inpatient', 'ambulatory', 'emergency', 'home', 'virtual', 'observation']),
  typeDisplay: z.string().optional(),
  periodStart: z.string().optional(),
  periodEnd: z.string().optional(),
  chiefComplaint: z.string().optional(),
  telehealthPlatform: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

export function EncounterCreatePage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const defaultPatientId = searchParams.get('patientId') ?? '';
  const createEncounter = useCreateEncounter();
  const { data: patients } = usePatients();

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      status: 'planned',
      encounterClass: 'outpatient',
      patientId: defaultPatientId,
    },
  });

  const watchClass = watch('encounterClass');

  // HTML datetime-local produces "YYYY-MM-DDTHH:mm" with no timezone.
  // Append seconds + UTC offset so the backend can parse it as OffsetDateTime.
  const toIso = (dt?: string) => (dt ? dt + ':00Z' : undefined);

  const onSubmit = async (values: FormValues) => {
    const encounter = await createEncounter.mutateAsync({
      patientId: values.patientId,
      status: values.status,
      encounterClass: values.encounterClass,
      typeDisplay: values.typeDisplay || undefined,
      periodStart: toIso(values.periodStart),
      periodEnd: toIso(values.periodEnd),
      chiefComplaint: values.chiefComplaint || undefined,
      telehealthPlatform:
        values.encounterClass === 'virtual' ? values.telehealthPlatform || undefined : undefined,
    });
    navigate(`/patients/${encounter.patientId}`);
  };

  return (
    <PageWrapper title="New Encounter">
      <PageHeader title="Create Encounter" backTo="/patients" />
      <Card className="max-w-2xl">
        <CardHeader>
          <CardTitle>Encounter Details</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <FormField label="Patient" required error={errors.patientId?.message}>
              <Select
                onValueChange={(v) => setValue('patientId', v)}
                defaultValue={defaultPatientId}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select patient..." />
                </SelectTrigger>
                <SelectContent>
                  {patients?.map((p) => (
                    <SelectItem key={p.id} value={p.id}>
                      {formatPatientName(p.names)} {p.mrn ? `(${p.mrn})` : ''}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </FormField>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="Status" required error={errors.status?.message}>
                <Select
                  onValueChange={(v) => setValue('status', v as EncounterStatus)}
                  defaultValue="planned"
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="planned">Planned</SelectItem>
                    <SelectItem value="arrived">Arrived</SelectItem>
                    <SelectItem value="in_progress">In Progress</SelectItem>
                    <SelectItem value="finished">Finished</SelectItem>
                    <SelectItem value="cancelled">Cancelled</SelectItem>
                  </SelectContent>
                </Select>
              </FormField>

              <FormField label="Encounter Class" required error={errors.encounterClass?.message}>
                <Select
                  onValueChange={(v) => setValue('encounterClass', v as EncounterClass)}
                  defaultValue="outpatient"
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="outpatient">Outpatient</SelectItem>
                    <SelectItem value="inpatient">Inpatient</SelectItem>
                    <SelectItem value="ambulatory">Ambulatory</SelectItem>
                    <SelectItem value="emergency">Emergency</SelectItem>
                    <SelectItem value="home">Home</SelectItem>
                    <SelectItem value="virtual">Virtual / Telehealth</SelectItem>
                    <SelectItem value="observation">Observation</SelectItem>
                  </SelectContent>
                </Select>
              </FormField>
            </div>

            <FormField label="Type Display">
              <Input placeholder="e.g. Follow-up visit, Initial consultation" {...register('typeDisplay')} />
            </FormField>

            {watchClass === 'virtual' && (
              <FormField label="Telehealth Platform">
                <Input placeholder="e.g. Zoom Health, Doximity, Epic MyChart" {...register('telehealthPlatform')} />
              </FormField>
            )}

            <div className="grid grid-cols-2 gap-4">
              <FormField label="Period Start">
                <Input type="datetime-local" {...register('periodStart')} />
              </FormField>
              <FormField label="Period End">
                <Input type="datetime-local" {...register('periodEnd')} />
              </FormField>
            </div>

            <FormField label="Chief Complaint">
              <Textarea
                placeholder="Patient's primary reason for visit..."
                {...register('chiefComplaint')}
                rows={3}
              />
            </FormField>

            <div className="flex justify-end gap-2 pt-2">
              <Button variant="outline" type="button" onClick={() => navigate(-1)}>
                Cancel
              </Button>
              <Button type="submit" disabled={createEncounter.isPending}>
                {createEncounter.isPending ? 'Creating...' : 'Create Encounter'}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </PageWrapper>
  );
}
