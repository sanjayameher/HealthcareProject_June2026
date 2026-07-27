import { useQuery } from '@tanstack/react-query';
import { Pill, Download } from 'lucide-react';
import { cdsApi } from '@/api/cdsApi';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { formatDateTime } from '@/utils/formatters';

interface PrescriptionHistoryCardProps {
  patientId: string;
}

export function PrescriptionHistoryCard({ patientId }: PrescriptionHistoryCardProps) {
  const { data: prescriptions, isLoading } = useQuery({
    queryKey: ['cds-prescriptions', patientId],
    queryFn: () => cdsApi.getPrescriptions(patientId),
    enabled: !!patientId,
  });

  return (
    <Card className="mt-6">
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2">
          <Pill className="w-4 h-4" /> Prescription History
        </CardTitle>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="space-y-2">
            <Skeleton className="h-16 w-full" />
            <Skeleton className="h-16 w-full" />
          </div>
        ) : !prescriptions || prescriptions.length === 0 ? (
          <p className="text-sm text-gray-500">No prescriptions on record for this patient yet.</p>
        ) : (
          <div className="space-y-3">
            {prescriptions.map((rx) => (
              <div key={rx.id} className="rounded-md border p-3">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs text-gray-500">
                    {formatDateTime(rx.confirmedAt ?? rx.createdAt)}
                  </span>
                  <div className="flex items-center gap-2">
                    {rx.diagnosisCodes && rx.diagnosisCodes.length > 0 && (
                      <div className="flex gap-1">
                        {rx.diagnosisCodes.map((code) => (
                          <Badge key={code} variant="outline">{code}</Badge>
                        ))}
                      </div>
                    )}
                    <Button
                      variant="ghost"
                      size="sm"
                      className="gap-1.5 h-7"
                      onClick={() => window.open(`/doctor/prescriptions/${rx.id}/print`, '_blank')}
                    >
                      <Download className="w-3.5 h-3.5" /> Download
                    </Button>
                  </div>
                </div>
                <div className="space-y-1">
                  {rx.drugs.map((drug, i) => (
                    <p key={i} className="text-sm">
                      <span className="font-medium">{drug.drugName}</span>
                      {' '}— {drug.dose} · {drug.frequency} · {drug.duration}
                    </p>
                  ))}
                </div>
                {rx.notes && <p className="text-xs text-gray-500 mt-2">{rx.notes}</p>}
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
