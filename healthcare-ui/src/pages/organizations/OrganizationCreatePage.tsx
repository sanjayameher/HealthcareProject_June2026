import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { PageWrapper } from '@/components/layout/PageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { FormField } from '@/components/common/FormField';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useCreateOrganization } from '@/hooks/useOrganizations';

const schema = z.object({
  name: z.string().min(1, 'Organization name is required').max(200),
  npi: z
    .string()
    .optional()
    .refine((v) => !v || /^\d{10}$/.test(v), 'NPI must be exactly 10 digits'),
  typeCode: z.string().optional(),
  typeDisplay: z.string().optional(),
  phone: z.string().optional(),
  fax: z.string().optional(),
  email: z.string().email('Invalid email').optional().or(z.literal('')),
  city: z.string().optional(),
  state: z
    .string()
    .optional()
    .refine((s) => !s || /^[A-Z]{2}$/.test(s), 'State must be 2 uppercase letters (e.g. CA)'),
  postalCode: z.string().optional(),
});

type FormValues = z.infer<typeof schema>;

export function OrganizationCreatePage() {
  const navigate = useNavigate();
  const createOrg = useCreateOrganization();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({ resolver: zodResolver(schema) });

  const onSubmit = async (values: FormValues) => {
    const org = await createOrg.mutateAsync({
      name: values.name,
      npi: values.npi || undefined,
      typeCode: values.typeCode || undefined,
      typeDisplay: values.typeDisplay || undefined,
      phone: values.phone || undefined,
      fax: values.fax || undefined,
      email: values.email || undefined,
      city: values.city || undefined,
      state: values.state ? values.state.toUpperCase() : undefined,
      postalCode: values.postalCode || undefined,
    });
    navigate(`/organizations/${org.id}`);
  };

  return (
    <PageWrapper title="New Organization">
      <PageHeader title="Create Organization" backTo="/organizations" />
      <Card className="max-w-xl">
        <CardHeader>
          <CardTitle>Organization Details</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <FormField label="Organization Name" required error={errors.name?.message}>
              <Input placeholder="City General Hospital" {...register('name')} />
            </FormField>

            <FormField label="NPI" error={errors.npi?.message} hint="10-digit National Provider Identifier">
              <Input placeholder="1234567890" maxLength={10} {...register('npi')} />
            </FormField>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="Type Code" error={errors.typeCode?.message} hint="e.g. hosp, prov">
                <Input placeholder="hosp" {...register('typeCode')} />
              </FormField>
              <FormField label="Type Display" error={errors.typeDisplay?.message}>
                <Input placeholder="Hospital" {...register('typeDisplay')} />
              </FormField>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="Phone" error={errors.phone?.message}>
                <Input type="tel" placeholder="+1 555-000-0000" {...register('phone')} />
              </FormField>
              <FormField label="Fax" error={errors.fax?.message}>
                <Input type="tel" placeholder="+1 555-000-0001" {...register('fax')} />
              </FormField>
            </div>

            <FormField label="Email" error={errors.email?.message}>
              <Input type="email" placeholder="info@hospital.org" {...register('email')} />
            </FormField>

            <FormField label="City" error={errors.city?.message}>
              <Input placeholder="Springfield" {...register('city')} />
            </FormField>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="State" error={errors.state?.message} hint="2-letter code e.g. IL">
                <Input
                  placeholder="IL"
                  maxLength={2}
                  {...register('state', {
                    onChange: (e) => {
                      e.target.value = e.target.value.toUpperCase();
                    },
                  })}
                />
              </FormField>
              <FormField label="Postal Code" error={errors.postalCode?.message}>
                <Input placeholder="62701" maxLength={10} {...register('postalCode')} />
              </FormField>
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <Button variant="outline" type="button" onClick={() => navigate('/organizations')}>
                Cancel
              </Button>
              <Button type="submit" disabled={createOrg.isPending}>
                {createOrg.isPending ? 'Creating...' : 'Create Organization'}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </PageWrapper>
  );
}
