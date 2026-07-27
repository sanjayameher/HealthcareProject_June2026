import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { toast } from 'sonner';
import { UserPlus, Copy, Check, RefreshCw, Shield, ShieldCheck } from 'lucide-react';
import { format } from 'date-fns';
import { portalApi } from '@/api/portalApi';
import { useAuthStore } from '@/store/authStore';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { DataTable } from '@/components/common/DataTable';
import { ActiveBadge } from '@/components/common/StatusBadge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { ConfirmDialog } from '@/components/common/ConfirmDialog';
import type { AdminAccountInfo } from '@/types';

const createSchema = z.object({
  fullName: z.string().min(2, 'Full name is required'),
  email: z.string().refine((v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v), 'Valid email required'),
});
type CreateForm = z.infer<typeof createSchema>;

export function AdminAccountsPage() {
  const qc = useQueryClient();
  const { user } = useAuthStore();

  const [showCreate, setShowCreate] = useState(false);
  const [toggleTarget, setToggleTarget] = useState<AdminAccountInfo | null>(null);
  const [inviteLink, setInviteLink] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const { data: admins = [], isLoading } = useQuery<AdminAccountInfo[]>({
    queryKey: ['admin-accounts'],
    queryFn: portalApi.listAdmins,
  });

  const { register, handleSubmit, reset, formState: { errors } } = useForm<CreateForm>({
    resolver: zodResolver(createSchema),
  });

  const createMutation = useMutation({
    mutationFn: (data: CreateForm) => portalApi.createAdmin(data),
    onSuccess: (data) => {
      qc.invalidateQueries({ queryKey: ['admin-accounts'] });
      setShowCreate(false);
      reset();
      if (data?.inviteToken) {
        setInviteLink(`${window.location.origin}/admin/set-password?token=${data.inviteToken}`);
      } else {
        toast.success('Admin account created');
      }
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const toggleMutation = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) =>
      portalApi.toggleAdmin(id, active),
    onSuccess: (_, { active }) => {
      toast.success(active ? 'Admin activated' : 'Admin deactivated');
      qc.invalidateQueries({ queryKey: ['admin-accounts'] });
      setToggleTarget(null);
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const resendMutation = useMutation({
    mutationFn: (id: string) => portalApi.resendAdminInvite(id),
    onSuccess: (data) => {
      if (data?.inviteToken) {
        setInviteLink(`${window.location.origin}/admin/set-password?token=${data.inviteToken}`);
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
      render: (a: AdminAccountInfo) => (
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-violet-100 flex items-center justify-center flex-shrink-0">
            <span className="text-xs font-semibold text-violet-700">
              {a.fullName.split(' ').map((n) => n[0]).join('').slice(0, 2).toUpperCase()}
            </span>
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <span className="font-medium text-sm">{a.fullName}</span>
              {a.superAdmin && (
                <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded text-xs font-medium bg-amber-100 text-amber-700">
                  <ShieldCheck className="w-3 h-3" /> Super Admin
                </span>
              )}
              {a.id === user?.userId && (
                <span className="px-1.5 py-0.5 rounded text-xs font-medium bg-violet-100 text-violet-700">You</span>
              )}
            </div>
            <p className="text-xs text-gray-500">{a.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: 'status', header: 'Status',
      render: (a: AdminAccountInfo) => (
        <div className="flex flex-col gap-1">
          <ActiveBadge active={a.active} />
          {a.mustChangePassword && (
            <span className="text-xs text-amber-600 font-medium">Password not set</span>
          )}
          {a.lockedUntil && new Date(a.lockedUntil) > new Date() && (
            <span className="text-xs text-red-500 font-medium">Locked</span>
          )}
        </div>
      ),
    },
    {
      key: 'lastLogin', header: 'Last Login',
      render: (a: AdminAccountInfo) =>
        a.lastLoginAt ? format(new Date(a.lastLoginAt), 'dd MMM yyyy HH:mm') : <span className="text-gray-400 text-sm">Never</span>,
    },
    {
      key: 'created', header: 'Created',
      render: (a: AdminAccountInfo) => format(new Date(a.createdAt), 'dd MMM yyyy'),
    },
    {
      key: 'actions', header: '',
      render: (a: AdminAccountInfo) => (
        <div className="flex gap-2 justify-end">
          <Button size="sm" variant="outline"
            onClick={(e) => { e.stopPropagation(); resendMutation.mutate(a.id); }}
            disabled={resendMutation.isPending}
            title="Get new set-password link">
            <RefreshCw className="w-3 h-3 mr-1" /> Invite Link
          </Button>
          {a.id !== user?.userId && !a.superAdmin && (
            <Button size="sm"
              variant={a.active ? 'destructive' : 'default'}
              onClick={(e) => { e.stopPropagation(); setToggleTarget(a); }}>
              {a.active ? 'Deactivate' : 'Activate'}
            </Button>
          )}
        </div>
      ),
    },
  ];

  return (
    <PortalPageWrapper title="Admin Accounts">
      <PageHeader
        title="Admin Management"
        subtitle="Onboard and manage administrator accounts"
        actions={
          user?.superAdmin ? (
            <Button onClick={() => setShowCreate(true)} className="gap-2 bg-violet-600 hover:bg-violet-700">
              <UserPlus className="w-4 h-4" /> Onboard Admin
            </Button>
          ) : (
            <Button disabled className="gap-2" title="Only Super Admins can onboard new admins">
              <UserPlus className="w-4 h-4" /> Onboard Admin
            </Button>
          )
        }
      />

      <div className="mb-4 p-3 bg-amber-50 border border-amber-200 rounded-lg flex items-start gap-2 text-sm text-amber-800">
        <Shield className="w-4 h-4 mt-0.5 flex-shrink-0" />
        <span>
          Only <strong>Super Admins</strong> can onboard new admins. New admins receive a set-password link
          to complete their account setup. You cannot deactivate Super Admins or your own account.
        </span>
      </div>

      <DataTable
        columns={columns}
        data={admins}
        loading={isLoading}
        keyExtractor={(a) => a.id}
        emptyMessage="No admin accounts found."
      />

      {/* Create admin dialog */}
      <Dialog open={showCreate} onOpenChange={(o) => { if (!o) { setShowCreate(false); reset(); } }}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <UserPlus className="w-5 h-5 text-violet-600" /> Onboard New Admin
            </DialogTitle>
          </DialogHeader>
          <form onSubmit={handleSubmit((d) => createMutation.mutate(d))} className="space-y-4 pt-2">
            <div className="space-y-1">
              <Label htmlFor="fullName">Full Name</Label>
              <Input id="fullName" placeholder="e.g. Sarah Johnson" {...register('fullName')} />
              {errors.fullName && <p className="text-xs text-red-500">{errors.fullName.message}</p>}
            </div>
            <div className="space-y-1">
              <Label htmlFor="email">Work Email</Label>
              <Input id="email" type="email" placeholder="admin@hospital.com" {...register('email')} />
              {errors.email && <p className="text-xs text-red-500">{errors.email.message}</p>}
            </div>
            <p className="text-xs text-gray-500">
              A set-password link will be generated after creation. Share it with the new admin so they
              can set their own password. The link expires in <strong>15 minutes</strong>.
            </p>
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="outline" onClick={() => { setShowCreate(false); reset(); }}>
                Cancel
              </Button>
              <Button type="submit" className="bg-violet-600 hover:bg-violet-700" disabled={createMutation.isPending}>
                {createMutation.isPending ? 'Creating…' : 'Create & Get Link'}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>

      {/* Toggle confirmation */}
      <ConfirmDialog
        open={!!toggleTarget}
        onOpenChange={(o) => !o && setToggleTarget(null)}
        title={`${toggleTarget?.active ? 'Deactivate' : 'Activate'} ${toggleTarget?.fullName}?`}
        description={
          toggleTarget?.active
            ? 'This admin will no longer be able to log in to the portal.'
            : 'This will restore the admin\'s login access.'
        }
        confirmLabel={toggleTarget?.active ? 'Deactivate' : 'Activate'}
        onConfirm={() =>
          toggleTarget && toggleMutation.mutate({ id: toggleTarget.id, active: !toggleTarget.active })
        }
      />

      {/* Invite link dialog */}
      {inviteLink && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
          onClick={() => setInviteLink(null)}>
          <div className="bg-white rounded-xl shadow-xl p-6 max-w-lg w-full mx-4"
            onClick={(e) => e.stopPropagation()}>
            <h3 className="text-base font-semibold mb-1">Admin Set-Password Link</h3>
            <p className="text-sm text-gray-500 mb-4">
              Share this link with the admin. It expires in <strong>15 minutes</strong>.
              They will use it to set their password and log in at{' '}
              <span className="font-mono text-violet-600">localhost:5001/login/admin</span>.
            </p>
            <div className="flex gap-2 mb-4">
              <Input readOnly value={inviteLink} className="font-mono text-xs" />
              <Button size="sm" onClick={copyLink} className="shrink-0 gap-1 bg-violet-600 hover:bg-violet-700">
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