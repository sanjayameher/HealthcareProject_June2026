import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, User } from 'lucide-react';
import { usePatient } from '@/hooks/usePatients';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { formatPatientName, formatDate, calculateAge, formatGender } from '@/utils/formatters';
import { DiagnosisInputPanel } from './DiagnosisInputPanel';
import { CdsResponsePanel } from './CdsResponsePanel';
import { PrescriptionHistoryCard } from './PrescriptionHistoryCard';
import type { CdsResponse } from '@/types';

export function ClinicalChartPage() {
  const { patientId } = useParams<{ patientId: string }>();
  const navigate = useNavigate();
  const { data: patient, isLoading: patientLoading } = usePatient(patientId!);
  const [cdsResponse, setCdsResponse] = useState<CdsResponse | null>(null);

  return (
    <PortalPageWrapper title="Clinical Chart">
      <Button variant="ghost" size="sm" className="gap-1.5 mb-4 -ml-2" onClick={() => navigate(-1)}>
        <ArrowLeft className="w-4 h-4" /> Back
      </Button>

      <Card className="mb-6">
        <CardContent className="flex items-center gap-4 p-5">
          <div className="w-12 h-12 rounded-full bg-emerald-100 flex items-center justify-center flex-shrink-0">
            <User className="w-6 h-6 text-emerald-700" />
          </div>
          {patientLoading || !patient ? (
            <div className="space-y-2 flex-1">
              <Skeleton className="h-5 w-48" />
              <Skeleton className="h-4 w-64" />
            </div>
          ) : (
            <div>
              <p className="text-lg font-bold text-gray-900">{formatPatientName(patient.names)}</p>
              <p className="text-sm text-gray-500">
                MRN {patient.mrn ?? '—'} · {calculateAge(patient.birthDate)} · {formatGender(patient.gender)} ·
                {' '}DOB {formatDate(patient.birthDate)}
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      {!cdsResponse ? (
        <DiagnosisInputPanel patientId={patientId!} onResult={setCdsResponse} />
      ) : (
        <CdsResponsePanel patientId={patientId!} response={cdsResponse} onDiscard={() => setCdsResponse(null)} />
      )}

      <PrescriptionHistoryCard patientId={patientId!} />
    </PortalPageWrapper>
  );
}
