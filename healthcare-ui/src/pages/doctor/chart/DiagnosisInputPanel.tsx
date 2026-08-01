import { useRef, useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { toast } from 'sonner';
import { Sparkles, Mic, Loader2, Paperclip, FileText, X } from 'lucide-react';
import { cdsApi } from '@/api/cdsApi';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { FormField } from '@/components/common/FormField';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useSpeechToText } from '@/hooks/useSpeechToText';
import { useLlmProvider } from '@/hooks/useLlmProvider';
import { cn } from '@/utils/cn';
import type { CdsResponse, DiagnosisInputRequest, TestReportAttachment } from '@/types';

const ALLOWED_ATTACHMENT_TYPES = ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
const MAX_ATTACHMENT_BYTES = 8 * 1024 * 1024;

function readFileAsBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve((reader.result as string).split(',')[1] ?? '');
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
}

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
    setValue,
    getValues,
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

  const { provider, setProvider } = useLlmProvider();

  const rawTranscriptRef = useRef('');
  const [interimText, setInterimText] = useState('');

  const fileInputRef = useRef<HTMLInputElement>(null);
  const [attachment, setAttachment] = useState<TestReportAttachment | null>(null);
  const [attachmentError, setAttachmentError] = useState<string | null>(null);
  const attachmentUnreadableByProvider =
    attachment !== null && provider === 'groq' && attachment.mimeType !== 'application/pdf';

  const handleFileSelected = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file) return;
    setAttachmentError(null);
    if (!ALLOWED_ATTACHMENT_TYPES.includes(file.type)) {
      setAttachmentError('Unsupported file type — attach a PDF or an image (JPG, PNG, GIF, WEBP).');
      return;
    }
    if (file.size > MAX_ATTACHMENT_BYTES) {
      setAttachmentError('File is too large — the limit is 8 MB.');
      return;
    }
    try {
      const base64Data = await readFileAsBase64(file);
      setAttachment({ filename: file.name, mimeType: file.type, base64Data });
    } catch {
      setAttachmentError('Could not read the selected file.');
    }
  };

  const removeAttachment = () => {
    setAttachment(null);
    setAttachmentError(null);
  };

  const summarizeMutation = useMutation({
    mutationFn: (transcript: string) => cdsApi.summarizeTranscript({ transcript, provider }),
    onSuccess: (response) => {
      const gist = response.chiefComplaint.trim();
      if (!gist) return;
      const current = getValues('chiefComplaint').trim();
      const next = current ? `${current} ${gist}` : gist;
      setValue('chiefComplaint', next, { shouldValidate: true, shouldDirty: true });
    },
    onError: (err: Error) => toast.error(`Could not summarize the conversation: ${err.message}`),
  });

  const { isListening, isSupported, toggleListening } = useSpeechToText({
    onTranscript: (transcript, isFinal) => {
      if (isFinal) {
        rawTranscriptRef.current = `${rawTranscriptRef.current} ${transcript}`.replace(/\s+/g, ' ').trim();
        setInterimText('');
      } else {
        setInterimText(transcript);
      }
    },
  });

  const handleMicClick = () => {
    if (isListening) {
      toggleListening();
      setInterimText('');
      const transcript = rawTranscriptRef.current.trim();
      rawTranscriptRef.current = '';
      if (transcript) {
        summarizeMutation.mutate(transcript);
      }
    } else {
      rawTranscriptRef.current = '';
      setInterimText('');
      toggleListening();
    }
  };

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
      provider,
      testReportAttachment: attachment ?? undefined,
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
        <div className="flex items-center justify-between gap-3">
          <CardTitle className="text-base">New Visit — Diagnosis Input</CardTitle>
          <div className="flex items-center gap-2">
            <span className="text-xs text-muted-foreground whitespace-nowrap">AI Provider</span>
            <Select value={provider} onValueChange={(value) => setProvider(value as typeof provider)}>
              <SelectTrigger className="h-8 w-[130px] text-xs">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="groq">Groq (free)</SelectItem>
                <SelectItem value="claude">Claude</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <FormField label="Chief Complaint" required error={errors.chiefComplaint?.message}>
            <div className="relative">
              <Textarea
                rows={2}
                placeholder="e.g. Fever and sore throat for 3 days"
                className={isSupported ? 'pr-12' : undefined}
                {...register('chiefComplaint')}
              />
              {isSupported && (
                <Button
                  type="button"
                  variant="ghost"
                  size="icon"
                  disabled={summarizeMutation.isPending}
                  className={cn(
                    'absolute right-1.5 top-1.5 h-8 w-8 rounded-full',
                    isListening && 'bg-red-100 text-red-600 hover:bg-red-100 hover:text-red-600'
                  )}
                  onClick={handleMicClick}
                  title={isListening ? 'Stop and summarize' : 'Capture chief complaint by voice'}
                  aria-label={isListening ? 'Stop and summarize' : 'Capture chief complaint by voice'}
                >
                  {summarizeMutation.isPending ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : (
                    <Mic className={cn('w-4 h-4', isListening && 'animate-pulse')} />
                  )}
                </Button>
              )}
            </div>
            {isListening && (
              <div className="mt-1 space-y-1">
                <p className="text-xs text-emerald-600 flex items-center gap-1.5">
                  <span className="relative flex h-2 w-2">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
                    <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500" />
                  </span>
                  Listening — click the mic again when the conversation is done
                </p>
                {interimText && (
                  <p className="text-xs text-muted-foreground italic truncate">Hearing: "{interimText}"</p>
                )}
              </div>
            )}
            {summarizeMutation.isPending && (
              <p className="text-xs text-emerald-600 flex items-center gap-1.5 mt-1">
                <Loader2 className="w-3 h-3 animate-spin" />
                Summarizing the conversation into a chief complaint…
              </p>
            )}
          </FormField>

          <FormField label="Symptoms & Test Report" hint="Comma-separated symptoms, e.g. fever, cough, fatigue">
            <Input placeholder="fever, cough, fatigue" {...register('symptomsText')} />
            <div className="mt-2 flex flex-wrap items-center gap-2">
              <input
                ref={fileInputRef}
                type="file"
                accept="application/pdf,image/jpeg,image/png,image/gif,image/webp"
                className="hidden"
                onChange={handleFileSelected}
              />
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="h-8 gap-1.5 text-xs"
                onClick={() => fileInputRef.current?.click()}
              >
                <Paperclip className="w-3.5 h-3.5" />
                Attach test report
              </Button>
              {attachment && (
                <span className="flex items-center gap-1.5 rounded-md bg-muted px-2 py-1 text-xs">
                  <FileText className="w-3.5 h-3.5" />
                  <span className="max-w-[180px] truncate">{attachment.filename}</span>
                  <button
                    type="button"
                    onClick={removeAttachment}
                    className="text-muted-foreground hover:text-foreground"
                    aria-label="Remove attached test report"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                </span>
              )}
            </div>
            {attachmentError && <p className="mt-1 text-xs text-destructive">{attachmentError}</p>}
            {attachmentUnreadableByProvider && (
              <p className="mt-1 text-xs text-amber-600">
                Groq can't read images — switch the AI Provider above to Claude to have this report analyzed
                visually, or the suggestion will be based on symptoms only.
              </p>
            )}
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
