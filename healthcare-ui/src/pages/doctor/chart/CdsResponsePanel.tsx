import { useState } from 'react';
import { AlertTriangle, ChevronDown, ChevronUp, Pencil, Trash2, Plus, Check, X } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Separator } from '@/components/ui/separator';
import { PrescriptionConfirmDialog } from './PrescriptionConfirmDialog';
import type { CdsResponse, SuggestedDrug } from '@/types';

interface CdsResponsePanelProps {
  patientId: string;
  response: CdsResponse;
  onDiscard: () => void;
}

const EMPTY_DRUG: SuggestedDrug = { drugName: '', dose: '', frequency: '', duration: '', notes: '' };

export function CdsResponsePanel({ patientId, response, onDiscard }: CdsResponsePanelProps) {
  const [sourcesOpen, setSourcesOpen] = useState(false);
  const [editing, setEditing] = useState(false);
  const [editedDrugs, setEditedDrugs] = useState<SuggestedDrug[]>(response.suggestedPrescription);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [confirmAccepted, setConfirmAccepted] = useState(true);

  const diagnosisCodes = response.differentialDiagnoses.map((d) => d.icd10Code).filter(Boolean);

  const startEditing = () => {
    setEditedDrugs(response.suggestedPrescription.length > 0 ? response.suggestedPrescription : [EMPTY_DRUG]);
    setEditing(true);
  };

  const updateDrug = (index: number, field: keyof SuggestedDrug, value: string) => {
    setEditedDrugs((prev) => prev.map((d, i) => (i === index ? { ...d, [field]: value } : d)));
  };

  const removeDrug = (index: number) => {
    setEditedDrugs((prev) => prev.filter((_, i) => i !== index));
  };

  const addDrug = () => setEditedDrugs((prev) => [...prev, { ...EMPTY_DRUG }]);

  const openAccept = () => {
    setConfirmAccepted(true);
    setConfirmOpen(true);
  };

  const openSaveEdited = () => {
    setConfirmAccepted(false);
    setConfirmOpen(true);
  };

  const drugsForConfirm = editing ? editedDrugs.filter((d) => d.drugName.trim()) : response.suggestedPrescription;

  return (
    <div className="space-y-4">
      {response.disclaimer && (
        <div className="flex items-start gap-2 rounded-md bg-amber-50 border border-amber-200 p-3 text-sm text-amber-900">
          <AlertTriangle className="w-4 h-4 flex-shrink-0 mt-0.5" />
          <span>{response.disclaimer}</span>
        </div>
      )}

      <div className="flex items-start gap-2 rounded-md bg-blue-50 border border-blue-200 p-3 text-sm text-blue-900">
        <AlertTriangle className="w-4 h-4 flex-shrink-0 mt-0.5" />
        <span>
          This is AI-generated clinical decision support, not a diagnosis. Independently verify every
          suggestion against the patient's full clinical picture before prescribing.
        </span>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Differential Diagnoses</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {response.differentialDiagnoses.length === 0 ? (
            <p className="text-sm text-gray-500">No differential diagnoses returned.</p>
          ) : (
            response.differentialDiagnoses.map((dx, i) => (
              <div key={i} className="flex items-start justify-between gap-3 rounded-md border p-3">
                <div>
                  <p className="font-medium text-sm">
                    {dx.display} <span className="text-gray-400 font-normal">({dx.icd10Code})</span>
                  </p>
                  {dx.rationale && <p className="text-xs text-gray-500 mt-1">{dx.rationale}</p>}
                </div>
                <Badge variant={dx.confidencePct >= 70 ? 'success' : dx.confidencePct >= 40 ? 'warning' : 'secondary'}>
                  {dx.confidencePct}%
                </Badge>
              </div>
            ))
          )}
        </CardContent>
      </Card>

      {response.redFlags.length > 0 && (
        <Card className="border-red-200">
          <CardHeader>
            <CardTitle className="text-base text-red-700 flex items-center gap-2">
              <AlertTriangle className="w-4 h-4" /> Red Flags
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ul className="list-disc list-inside space-y-1 text-sm text-red-700">
              {response.redFlags.map((flag, i) => (
                <li key={i}>{flag}</li>
              ))}
            </ul>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="text-base">Suggested Prescription</CardTitle>
          {!editing && (
            <Button variant="outline" size="sm" className="gap-1.5" onClick={startEditing}>
              <Pencil className="w-3.5 h-3.5" /> Edit Before Saving
            </Button>
          )}
        </CardHeader>
        <CardContent>
          {!editing ? (
            response.suggestedPrescription.length === 0 ? (
              <p className="text-sm text-gray-500">No prescription suggested.</p>
            ) : (
              <div className="overflow-x-auto rounded-lg border border-gray-200">
                <table className="min-w-full divide-y divide-gray-200 text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      {['Drug', 'Dose', 'Frequency', 'Duration', 'Notes'].map((h) => (
                        <th key={h} className="px-4 py-2 text-left text-xs font-semibold text-gray-500 uppercase">{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-100">
                    {response.suggestedPrescription.map((drug, i) => (
                      <tr key={i}>
                        <td className="px-4 py-2 font-medium">{drug.drugName}</td>
                        <td className="px-4 py-2">{drug.dose}</td>
                        <td className="px-4 py-2">{drug.frequency}</td>
                        <td className="px-4 py-2">{drug.duration}</td>
                        <td className="px-4 py-2 text-gray-500">{drug.notes || '—'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )
          ) : (
            <div className="space-y-3">
              {editedDrugs.map((drug, i) => (
                <div key={i} className="grid grid-cols-1 sm:grid-cols-5 gap-2 items-start rounded-md border p-3">
                  <Input placeholder="Drug name" value={drug.drugName} onChange={(e) => updateDrug(i, 'drugName', e.target.value)} />
                  <Input placeholder="Dose" value={drug.dose} onChange={(e) => updateDrug(i, 'dose', e.target.value)} />
                  <Input placeholder="Frequency" value={drug.frequency} onChange={(e) => updateDrug(i, 'frequency', e.target.value)} />
                  <Input placeholder="Duration" value={drug.duration} onChange={(e) => updateDrug(i, 'duration', e.target.value)} />
                  <div className="flex gap-2">
                    <Input placeholder="Notes" value={drug.notes ?? ''} onChange={(e) => updateDrug(i, 'notes', e.target.value)} />
                    <Button variant="ghost" size="icon" onClick={() => removeDrug(i)} className="flex-shrink-0">
                      <Trash2 className="w-4 h-4 text-red-500" />
                    </Button>
                  </div>
                </div>
              ))}
              <div className="flex items-center justify-between">
                <Button variant="outline" size="sm" className="gap-1.5" onClick={addDrug}>
                  <Plus className="w-3.5 h-3.5" /> Add Drug
                </Button>
                <div className="flex gap-2">
                  <Button variant="ghost" size="sm" onClick={() => setEditing(false)}>
                    <X className="w-3.5 h-3.5 mr-1.5" /> Cancel
                  </Button>
                  <Button
                    size="sm"
                    className="bg-emerald-600 hover:bg-emerald-700"
                    disabled={editedDrugs.every((d) => !d.drugName.trim())}
                    onClick={openSaveEdited}
                  >
                    <Check className="w-3.5 h-3.5 mr-1.5" /> Review & Save
                  </Button>
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="cursor-pointer" onClick={() => setSourcesOpen((o) => !o)}>
          <CardTitle className="text-base flex items-center justify-between">
            <span>RAG Sources Used ({response.sourceChunks.length})</span>
            {sourcesOpen ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
          </CardTitle>
        </CardHeader>
        {sourcesOpen && (
          <CardContent className="space-y-3">
            {response.sourceChunks.length === 0 ? (
              <p className="text-sm text-gray-500">No knowledge chunks matched this query.</p>
            ) : (
              response.sourceChunks.map((chunk) => (
                <div key={chunk.id} className="rounded-md border p-3 text-sm">
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-medium text-xs text-gray-500 uppercase">{chunk.sourceType}</span>
                    <Badge variant="outline">{(chunk.similarity * 100).toFixed(0)}% match</Badge>
                  </div>
                  {chunk.sourceRef && <p className="font-medium text-sm mb-1">{chunk.sourceRef}</p>}
                  <p className="text-gray-600">{chunk.content}</p>
                </div>
              ))
            )}
          </CardContent>
        )}
      </Card>

      <Separator />

      <div className="flex flex-wrap justify-end gap-2">
        <Button variant="outline" onClick={onDiscard}>
          Discard
        </Button>
        {!editing && (
          <Button
            className="gap-2 bg-emerald-600 hover:bg-emerald-700"
            disabled={response.suggestedPrescription.length === 0}
            onClick={openAccept}
          >
            <Check className="w-4 h-4" /> Accept &amp; Save Prescription
          </Button>
        )}
      </div>

      <PrescriptionConfirmDialog
        open={confirmOpen}
        onOpenChange={setConfirmOpen}
        patientId={patientId}
        sessionId={response.sessionId}
        diagnosisCodes={diagnosisCodes}
        drugs={drugsForConfirm}
        accepted={confirmAccepted}
        onSaved={() => {
          setConfirmOpen(false);
          onDiscard();
        }}
      />
    </div>
  );
}
