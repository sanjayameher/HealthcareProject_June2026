import { useParams, useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useEffect } from 'react';
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
import { Skeleton } from '@/components/ui/skeleton';
import { usePatient, useUpdatePatient } from '@/hooks/usePatients';
import type { UpdatePatientRequest } from '@/types';

// Backend UpdatePatientRequest: gender, birthDate, preferredLanguage, active, version only
const schema = z.object({
  gender: z.enum(['male', 'female', 'other', 'unknown']),
  birthDate: z
    .string()
    .min(1, 'Date of birth is required')
    .refine((d) => new Date(d) < new Date(), 'Date of birth must be in the past'),
  preferredLanguage: z.string().optional(),
  active: z.boolean().optional(),
});

type FormValues = z.infer<typeof schema>;

export function PatientEditPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data: patient, isLoading } = usePatient(id!);
  const updatePatient = useUpdatePatient(id!);

  const {
    register,
    handleSubmit,
    setValue,
    reset,
    formState: { errors },
  } = useForm<FormValues>({ resolver: zodResolver(schema) });

  useEffect(() => {
    if (patient) {
      reset({
        gender: patient.gender,
        birthDate: patient.birthDate ?? '',
        active: patient.active,
      });
    }
  }, [patient, reset]);

  const onSubmit = async (values: FormValues) => {
    const payload: UpdatePatientRequest = {
      gender: values.gender,
      birthDate: values.birthDate,
      preferredLanguage: values.preferredLanguage || undefined,
      active: values.active,
      version: patient!.version,
    };

    await updatePatient.mutateAsync(payload);
    navigate(`/patients/${id}`);
  };

  if (isLoading) {
    return (
      <PageWrapper title="Edit Patient">
        <Skeleton className="h-64 w-full" />
      </PageWrapper>
    );
  }

  return (
    <PageWrapper title="Edit Patient">
      <PageHeader title="Edit Patient" backTo={`/patients/${id}`} />
      <Card className="max-w-lg">
        <CardHeader>
          <CardTitle>Update Patient Demographics</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <FormField label="Gender" required error={errors.gender?.message}>
                <Select
                  onValueChange={(v) => setValue('gender', v as FormValues['gender'])}
                  defaultValue={patient?.gender}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select gender" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="male">Male</SelectItem>
                    <SelectItem value="female">Female</SelectItem>
                    <SelectItem value="other">Other</SelectItem>
                    <SelectItem value="unknown">Unknown</SelectItem>
                  </SelectContent>
                </Select>
              </FormField>

              <FormField
                label="Date of Birth"
                required
                error={errors.birthDate?.message}
              >
                <Input
                  type="date"
                  max={new Date().toISOString().split('T')[0]}
                  {...register('birthDate')}
                />
              </FormField>
            </div>

            <FormField label="Preferred Language">
              <Input placeholder="e.g. English" {...register('preferredLanguage')} />
            </FormField>

            <div className="flex justify-end gap-2 pt-2">
              <Button
                variant="outline"
                type="button"
                onClick={() => navigate(`/patients/${id}`)}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={updatePatient.isPending}>
                {updatePatient.isPending ? 'Saving...' : 'Save Changes'}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </PageWrapper>
  );
}
