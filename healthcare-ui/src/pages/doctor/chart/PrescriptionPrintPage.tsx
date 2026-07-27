import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Printer, ArrowLeft, Heart } from 'lucide-react';
import { cdsApi } from '@/api/cdsApi';
import { usePatient } from '@/hooks/usePatients';
import { useAuthStore } from '@/store/authStore';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { formatPatientName, formatDateTime, calculateAge, formatGender } from '@/utils/formatters';

export function PrescriptionPrintPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuthStore();

  const { data: prescription, isLoading } = useQuery({
    queryKey: ['cds-prescription', id],
    queryFn: () => cdsApi.getPrescription(id!),
    enabled: !!id,
  });

  const { data: patient } = usePatient(prescription?.patientId ?? '');

  if (isLoading || !prescription) {
    return (
      <div className="max-w-2xl mx-auto p-8 space-y-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto p-8 bg-white min-h-screen text-gray-900">
      <div className="flex items-center justify-between mb-8 print:hidden">
        <Button variant="ghost" size="sm" className="gap-1.5" onClick={() => navigate(-1)}>
          <ArrowLeft className="w-4 h-4" /> Back
        </Button>
        <Button className="gap-1.5 bg-emerald-600 hover:bg-emerald-700" onClick={() => window.print()}>
          <Printer className="w-4 h-4" /> Print / Save as PDF
        </Button>
      </div>

      <div className="border-b-2 border-gray-800 pb-4 mb-6 flex items-center gap-3">
        <Heart className="w-8 h-8 text-emerald-600" />
        <div>
          <h1 className="text-xl font-bold">Healthcare Platform</h1>
          <p className="text-sm text-gray-500">Prescription</p>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-6 text-sm">
        <div>
          <p className="text-gray-500">Patient</p>
          <p className="font-medium">{patient ? formatPatientName(patient.names) : '—'}</p>
          {patient && (
            <p className="text-gray-500">
              MRN {patient.mrn ?? '—'} · {calculateAge(patient.birthDate)} · {formatGender(patient.gender)}
            </p>
          )}
        </div>
        <div className="text-right">
          <p className="text-gray-500">Date</p>
          <p className="font-medium">{formatDateTime(prescription.confirmedAt ?? prescription.createdAt)}</p>
          <p className="text-gray-500">Prescribing Doctor: {user?.fullName ?? '—'}</p>
        </div>
      </div>

      {prescription.diagnosisCodes && prescription.diagnosisCodes.length > 0 && (
        <div className="mb-6">
          <p className="text-sm text-gray-500 mb-1">Diagnosis</p>
          <p className="text-sm">{prescription.diagnosisCodes.join(', ')}</p>
        </div>
      )}

      <table className="w-full text-sm border-collapse mb-6">
        <thead>
          <tr className="border-b-2 border-gray-800">
            <th className="text-left py-2">Drug</th>
            <th className="text-left py-2">Dose</th>
            <th className="text-left py-2">Frequency</th>
            <th className="text-left py-2">Duration</th>
            <th className="text-left py-2">Notes</th>
          </tr>
        </thead>
        <tbody>
          {prescription.drugs.map((drug, i) => (
            <tr key={i} className="border-b border-gray-200">
              <td className="py-2 font-medium">{drug.drugName}</td>
              <td className="py-2">{drug.dose}</td>
              <td className="py-2">{drug.frequency}</td>
              <td className="py-2">{drug.duration}</td>
              <td className="py-2 text-gray-500">{drug.notes ?? '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {prescription.notes && (
        <div className="mb-10">
          <p className="text-sm text-gray-500 mb-1">Notes</p>
          <p className="text-sm">{prescription.notes}</p>
        </div>
      )}

      <div className="mt-16 pt-4 border-t border-gray-300 flex justify-between text-xs text-gray-400">
        <span>AI-assisted clinical decision support — independently reviewed and confirmed by the prescribing doctor.</span>
        <span>Rx ID: {prescription.id}</span>
      </div>
    </div>
  );
}
