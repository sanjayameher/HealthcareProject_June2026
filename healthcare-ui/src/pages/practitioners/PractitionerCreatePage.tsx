import { useNavigate } from 'react-router-dom';
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
import { useCreatePractitioner } from '@/hooks/usePractitioners';

const schema = z.object({
  npi: z
    .string()
    .optional()
    .refine((v) => !v || /^\d{10}$/.test(v), 'NPI must be exactly 10 digits'),
  familyName: z.string().min(1, 'Last name is required').max(100),
  givenName: z.string().min(1, 'First name is required'),
  prefix: z.string().optional(),
  suffix: z.string().optional(),
  gender: z.enum(['male', 'female', 'other', 'unknown']).optional(),
  birthDate: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

export function PractitionerCreatePage() {
  const navigate = useNavigate();
  const createPractitioner = useCreatePractitioner();

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<FormValues>({ resolver: zodResolver(schema) });

  const onSubmit = async (values: FormValues) => {
    const practitioner = await createPractitioner.mutateAsync({
      npi: values.npi || undefined,
      familyName: values.familyName,
      givenName: values.givenName,
      prefix: values.prefix || undefined,
      suffix: values.suffix || undefined,
      gender: values.gender,
      birthDate: values.birthDate || undefined,
    });
    navigate(`/practitioners/${practitioner.id}`);
  };

  return (
    <PageWrapper title="Register Practitioner">
      <PageHeader title="Register Practitioner" backTo="/practitioners" />
      <Card className="max-w-xl">
        <CardHeader>
          <CardTitle>Practitioner Information</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <FormField label="NPI" error={errors.npi?.message} hint="10-digit National Provider Identifier">
              <Input placeholder="1234567890" maxLength={10} {...register('npi')} />
            </FormField>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="Prefix">
                <Input placeholder="Dr. Mr. Ms." {...register('prefix')} />
              </FormField>
              <FormField label="Suffix">
                <Input placeholder="MD PhD Jr." {...register('suffix')} />
              </FormField>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="First Name" required error={errors.givenName?.message}>
                <Input placeholder="John" {...register('givenName')} />
              </FormField>
              <FormField label="Last Name" required error={errors.familyName?.message}>
                <Input placeholder="Smith" {...register('familyName')} />
              </FormField>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="Gender">
                <Select onValueChange={(v) => setValue('gender', v as FormValues['gender'])}>
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
              <FormField label="Date of Birth">
                <Input
                  type="date"
                  max={new Date().toISOString().split('T')[0]}
                  {...register('birthDate')}
                />
              </FormField>
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <Button variant="outline" type="button" onClick={() => navigate('/practitioners')}>
                Cancel
              </Button>
              <Button type="submit" disabled={createPractitioner.isPending}>
                {createPractitioner.isPending ? 'Registering...' : 'Register Practitioner'}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </PageWrapper>
  );
}
