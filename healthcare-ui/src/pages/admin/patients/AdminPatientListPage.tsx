import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { toast } from 'sonner';
import { UserPlus, Copy, Check, Link } from 'lucide-react';
import { portalApi } from '@/api/portalApi';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { DataTable } from '@/components/common/DataTable';
import { ActiveBadge } from '@/components/common/StatusBadge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';

type PatientRow = { id: string; mrn: string; gender: string; birthDate: string; active: boolean };

const emailSchema = z.object({ email: z.string().email() });

export function AdminPatientListPage() {
  const qc = useQueryClient();
  const [activateTarget, setActivateTarget] = useState<PatientRow | null>(null);
  const [accountTarget, setAccountTarget] = useState<PatientRow | null>(null);
  const [inviteLink, setInviteLink] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const { data: patients = [], isLoading } = useQuery<PatientRow[]>({
    queryKey: ['admin-patients'],
    queryFn: () => portalApi.listPatientsAdmin(),
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) =>
      portalApi.togglePatient(id, active),
    onSuccess: () => {
      toast.success('Updated');
      qc.invalidateQueries({ queryKey: ['admin-patients'] });
      setActivateTarget(null);
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const { register, handleSubmit, reset, formState: { errors } } = useForm({ resolver: zodResolver(emailSchema) });

  const createAccountMutation = useMutation({
    mutationFn: ({ email }: { email: string }) =>
      portalApi.createPatientAccount(accountTarget!.id, email),
    onSuccess: (data: any) => {
      qc.invalidateQueries({ queryKey: ['admin-patients'] });
      setAccountTarget(null);
      reset();
      const token = data?.inviteToken ?? data?.data?.inviteToken;
      if (token) {
        setInviteLink(`${window.location.origin}/patient/set-password?token=${token}`);
      } else {
        toast.success('Patient portal account created');
      }
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const inviteMutation = useMutation({
    mutationFn: (patientId: string) => portalApi.resendPatientInvite(patientId),
    onSuccess: (data: any) => {
      const token = data?.inviteToken ?? data?.data?.inviteToken;
      if (token) {
        setInviteLink(`${window.location.origin}/patient/set-password?token=${token}`);
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
    { key: 'mrn', header: 'MRN', render: (p: PatientRow) => <span className="font-mono text-sm">{p.mrn}</span> },
    { key: 'dob', header: 'DOB', render: (p: PatientRow) => p.birthDate ?? '—' },
    { key: 'gender', header: 'Gender', render: (p: PatientRow) => p.gender ? p.gender.charAt(0).toUpperCase() + p.gender.slice(1) : '—' },
    { key: 'status', header: 'Status', render: (p: PatientRow) => <ActiveBadge active={p.active} /> },
    {
      key: 'actions', header: '',
      render: (p: PatientRow) => (
        <div className="flex gap-2">
          <Button size="sm" variant="outline" onClick={(e) => { e.stopPropagation(); setAccountTarget(p); }}
            title="Create portal account">
            <UserPlus className="w-3 h-3 mr-1" /> Portal
          </Button>
          <Button size="sm" variant="outline"
            onClick={(e) => { e.stopPropagation(); inviteMutation.mutate(p.id); }}
            disabled={inviteMutation.isPending}
            title="Get set-password link for this patient">
            <Link className="w-3 h-3 mr-1" /> Get Link
          </Button>
          <Button size="sm" variant={p.active ? 'destructive' : 'default'}
            onClick={(e) => { e.stopPropagation(); setActivateTarget(p); }}>
            {p.active ? 'Deactivate' : 'Activate'}
          </Button>
        </div>
      ),
    },
  ];

  return (
    <PortalPageWrapper title="Patients">
      <PageHeader title="Patient Management" subtitle="Manage patient portal access" />
      <DataTable
        columns={columns}
        data={patients}
        loading={isLoading}
        keyExtractor={(p) => p.id}
        emptyMessage="No patients found."
      />

      <ConfirmDialog
        open={!!activateTarget}
        onOpenChange={(o) => !o && setActivateTarget(null)}
        title={`${activateTarget?.active ? 'Deactivate' : 'Activate'} patient ${activateTarget?.mrn}?`}
        description={activateTarget?.active ? 'This will block the patient from logging in.' : 'This will restore patient portal access.'}
        confirmLabel={activateTarget?.active ? 'Deactivate' : 'Activate'}
        onConfirm={() => activateTarget && toggleMutation.mutate({ id: activateTarget.id, active: !activateTarget.active })}
      />

      {/* Create portal account dialog */}
      <Dialog open={!!accountTarget} onOpenChange={(o) => !o && setAccountTarget(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Create Portal Account — {accountTarget?.mrn}</DialogTitle></DialogHeader>
          <form onSubmit={handleSubmit((d) => createAccountMutation.mutate({ email: d.email }))} className="space-y-4">
            <div className="space-y-1">
              <Label>Patient Email</Label>
              <Input type="email" placeholder="patient@email.com" {...register('email')} />
              {errors.email && <p className="text-xs text-red-500">Valid email required</p>}
            </div>
            <div className="flex justify-end gap-2">
              <Button type="button" variant="outline" onClick={() => setAccountTarget(null)}>Cancel</Button>
              <Button type="submit" disabled={createAccountMutation.isPending}>
                {createAccountMutation.isPending ? 'Creating…' : 'Create Account'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Invite link dialog */}
      {inviteLink && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
          onClick={() => setInviteLink(null)}>
          <div className="bg-white rounded-xl shadow-xl p-6 max-w-lg w-full mx-4"
            onClick={(e) => e.stopPropagation()}>
            <h3 className="text-base font-semibold mb-1">Patient Set-Password Link</h3>
            <p className="text-sm text-gray-500 mb-4">
              Share this link with the patient. It expires in <strong>15 minutes</strong>.
              They will use it to set their password, then log in at{' '}
              <span className="font-mono text-sky-600">localhost:3000/login/patient</span>.
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
    </PortalPageWrapper>
  );
}