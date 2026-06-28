import { Pill } from 'lucide-react';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { Card, CardContent } from '@/components/ui/card';

export function PatientPrescriptionsPage() {
  return (
    <PortalPageWrapper title="My Prescriptions">
      <PageHeader title="My Prescriptions" subtitle="Medications prescribed to you" />
      <Card>
        <CardContent className="flex flex-col items-center justify-center py-16 text-center">
          <Pill className="w-12 h-12 text-gray-300 mb-4" />
          <p className="text-gray-500 font-medium">No prescriptions on file.</p>
          <p className="text-sm text-gray-400 mt-1">
            Your prescriptions will appear here after a clinical encounter.
          </p>
        </CardContent>
      </Card>
    </PortalPageWrapper>
  );
}