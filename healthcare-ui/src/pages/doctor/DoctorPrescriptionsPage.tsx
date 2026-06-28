import { useNavigate } from 'react-router-dom';
import { Plus, Pill } from 'lucide-react';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';

export function DoctorPrescriptionsPage() {
  const navigate = useNavigate();

  return (
    <PortalPageWrapper title="Prescriptions">
      <PageHeader
        title="Prescriptions"
        subtitle="Medications prescribed during encounters"
        actions={
          <Button onClick={() => navigate('/encounters/new')} className="gap-2 bg-emerald-600 hover:bg-emerald-700">
            <Plus className="w-4 h-4" /> New Encounter
          </Button>
        }
      />
      <Card>
        <CardContent className="flex flex-col items-center justify-center py-16 text-center">
          <Pill className="w-12 h-12 text-gray-300 mb-4" />
          <p className="text-gray-500 font-medium">Prescriptions are created during encounters.</p>
          <p className="text-sm text-gray-400 mt-1 mb-6">Start a new encounter to add medications for a patient.</p>
          <Button onClick={() => navigate('/encounters/new')} className="bg-emerald-600 hover:bg-emerald-700">
            New Encounter
          </Button>
        </CardContent>
      </Card>
    </PortalPageWrapper>
  );
}