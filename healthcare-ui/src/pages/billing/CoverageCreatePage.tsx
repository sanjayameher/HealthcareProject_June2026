import { useNavigate, useSearchParams } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { PageWrapper } from '@/components/layout/PageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { FormField } from '@/components/common/FormField';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useAddCoverage, usePayers } from '@/hooks/useBilling';
import { usePatients } from '@/hooks/usePatients';
import type { CoverageType, CoverageStatus, SubscriberRelationship } from '@/types';
import { toBase64, formatPatientName } from '@/utils/formatters';

const schema = z.object({
  patientId: z.string().min(1, 'Patient is required'),
  payerId: z.string().min(1, 'Payer is required'),
  planName: z.string().min(1, 'Plan name is required'),
  type: z.enum(['medical', 'dental', 'vision', 'pharmacy', 'other']),
  status: z.enum(['active', 'cancelled', 'draft']),
  subscriberRelationship: z.enum(['self', 'spouse', 'child', 'parent', 'other']),
  subscriberId: z.string().min(1, 'Subscriber ID is required'),
  groupNumber: z.string().optional(),
  periodStart: z.string().min(1, 'Start date is required'),
  periodEnd: z.string().optional(),
  orderOfBenefit: z.number().min(1).max(10),
});

type FormValues = z.infer<typeof schema>;

export function CoverageCreatePage() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const defaultPatientId = searchParams.get('patientId') ?? '';

  const addCoverage = useAddCoverage();
  const { data: payers } = usePayers();
  const { data: patients } = usePatients();

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      patientId: defaultPatientId,
      status: 'active',
      type: 'medical',
      subscriberRelationship: 'self',
      orderOfBenefit: 1,
    },
  });

  const onSubmit = async (values: FormValues) => {
    const coverage = await addCoverage.mutateAsync({
      patientId: values.patientId,
      payerId: values.payerId,
      planName: values.planName,
      type: values.type,
      status: values.status,
      subscriberRelationship: values.subscriberRelationship,
      subscriberId: toBase64(values.subscriberId),
      subscriberIdHash: toBase64(values.subscriberId),
      groupNumber: values.groupNumber || undefined,
      periodStart: values.periodStart,
      periodEnd: values.periodEnd || undefined,
      orderOfBenefit: values.orderOfBenefit,
    });
    navigate(`/patients/${coverage.patientId}`);
  };

  return (
    <PageWrapper title="Add Coverage">
      <PageHeader title="Add Insurance Coverage" backTo="/billing/payers" />
      <Card className="max-w-2xl">
        <CardHeader>
          <CardTitle>Coverage Details</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
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

              <FormField label="Payer" required error={errors.payerId?.message}>
                <Select onValueChange={(v) => setValue('payerId', v)}>
                  <SelectTrigger>
                    <SelectValue placeholder="Select payer..." />
                  </SelectTrigger>
                  <SelectContent>
                    {payers?.map((p) => (
                      <SelectItem key={p.id} value={p.id}>{p.name}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </FormField>
            </div>

            <FormField label="Plan Name" required error={errors.planName?.message}>
              <Input placeholder="Gold PPO 2024" {...register('planName')} />
            </FormField>

            <div className="grid grid-cols-3 gap-4">
              <FormField label="Coverage Type" required error={errors.type?.message}>
                <Select
                  onValueChange={(v) => setValue('type', v as CoverageType)}
                  defaultValue="medical"
                >
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="medical">Medical</SelectItem>
                    <SelectItem value="dental">Dental</SelectItem>
                    <SelectItem value="vision">Vision</SelectItem>
                    <SelectItem value="pharmacy">Pharmacy</SelectItem>
                    <SelectItem value="other">Other</SelectItem>
                  </SelectContent>
                </Select>
              </FormField>

              <FormField label="Status" required error={errors.status?.message}>
                <Select
                  onValueChange={(v) => setValue('status', v as CoverageStatus)}
                  defaultValue="active"
                >
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="active">Active</SelectItem>
                    <SelectItem value="cancelled">Cancelled</SelectItem>
                    <SelectItem value="draft">Draft</SelectItem>
                  </SelectContent>
                </Select>
              </FormField>

              <FormField label="Order of Benefit" required error={errors.orderOfBenefit?.message}>
                <Input type="number" min={1} max={10} {...register('orderOfBenefit', { valueAsNumber: true })} />
              </FormField>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="Subscriber Relationship" required error={errors.subscriberRelationship?.message}>
                <Select
                  onValueChange={(v) => setValue('subscriberRelationship', v as SubscriberRelationship)}
                  defaultValue="self"
                >
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="self">Self</SelectItem>
                    <SelectItem value="spouse">Spouse</SelectItem>
                    <SelectItem value="child">Child</SelectItem>
                    <SelectItem value="parent">Parent</SelectItem>
                    <SelectItem value="other">Other</SelectItem>
                  </SelectContent>
                </Select>
              </FormField>

              <FormField label="Subscriber ID" required error={errors.subscriberId?.message}>
                <Input placeholder="MEM123456" {...register('subscriberId')} />
              </FormField>
            </div>

            <FormField label="Group Number">
              <Input placeholder="GRP001" {...register('groupNumber')} />
            </FormField>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="Period Start" required error={errors.periodStart?.message}>
                <Input type="date" {...register('periodStart')} />
              </FormField>
              <FormField label="Period End (optional)">
                <Input type="date" {...register('periodEnd')} />
              </FormField>
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <Button variant="outline" type="button" onClick={() => navigate(-1)}>
                Cancel
              </Button>
              <Button type="submit" disabled={addCoverage.isPending}>
                {addCoverage.isPending ? 'Adding...' : 'Add Coverage'}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </PageWrapper>
  );
}
