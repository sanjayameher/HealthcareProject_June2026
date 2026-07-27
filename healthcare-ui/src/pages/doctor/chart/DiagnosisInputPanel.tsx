import { useMutation } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { toast } from 'sonner';
import { Sparkles } from 'lucide-react';
import { cdsApi } from '@/api/cdsApi';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { FormField } from '@/components/common/FormField';
import type { CdsResponse, DiagnosisInputRequest } from '@/types';

const diagnosisFormSchema = z.object({
  chiefComplaint: z.string().min(1, 'Chief complaint is required'),
  symptomsText: z.string().optional(),
  bp: z.string().optional(),
  hr: z.string().optional(),
  temp: z.string().optional(),
  spo2: z.string().optional(),
  weight: z.string().optional(),
  currentMedications: z.string().optional(),
  knownAllergies: z.string().optional(),
  clinicalNotes: z.string().optional(),
});

type DiagnosisFormValues = z.infer<typeof diagnosisFormSchema>;

interface DiagnosisInputPanelProps {
  patientId: string;
  defaultKnownAllergies?: string;
  onResult: (response: CdsResponse) => void;
}

export function DiagnosisInputPanel({ patientId, defaultKnownAllergies, onResult }: DiagnosisInputPanelProps) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<DiagnosisFormValues>({
    resolver: zodResolver(diagnosisFormSchema),
    defaultValues: {
      chiefComplaint: '',
      symptomsText: '',
      bp: '',
      hr: '',
      temp: '',
      spo2: '',
      weight: '',
      currentMedications: '',
      knownAllergies: defaultKnownAllergies ?? '',
      clinicalNotes: '',
    },
  });

  const diagnoseMutation = useMutation({
    mutationFn: (payload: DiagnosisInputRequest) => cdsApi.diagnose(payload),
    onSuccess: (response) => onResult(response),
    onError: (err: Error) => toast.error(err.message),
  });

  const onSubmit = (values: DiagnosisFormValues) => {
    const payload: DiagnosisInputRequest = {
      patientId,
      chiefComplaint: values.chiefComplaint,
      symptoms: values.symptomsText
        ? values.symptomsText.split(',').map((s) => s.trim()).filter(Boolean)
        : [],
      vitalSigns: {
        bp: values.bp || undefined,
        hr: values.hr || undefined,
        temp: values.temp || undefined,
        spo2: values.spo2 || undefined,
        weight: values.weight || undefined,
      },
      currentMedications: values.currentMedications || undefined,
      knownAllergies: values.knownAllergies || undefined,
      clinicalNotes: values.clinicalNotes || undefined,
    };
    diagnoseMutation.mutate(payload);
  };

  if (diagnoseMutation.isPending) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-emerald-600 animate-pulse" />
            Generating clinical decision support suggestion…
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <Skeleton className="h-4 w-3/4" />
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-5/6" />
          <Skeleton className="h-24 w-full" />
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">New Visit — Diagnosis Input</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <FormField label="Chief Complaint" required error={errors.chiefComplaint?.message}>
            <Textarea rows={2} placeholder="e.g. Fever and sore throat for 3 days" {...register('chiefComplaint')} />
          </FormField>

          <FormField label="Symptoms" hint="Comma-separated, e.g. fever, cough, fatigue">
            <Input placeholder="fever, cough, fatigue" {...register('symptomsText')} />
          </FormField>

          <div>
            <p className="text-sm font-medium mb-2">Vital Signs</p>
            <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
              <FormField label="BP"><Input placeholder="120/80" {...register('bp')} /></FormField>
              <FormField label="HR"><Input placeholder="78 bpm" {...register('hr')} /></FormField>
              <FormField label="Temp"><Input placeholder="98.6 F" {...register('temp')} /></FormField>
              <FormField label="SpO2"><Input placeholder="98%" {...register('spo2')} /></FormField>
              <FormField label="Weight"><Input placeholder="70 kg" {...register('weight')} /></FormField>
            </div>
          </div>

          <FormField label="Current Medications">
            <Textarea rows={2} placeholder="e.g. Lisinopril 10mg daily" {...register('currentMedications')} />
          </FormField>

          <FormField
            label="Known Allergies"
            hint={defaultKnownAllergies === undefined
              ? 'No structured allergy data on file for this patient — enter manually.'
              : undefined}
          >
            <Textarea rows={2} placeholder="e.g. Penicillin (rash)" {...register('knownAllergies')} />
          </FormField>

          <FormField label="Clinical Notes">
            <Textarea rows={3} placeholder="Free-text notes for this visit" {...register('clinicalNotes')} />
          </FormField>

          <div className="flex justify-end">
            <Button type="submit" className="gap-2 bg-emerald-600 hover:bg-emerald-700" disabled={diagnoseMutation.isPending}>
              <Sparkles className="w-4 h-4" />
              Generate Suggestion
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
