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
import { useCreatePayer } from '@/hooks/useBilling';

const schema = z.object({
  name: z.string().min(1, 'Payer name is required'),
  type: z.string().optional(),
  payerId: z.string().optional(),
  phone: z.string().optional(),
  email: z.string().email('Invalid email').optional().or(z.literal('')),
});

type FormValues = z.infer<typeof schema>;

export function PayerCreatePage() {
  const navigate = useNavigate();
  const createPayer = useCreatePayer();

  const { register, handleSubmit, formState: { errors } } = useForm<FormValues>({
    resolver: zodResolver(schema),
  });

  const onSubmit = async (values: FormValues) => {
    await createPayer.mutateAsync({
      name: values.name,
      type: values.type || undefined,
      payerId: values.payerId || undefined,
      phone: values.phone || undefined,
      email: values.email || undefined,
      active: true,
    });
    navigate('/billing/payers');
  };

  return (
    <PageWrapper title="Add Payer">
      <PageHeader title="Add Insurance Payer" backTo="/billing/payers" />
      <Card className="max-w-xl">
        <CardHeader>
          <CardTitle>Payer Details</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <FormField label="Payer Name" required error={errors.name?.message}>
              <Input placeholder="Blue Cross Blue Shield" {...register('name')} />
            </FormField>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="Type">
                <Input placeholder="Commercial, Medicare, Medicaid..." {...register('type')} />
              </FormField>
              <FormField label="Payer ID">
                <Input placeholder="00001" {...register('payerId')} />
              </FormField>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="Phone" error={errors.phone?.message}>
                <Input type="tel" placeholder="+1 800-000-0000" {...register('phone')} />
              </FormField>
              <FormField label="Email" error={errors.email?.message}>
                <Input type="email" placeholder="claims@payer.com" {...register('email')} />
              </FormField>
            </div>

            <div className="flex justify-end gap-2 pt-2">
              <Button variant="outline" type="button" onClick={() => navigate('/billing/payers')}>
                Cancel
              </Button>
              <Button type="submit" disabled={createPayer.isPending}>
                {createPayer.isPending ? 'Adding...' : 'Add Payer'}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </PageWrapper>
  );
}
