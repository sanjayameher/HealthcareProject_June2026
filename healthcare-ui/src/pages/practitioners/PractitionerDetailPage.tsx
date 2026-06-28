import { useParams } from 'react-router-dom';
import { UserCheck } from 'lucide-react';
import { PageWrapper } from '@/components/layout/PageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { ActiveBadge } from '@/components/common/StatusBadge';
import { usePractitioner } from '@/hooks/usePractitioners';
import { formatDate, formatGender } from '@/utils/formatters';

export function PractitionerDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data: practitioner, isLoading } = usePractitioner(id!);

  if (isLoading) {
    return (
      <PageWrapper title="Practitioner">
        <Skeleton className="h-48 w-full" />
      </PageWrapper>
    );
  }

  if (!practitioner) {
    return (
      <PageWrapper title="Practitioner">
        <p className="text-center py-12 text-gray-500">Practitioner not found.</p>
      </PageWrapper>
    );
  }

  const displayName =
    practitioner.fullNameDisplay ??
    [practitioner.prefix, practitioner.givenName, practitioner.familyName, practitioner.suffix]
      .filter(Boolean)
      .join(' ');

  return (
    <PageWrapper title="Practitioner">
      <PageHeader title={displayName} backTo="/practitioners" />

      <div className="flex items-center gap-3 mb-6">
        <ActiveBadge active={practitioner.active} />
        {practitioner.npi && (
          <span className="text-sm text-gray-400 font-mono bg-gray-50 px-2 py-1 rounded">
            NPI: {practitioner.npi}
          </span>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-semibold text-gray-500 uppercase">Personal Info</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center gap-3">
              <UserCheck className="w-4 h-4 text-gray-400" />
              <div>
                <p className="text-xs text-gray-400">Full Name</p>
                <p className="text-sm font-medium">{displayName}</p>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-y-2 text-sm">
              <span className="text-gray-500">Given Name</span>
              <span className="font-medium">{practitioner.givenName}</span>

              <span className="text-gray-500">Family Name</span>
              <span className="font-medium">{practitioner.familyName}</span>

              {practitioner.prefix && (
                <>
                  <span className="text-gray-500">Prefix</span>
                  <span className="font-medium">{practitioner.prefix}</span>
                </>
              )}

              {practitioner.suffix && (
                <>
                  <span className="text-gray-500">Suffix</span>
                  <span className="font-medium">{practitioner.suffix}</span>
                </>
              )}

              <span className="text-gray-500">Gender</span>
              <span className="font-medium">{formatGender(practitioner.gender)}</span>

              <span className="text-gray-500">Date of Birth</span>
              <span className="font-medium">{formatDate(practitioner.birthDate)}</span>

              <span className="text-gray-500">Registered</span>
              <span className="font-medium">{formatDate(practitioner.createdAt)}</span>
            </div>
          </CardContent>
        </Card>
      </div>
    </PageWrapper>
  );
}
