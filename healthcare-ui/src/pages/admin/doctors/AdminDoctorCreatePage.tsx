import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { toast } from 'sonner';
import { Search, Copy, Check } from 'lucide-react';
import { portalApi } from '@/api/portalApi';
import { PortalPageWrapper } from '@/components/layout/PortalPageWrapper';
import { PageHeader } from '@/components/common/PageHeader';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import type { Practitioner } from '@/types';

const schema = z.object({
  email: z.string().email('Must be a valid email'),
});
type FormData = z.infer<typeof schema>;

export function AdminDoctorCreatePage() {
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState<Practitioner | null>(null);
  const [inviteLink, setInviteLink] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const { data: practitioners = [] } = useQuery({
    queryKey: ['prac-search', search],
    queryFn: () => portalApi.searchDoctors(search),
    enabled: search.length > 1,
  });

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const createMutation = useMutation({
    mutationFn: ({ email }: FormData) =>
      portalApi.createDoctorAccount(selected!.id, email),
    onSuccess: (data: any) => {
      const token = data?.inviteToken ?? data?.data?.inviteToken;
      if (token) {
        const link = `${window.location.origin}/doctor/set-password?token=${token}`;
        setInviteLink(link);
      }
      toast.success('Doctor portal account created.');
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const copyLink = () => {
    if (!inviteLink) return;
    navigator.clipboard.writeText(inviteLink);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  if (inviteLink) {
    return (
      <PortalPageWrapper title="Add Doctor">
        <div className="max-w-xl">
          <Card className="border-emerald-200 bg-emerald-50">
            <CardHeader>
              <CardTitle className="text-emerald-800 text-base">
                ✓ Account Created — Share This Link
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-emerald-700">
                Send this one-time link to the doctor. They will use it to set their password and log in.
                The link expires in <strong>15 minutes</strong>.
              </p>
              <div className="flex gap-2 items-center">
                <Input
                  readOnly
                  value={inviteLink}
                  className="font-mono text-xs bg-white"
                />
                <Button size="sm" onClick={copyLink} className="shrink-0 gap-1">
                  {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                  {copied ? 'Copied' : 'Copy'}
                </Button>
              </div>
              <p className="text-xs text-emerald-600">
                Doctor login: <strong>localhost:3000/login/doctor</strong>
              </p>
              <Button onClick={() => navigate('/admin/doctors')} className="bg-violet-600 hover:bg-violet-700">
                Back to Doctors
              </Button>
            </CardContent>
          </Card>
        </div>
      </PortalPageWrapper>
    );
  }

  return (
    <PortalPageWrapper title="Add Doctor">
      <PageHeader
        title="Create Doctor Portal Account"
        subtitle="Link an existing practitioner to a portal login"
      />

      <div className="max-w-xl space-y-6">
        <Card>
          <CardHeader><CardTitle className="text-sm">Step 1 — Find Practitioner</CardTitle></CardHeader>
          <CardContent className="space-y-3">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <Input className="pl-9" placeholder="Search by name…" value={search}
                onChange={(e) => { setSearch(e.target.value); setSelected(null); }} />
            </div>
            {practitioners.length > 0 && !selected && (
              <div className="border rounded divide-y max-h-48 overflow-y-auto">
                {practitioners.map((p: Practitioner) => (
                  <button key={p.id} onClick={() => setSelected(p)}
                    className="w-full text-left px-3 py-2 hover:bg-violet-50 text-sm flex justify-between">
                    <span className="font-medium">{p.givenName} {p.familyName}</span>
                    <span className="text-gray-400 text-xs">{p.npi ?? 'No NPI'}</span>
                  </button>
                ))}
              </div>
            )}
            {selected && (
              <div className="flex items-center justify-between rounded border bg-violet-50 px-3 py-2 text-sm">
                <span className="font-medium text-violet-800">{selected.givenName} {selected.familyName}</span>
                <button className="text-xs text-gray-500 hover:text-red-500"
                  onClick={() => { setSelected(null); setSearch(''); }}>Clear</button>
              </div>
            )}
          </CardContent>
        </Card>

        {selected && (
          <Card>
            <CardHeader><CardTitle className="text-sm">Step 2 — Set Portal Email</CardTitle></CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit((d) => createMutation.mutate(d))} className="space-y-4">
                <div className="space-y-1">
                  <Label>Email Address</Label>
                  <Input type="email" placeholder="doctor@clinic.com" {...register('email')} />
                  {errors.email && <p className="text-xs text-red-500">{errors.email.message}</p>}
                  <p className="text-xs text-gray-500">
                    A one-time set-password link will be generated for you to share with the doctor.
                  </p>
                </div>
                <div className="flex gap-3">
                  <Button type="button" variant="outline" onClick={() => navigate('/admin/doctors')}>Cancel</Button>
                  <Button type="submit" disabled={createMutation.isPending} className="bg-violet-600 hover:bg-violet-700">
                    {createMutation.isPending ? 'Creating…' : 'Create Account'}
                  </Button>
                </div>
              </form>
            </CardContent>
          </Card>
        )}
      </div>
    </PortalPageWrapper>
  );
}