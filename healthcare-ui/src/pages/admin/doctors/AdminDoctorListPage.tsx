import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { Plus, Search, Copy, Check, Link } from 'lucide-react';
import { portalApi } from '@/api/portalApi';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { DataTable } from '@/components/common/DataTable';
import { ActiveBadge } from '@/components/common/StatusBadge';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import type { Practitioner } from '@/types';

export function AdminDoctorListPage() {
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [search, setSearch] = useState('');
  const [deactivateTarget, setDeactivateTarget] = useState<Practitioner | null>(null);
  const [inviteLink, setInviteLink] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const { data: doctors = [], isLoading } = useQuery({
    queryKey: ['admin-doctors', search],
    queryFn: () => search ? portalApi.searchDoctors(search) : portalApi.listDoctors(),
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) =>
      portalApi.toggleDoctor(id, active),
    onSuccess: (_, v) => {
      toast.success(v.active ? 'Doctor activated' : 'Doctor deactivated');
      qc.invalidateQueries({ queryKey: ['admin-doctors'] });
      setDeactivateTarget(null);
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const inviteMutation = useMutation({
    mutationFn: (practitionerId: string) => portalApi.resendDoctorInvite(practitionerId),
    onSuccess: (data: any) => {
      const token = data?.inviteToken ?? data?.data?.inviteToken;
      if (token) {
        setInviteLink(`${window.location.origin}/doctor/set-password?token=${token}`);
      } else {
        toast.error('Could not generate invite link');
      }
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const copyLink = () => {
    if (!inviteLink) return;
    navigator.clipboard.writeText(inviteLink);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const columns = [
    {
      key: 'name', header: 'Name',
      render: (d: Practitioner) => (
        <span className="font-medium">{d.givenName} {d.familyName}</span>
      ),
    },
    {
      key: 'npi', header: 'NPI',
      render: (d: Practitioner) => d.npi ?? '—',
    },
    {
      key: 'gender', header: 'Gender',
      render: (d: Practitioner) => d.gender ? d.gender.charAt(0).toUpperCase() + d.gender.slice(1) : '—',
    },
    {
      key: 'status', header: 'Status',
      render: (d: Practitioner) => <ActiveBadge active={d.active} />,
    },
    {
      key: 'actions', header: '',
      render: (d: Practitioner) => (
        <div className="flex gap-2">
          <Button size="sm" variant="outline"
            onClick={(e) => { e.stopPropagation(); navigate(`/admin/doctors/${d.id}/calendar`); }}>
            Calendar
          </Button>
          <Button size="sm" variant="outline"
            onClick={(e) => { e.stopPropagation(); inviteMutation.mutate(d.id); }}
            disabled={inviteMutation.isPending}
            title="Get set-password link for this doctor">
            <Link className="w-3 h-3 mr-1" /> Get Link
          </Button>
          <Button size="sm" variant={d.active ? 'destructive' : 'default'}
            onClick={(e) => { e.stopPropagation(); d.active ? setDeactivateTarget(d) : toggleMutation.mutate({ id: d.id, active: true }); }}>
            {d.active ? 'Deactivate' : 'Activate'}
          </Button>
        </div>
      ),
    },
  ];

  return (
    <PortalPageWrapper title="Doctors">
      <PageHeader
        title="Doctor Management"
        subtitle="Manage practitioners and their portal accounts"
        actions={
          <Button onClick={() => navigate('/admin/doctors/new')} className="gap-2 bg-violet-600 hover:bg-violet-700">
            <Plus className="w-4 h-4" /> Add Doctor
          </Button>
        }
      />

      <div className="relative mb-4 max-w-sm">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <Input className="pl-9" placeholder="Search by name…" value={search}
          onChange={(e) => setSearch(e.target.value)} />
      </div>

      <DataTable
        columns={columns}
        data={doctors}
        loading={isLoading}
        keyExtractor={(d) => d.id}
        onRowClick={(d) => navigate(`/admin/doctors/${d.id}/calendar`)}
        emptyMessage="No doctors found."
      />

      {/* Invite link dialog */}
      {inviteLink && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
          onClick={() => setInviteLink(null)}>
          <div className="bg-white rounded-xl shadow-xl p-6 max-w-lg w-full mx-4"
            onClick={(e) => e.stopPropagation()}>
            <h3 className="text-base font-semibold mb-1">Doctor Set-Password Link</h3>
            <p className="text-sm text-gray-500 mb-4">
              Share this link with the doctor. It expires in <strong>15 minutes</strong>.
              They will use it to set their password, then log in at{' '}
              <span className="font-mono text-violet-600">localhost:3000/login/doctor</span>.
            </p>
            <div className="flex gap-2 mb-4">
              <Input readOnly value={inviteLink} className="font-mono text-xs" />
              <Button size="sm" onClick={copyLink} className="shrink-0 gap-1">
                {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                {copied ? 'Copied!' : 'Copy'}
              </Button>
            </div>
            <Button variant="outline" className="w-full" onClick={() => setInviteLink(null)}>
              Close
            </Button>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={!!deactivateTarget}
        title={`Deactivate ${deactivateTarget?.givenName} ${deactivateTarget?.familyName}?`}
        description="This will prevent the doctor from logging in."
        confirmLabel="Deactivate"
        onConfirm={() => deactivateTarget && toggleMutation.mutate({ id: deactivateTarget.id, active: false })}
        onCancel={() => setDeactivateTarget(null)}
      />
    </PortalPageWrapper>
  );
}