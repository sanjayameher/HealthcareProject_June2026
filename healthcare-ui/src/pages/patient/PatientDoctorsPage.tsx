import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Search, CalendarDays } from 'lucide-react';
import { portalApi } from '@/api/portalApi';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import type { Practitioner } from '@/types';

export function PatientDoctorsPage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState('');

  const { data: doctors = [], isLoading } = useQuery({
    queryKey: ['browse-doctors', search],
    queryFn: () => portalApi.browseDoctors(search || undefined),
  });

  return (
    <PortalPageWrapper title="Find a Doctor">
      <PageHeader title="Find a Doctor" subtitle="Browse available practitioners" />

      <div className="relative mb-6 max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <Input className="pl-9" placeholder="Search by name…" value={search}
          onChange={(e) => setSearch(e.target.value)} />
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="h-32 rounded-lg bg-gray-100 animate-pulse" />
          ))}
        </div>
      ) : doctors.length === 0 ? (
        <p className="text-center text-gray-500 py-12">No doctors found.</p>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {doctors.map((d: Practitioner) => (
            <Card key={d.id} className="hover:shadow-md transition-shadow">
              <CardContent className="p-5">
                <div className="flex items-start justify-between mb-3">
                  <div className="w-12 h-12 rounded-full bg-sky-100 flex items-center justify-center text-sky-700 font-bold text-lg">
                    {d.givenName?.charAt(0)}{d.familyName?.charAt(0)}
                  </div>
                </div>
                <p className="font-semibold text-gray-900">
                  {d.givenName} {d.familyName}
                </p>
                {d.npi && <p className="text-xs text-gray-500 font-mono">NPI: {d.npi}</p>}
                {d.gender && (
                  <p className="text-sm text-gray-500 capitalize mt-1">{d.gender}</p>
                )}
                <Button
                  size="sm"
                  className="mt-4 w-full gap-2 bg-sky-600 hover:bg-sky-700"
                  onClick={() => navigate('/patient/appointments', { state: { preselectedDoctorId: d.id } })}
                >
                  <CalendarDays className="w-4 h-4" /> Book Appointment
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </PortalPageWrapper>
  );
}