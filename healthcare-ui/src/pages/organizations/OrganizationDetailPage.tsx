import { useParams } from 'react-router-dom';
import { Building2, Phone, Mail, MapPin, Printer } from 'lucide-react';
import { PageWrapper } from '@/components/layout/PageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { ActiveBadge } from '@/components/common/StatusBadge';
import { useOrganization } from '@/hooks/useOrganizations';
import { formatDate } from '@/utils/formatters';

export function OrganizationDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data: org, isLoading } = useOrganization(id!);

  if (isLoading) {
    return (
      <PageWrapper title="Organization">
        <Skeleton className="h-48 w-full" />
      </PageWrapper>
    );
  }

  if (!org) {
    return (
      <PageWrapper title="Organization">
        <p className="text-center py-12 text-gray-500">Organization not found.</p>
      </PageWrapper>
    );
  }

  const location = [org.city, org.state, org.postalCode].filter(Boolean).join(', ');

  return (
    <PageWrapper title="Organization">
      <PageHeader title={org.name} backTo="/organizations" />

      <div className="flex items-center gap-3 mb-6">
        <ActiveBadge active={org.active} />
        {(org.typeDisplay || org.typeCode) && (
          <span className="text-sm text-gray-500 bg-gray-100 px-2 py-1 rounded">
            {org.typeDisplay ?? org.typeCode}
          </span>
        )}
        {org.npi && (
          <span className="text-sm text-gray-400 font-mono">NPI: {org.npi}</span>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-semibold text-gray-500 uppercase">Contact</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center gap-3">
              <Building2 className="w-4 h-4 text-gray-400" />
              <div>
                <p className="text-xs text-gray-400">Name</p>
                <p className="text-sm font-medium">{org.name}</p>
              </div>
            </div>
            {org.phone && (
              <div className="flex items-center gap-3">
                <Phone className="w-4 h-4 text-gray-400" />
                <div>
                  <p className="text-xs text-gray-400">Phone</p>
                  <p className="text-sm font-medium">{org.phone}</p>
                </div>
              </div>
            )}
            {org.fax && (
              <div className="flex items-center gap-3">
                <Printer className="w-4 h-4 text-gray-400" />
                <div>
                  <p className="text-xs text-gray-400">Fax</p>
                  <p className="text-sm font-medium">{org.fax}</p>
                </div>
              </div>
            )}
            {org.email && (
              <div className="flex items-center gap-3">
                <Mail className="w-4 h-4 text-gray-400" />
                <div>
                  <p className="text-xs text-gray-400">Email</p>
                  <p className="text-sm font-medium">{org.email}</p>
                </div>
              </div>
            )}
            {location && (
              <div className="flex items-center gap-3">
                <MapPin className="w-4 h-4 text-gray-400" />
                <div>
                  <p className="text-xs text-gray-400">Location</p>
                  <p className="text-sm font-medium">{location}</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-semibold text-gray-500 uppercase">Metadata</CardTitle>
          </CardHeader>
          <CardContent className="grid grid-cols-2 gap-y-3">
            <span className="text-sm text-gray-500">Created</span>
            <span className="text-sm font-medium">{formatDate(org.createdAt)}</span>
            {org.parentId && (
              <>
                <span className="text-sm text-gray-500">Parent Org ID</span>
                <span className="text-sm font-mono text-gray-600 truncate">{org.parentId}</span>
              </>
            )}
          </CardContent>
        </Card>
      </div>
    </PageWrapper>
  );
}
