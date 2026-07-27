import { useState } from 'react';
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
import { useCreatePatient } from '@/hooks/usePatients';
import type { CreatePatientRequest } from '@/types';

const STEPS = ['Basic Info', 'Name', 'Contact', 'Address', 'Review'];

const basicSchema = z.object({
  gender: z.enum(['male', 'female', 'other', 'unknown'], {
    error: 'Gender is required',
  }),
  birthDate: z
    .string()
    .min(1, 'Date of birth is required')
    .refine((d) => new Date(d) < new Date(), 'Date of birth must be in the past'),
  preferredLanguage: z.string().optional(),
  managingOrganizationId: z.string().optional(),
});

const nameSchema = z.object({
  nameUse: z.enum(['official', 'usual', 'temp', 'nickname', 'maiden', 'old']),
  family: z.string().min(1, 'Last name is required').max(100),
  given: z.string().min(1, 'First name is required'),
  prefix: z.string().optional(),
  suffix: z.string().optional(),
});

const contactSchema = z.object({
  phone: z.string().optional(),
  email: z.string().optional().refine(
    (v) => !v || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
    'Invalid email address'
  ),
});

// Address is fully optional — but if any field is filled, enforce backend rules
const addressSchema = z
  .object({
    line1:      z.string().max(500).optional(),
    line2:      z.string().max(500).optional(),
    city:       z.string().max(100).optional(),
    // DB: VARCHAR(2) — must be 2-letter ISO 3166-2 subdivision code
    state: z
      .string()
      .optional()
      .refine(
        (s) => !s || /^[A-Z]{2}$/.test(s),
        'State must be exactly 2 uppercase letters (e.g. TX, KA)'
      ),
    // DB: VARCHAR(10) — max 10 chars; US format enforced by DB when country=US
    postalCode: z
      .string()
      .optional()
      .refine(
        (p) => !p || p.length <= 10,
        'Postal code must be 10 characters or fewer'
      ),
    // DB: VARCHAR(2) NOT NULL DEFAULT 'US' — ISO 3166-1 alpha-2
    country: z
      .string()
      .optional()
      .refine(
        (c) => !c || /^[A-Z]{2}$/.test(c),
        'Country must be a 2-letter ISO code (e.g. IN, US, GB)'
      ),
  })
  .refine(
    (a) => {
      // If any address field is provided, both line1 and city are required
      const hasAny = a.line1 || a.city || a.state || a.postalCode || a.country;
      if (hasAny) return !!a.line1 && !!a.city;
      return true;
    },
    { message: 'Street address and city are required when adding an address', path: ['line1'] }
  )
  .refine(
    (a) => {
      // DB check constraint: if country=US, postal code must be US ZIP format
      const country = a.country?.toUpperCase() || 'US';
      if (country === 'US' && a.postalCode) {
        return /^\d{5}(-\d{4})?$/.test(a.postalCode);
      }
      return true;
    },
    { message: 'US postal codes must be 5 digits (e.g. 75019 or 75019-1234)', path: ['postalCode'] }
  );

type BasicForm = z.infer<typeof basicSchema>;
type NameForm = z.infer<typeof nameSchema>;
type ContactForm = z.infer<typeof contactSchema>;
type AddressForm = z.infer<typeof addressSchema>;

export function PatientRegisterPage() {
  const navigate = useNavigate();
  const [step, setStep] = useState(0);
  const createPatient = useCreatePatient();

  const basicForm = useForm<BasicForm>({ resolver: zodResolver(basicSchema) });
  const nameForm = useForm<NameForm>({
    resolver: zodResolver(nameSchema),
    defaultValues: { nameUse: 'official' },
  });
  const contactForm = useForm<ContactForm>({ resolver: zodResolver(contactSchema) });
  const addressForm = useForm<AddressForm>({ resolver: zodResolver(addressSchema) });

  const [formData, setFormData] = useState<{
    basic?: BasicForm;
    name?: NameForm;
    contact?: ContactForm;
    address?: AddressForm;
  }>({});

  const saveStep = (data: BasicForm | NameForm | ContactForm | AddressForm) => {
    if (step === 0) setFormData((p) => ({ ...p, basic: data as BasicForm }));
    else if (step === 1) setFormData((p) => ({ ...p, name: data as NameForm }));
    else if (step === 2) setFormData((p) => ({ ...p, contact: data as ContactForm }));
    else if (step === 3) setFormData((p) => ({ ...p, address: data as AddressForm }));
    setStep((s) => s + 1);
  };

  const handleSubmit = async () => {
    const { basic, name, contact, address } = formData;
    if (!basic || !name) return;

    const telecoms = [];
    if (contact?.phone)
      telecoms.push({ system: 'phone' as const, value: contact.phone, use: 'mobile' as const });
    if (contact?.email)
      telecoms.push({ system: 'email' as const, value: contact.email });

    // Only include address when both line1 AND city are present (backend @NotBlank)
    const addresses = [];
    if (address?.line1 && address?.city) {
      addresses.push({
        use: 'home' as const,
        type: 'physical' as const,
        line1: address.line1,
        line2: address.line2 || undefined,
        city: address.city,
        // Backend requires exactly 2 uppercase letters; auto-uppercase what user typed
        state: address.state ? address.state.toUpperCase() : undefined,
        postalCode: address.postalCode || undefined,
        country: address.country || undefined,
      });
    }

    const payload: CreatePatientRequest = {
      gender: basic.gender,
      birthDate: basic.birthDate,
      preferredLanguage: basic.preferredLanguage || undefined,
      managingOrganizationId: basic.managingOrganizationId || undefined,
      names: [
        {
          use: name.nameUse,
          family: name.family,
          given: name.given.split(' ').filter(Boolean),
          prefix: name.prefix || undefined,
          suffix: name.suffix || undefined,
        },
      ],
      telecoms: telecoms.length ? telecoms : undefined,
      addresses: addresses.length ? addresses : undefined,
    };

    const patient = await createPatient.mutateAsync(payload);
    navigate(`/patients/${patient.id}`);
  };

  return (
    <PageWrapper title="Register Patient">
      <PageHeader title="Register New Patient" backTo="/patients" />

      {/* Step indicator */}
      <div className="flex items-center gap-2 mb-8 flex-wrap">
        {STEPS.map((label, i) => (
          <div key={label} className="flex items-center gap-2">
            <div
              className={`flex items-center justify-center w-8 h-8 rounded-full text-sm font-semibold ${
                i < step
                  ? 'bg-green-500 text-white'
                  : i === step
                  ? 'bg-medical-500 text-white'
                  : 'bg-gray-200 text-gray-500'
              }`}
            >
              {i < step ? '✓' : i + 1}
            </div>
            <span
              className={`text-sm ${i === step ? 'text-medical-700 font-medium' : 'text-gray-400'}`}
            >
              {label}
            </span>
            {i < STEPS.length - 1 && <div className="w-8 h-0.5 bg-gray-200" />}
          </div>
        ))}
      </div>

      <Card className="max-w-2xl">
        <CardHeader>
          <CardTitle>{STEPS[step]}</CardTitle>
        </CardHeader>
        <CardContent>
          {/* Step 0: Basic Info */}
          {step === 0 && (
            <form onSubmit={basicForm.handleSubmit(saveStep)} className="space-y-4">
              <FormField
                label="Gender"
                required
                error={basicForm.formState.errors.gender?.message}
              >
                <Select
                  onValueChange={(v) =>
                    basicForm.setValue('gender', v as BasicForm['gender'], {
                      shouldValidate: true,
                    })
                  }
                  defaultValue={basicForm.getValues('gender')}
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
                error={basicForm.formState.errors.birthDate?.message}
                hint="Must be a past date"
              >
                <Input
                  type="date"
                  max={new Date().toISOString().split('T')[0]}
                  {...basicForm.register('birthDate')}
                />
              </FormField>

              <FormField
                label="Preferred Language"
                error={basicForm.formState.errors.preferredLanguage?.message}
              >
                <Input placeholder="e.g. English" {...basicForm.register('preferredLanguage')} />
              </FormField>

              <div className="flex justify-end gap-2 pt-2">
                <Button type="submit">Next</Button>
              </div>
            </form>
          )}

          {/* Step 1: Name */}
          {step === 1 && (
            <form onSubmit={nameForm.handleSubmit(saveStep)} className="space-y-4">
              <FormField
                label="Name Use"
                required
                error={nameForm.formState.errors.nameUse?.message}
              >
                <Select
                  onValueChange={(v) => nameForm.setValue('nameUse', v as NameForm['nameUse'])}
                  defaultValue={nameForm.getValues('nameUse')}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select name use" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="official">Official</SelectItem>
                    <SelectItem value="usual">Usual</SelectItem>
                    <SelectItem value="nickname">Nickname</SelectItem>
                    <SelectItem value="maiden">Maiden</SelectItem>
                  </SelectContent>
                </Select>
              </FormField>

              <div className="grid grid-cols-2 gap-4">
                <FormField label="Prefix" error={nameForm.formState.errors.prefix?.message}>
                  <Input placeholder="Mr. Dr. Ms." {...nameForm.register('prefix')} />
                </FormField>
                <FormField label="Suffix" error={nameForm.formState.errors.suffix?.message}>
                  <Input placeholder="Jr. III MD" {...nameForm.register('suffix')} />
                </FormField>
              </div>

              <FormField
                label="First Name(s)"
                required
                error={nameForm.formState.errors.given?.message}
                hint="Enter all given names separated by spaces"
              >
                <Input placeholder="John Michael" {...nameForm.register('given')} />
              </FormField>

              <FormField
                label="Last Name"
                required
                error={nameForm.formState.errors.family?.message}
              >
                <Input placeholder="Doe" {...nameForm.register('family')} />
              </FormField>

              <div className="flex justify-between pt-2">
                <Button variant="outline" type="button" onClick={() => setStep(0)}>
                  Back
                </Button>
                <Button type="submit">Next</Button>
              </div>
            </form>
          )}

          {/* Step 2: Contact */}
          {step === 2 && (
            <form onSubmit={contactForm.handleSubmit(saveStep)} className="space-y-4">
              <FormField label="Phone" error={contactForm.formState.errors.phone?.message}>
                <Input
                  type="tel"
                  placeholder="+1 555-000-0000"
                  {...contactForm.register('phone')}
                />
              </FormField>

              <FormField label="Email" error={contactForm.formState.errors.email?.message}>
                <Input
                  type="email"
                  placeholder="patient@example.com"
                  {...contactForm.register('email')}
                />
              </FormField>

              <div className="flex justify-between pt-2">
                <Button variant="outline" type="button" onClick={() => setStep(1)}>
                  Back
                </Button>
                <Button type="submit">Next</Button>
              </div>
            </form>
          )}

          {/* Step 3: Address (fully optional — skip if not needed) */}
          {step === 3 && (
            <form onSubmit={addressForm.handleSubmit(saveStep)} className="space-y-4">
              <p className="text-xs text-gray-400 mb-2">
                Address is optional. If provided, street and city are required.
              </p>

              <FormField
                label="Street Address (Line 1)"
                error={addressForm.formState.errors.line1?.message}
                hint="Flat/house number, street name"
              >
                <Input
                  placeholder="Flat 115, Friends Nest Apartment"
                  maxLength={500}
                  {...addressForm.register('line1')}
                />
              </FormField>

              <FormField
                label="Street Address (Line 2)"
                error={addressForm.formState.errors.line2?.message}
                hint="Area, landmark (optional)"
              >
                <Input
                  placeholder="Near RTO Office, Medahalli"
                  maxLength={500}
                  {...addressForm.register('line2')}
                />
              </FormField>

              <div className="grid grid-cols-2 gap-4">
                <FormField label="City" error={addressForm.formState.errors.city?.message}>
                  <Input
                    placeholder="Bangalore"
                    maxLength={100}
                    {...addressForm.register('city')}
                  />
                </FormField>
                <FormField
                  label="State / Province"
                  error={addressForm.formState.errors.state?.message}
                  hint="2-letter code e.g. KA, TX, NY"
                >
                  <Input
                    placeholder="KA"
                    maxLength={2}
                    {...addressForm.register('state', {
                      onChange: (e) => {
                        e.target.value = e.target.value.toUpperCase();
                      },
                    })}
                  />
                </FormField>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <FormField
                  label="Postal Code"
                  error={addressForm.formState.errors.postalCode?.message}
                  hint="Max 10 chars — e.g. 560004 (IN) or 75019 (US)"
                >
                  <Input
                    placeholder="560004"
                    maxLength={10}
                    {...addressForm.register('postalCode')}
                  />
                </FormField>
                <FormField
                  label="Country"
                  error={addressForm.formState.errors.country?.message}
                  hint="2-letter ISO code e.g. IN, US, GB (default: US)"
                >
                  <Input
                    placeholder="IN"
                    maxLength={2}
                    {...addressForm.register('country', {
                      onChange: (e) => {
                        e.target.value = e.target.value.toUpperCase();
                      },
                    })}
                  />
                </FormField>
              </div>

              <div className="flex justify-between pt-2">
                <Button variant="outline" type="button" onClick={() => setStep(2)}>
                  Back
                </Button>
                <Button type="submit">Review</Button>
              </div>
            </form>
          )}

          {/* Step 4: Review */}
          {step === 4 && (
            <div className="space-y-6">
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-gray-500">Name</p>
                  <p className="font-medium">
                    {[
                      formData.name?.prefix,
                      formData.name?.given,
                      formData.name?.family,
                      formData.name?.suffix,
                    ]
                      .filter(Boolean)
                      .join(' ')}
                  </p>
                </div>
                <div>
                  <p className="text-gray-500">Gender</p>
                  <p className="font-medium capitalize">{formData.basic?.gender}</p>
                </div>
                <div>
                  <p className="text-gray-500">Date of Birth</p>
                  <p className="font-medium">{formData.basic?.birthDate}</p>
                </div>
                <div>
                  <p className="text-gray-500">Preferred Language</p>
                  <p className="font-medium">{formData.basic?.preferredLanguage || '—'}</p>
                </div>
                <div>
                  <p className="text-gray-500">Phone</p>
                  <p className="font-medium">{formData.contact?.phone || '—'}</p>
                </div>
                <div>
                  <p className="text-gray-500">Email</p>
                  <p className="font-medium">{formData.contact?.email || '—'}</p>
                </div>
                <div className="col-span-2">
                  <p className="text-gray-500">Address</p>
                  <p className="font-medium">
                    {formData.address?.line1 && formData.address?.city
                      ? [
                          formData.address.line1,
                          formData.address.line2,
                          formData.address.city,
                          formData.address.state,
                          formData.address.postalCode,
                        ]
                          .filter(Boolean)
                          .join(', ')
                      : '—'}
                  </p>
                </div>
              </div>

              <div className="flex justify-between pt-2">
                <Button variant="outline" type="button" onClick={() => setStep(3)}>
                  Back
                </Button>
                <Button onClick={handleSubmit} disabled={createPatient.isPending}>
                  {createPatient.isPending ? 'Registering...' : 'Register Patient'}
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </PageWrapper>
  );
}
