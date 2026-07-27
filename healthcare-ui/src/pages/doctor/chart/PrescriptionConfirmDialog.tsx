import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { cdsApi } from '@/api/cdsApi';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import type { SavePrescriptionRequest, SuggestedDrug } from '@/types';

interface PrescriptionConfirmDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  patientId: string;
  sessionId: string;
  diagnosisCodes: string[];
  drugs: SuggestedDrug[];
  accepted: boolean;
  onSaved: () => void;
}

export function PrescriptionConfirmDialog({
  open,
  onOpenChange,
  patientId,
  sessionId,
  diagnosisCodes,
  drugs,
  accepted,
  onSaved,
}: PrescriptionConfirmDialogProps) {
  const [confirmed, setConfirmed] = useState(false);
  const [notes, setNotes] = useState('');
  const queryClient = useQueryClient();

  const saveMutation = useMutation({
    mutationFn: (payload: SavePrescriptionRequest) => cdsApi.savePrescription(payload),
    onSuccess: () => {
      toast.success('Prescription saved to patient record');
      queryClient.invalidateQueries({ queryKey: ['cds-prescriptions', patientId] });
      setConfirmed(false);
      setNotes('');
      onSaved();
    },
    onError: (err: Error) => toast.error(err.message),
  });

  const handleConfirm = () => {
    saveMutation.mutate({
      sessionId,
      patientId,
      diagnosisCodes,
      drugs,
      notes: notes || undefined,
      accepted,
    });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Confirm Prescription</DialogTitle>
          <DialogDescription>
            Review the final prescription before it is saved to the patient record.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3 max-h-64 overflow-y-auto">
          {drugs.map((drug, i) => (
            <div key={i} className="rounded-md border p-3 text-sm">
              <p className="font-medium">{drug.drugName}</p>
              <p className="text-gray-500">
                {drug.dose} · {drug.frequency} · {drug.duration}
              </p>
              {drug.notes && <p className="text-xs text-gray-400 mt-1">{drug.notes}</p>}
            </div>
          ))}
        </div>

        <div className="space-y-1.5">
          <Label className="text-sm font-medium">Additional notes (optional)</Label>
          <Textarea rows={2} value={notes} onChange={(e) => setNotes(e.target.value)} />
        </div>

        <div className="flex items-start gap-2 rounded-md bg-amber-50 border border-amber-200 p-3">
          <Checkbox id="confirm-rx" checked={confirmed} onCheckedChange={(c) => setConfirmed(c === true)} className="mt-0.5" />
          <Label htmlFor="confirm-rx" className="text-sm text-amber-900 font-normal leading-snug">
            I confirm this prescription. AI-generated suggestions are decision support only —
            I have independently reviewed them against the patient's clinical picture.
          </Label>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={saveMutation.isPending}>
            Cancel
          </Button>
          <Button
            onClick={handleConfirm}
            disabled={!confirmed || saveMutation.isPending}
            className="bg-emerald-600 hover:bg-emerald-700"
          >
            {saveMutation.isPending ? 'Saving…' : 'Save Prescription'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
