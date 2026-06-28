import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { toast } from 'sonner';
import { KeyRound } from 'lucide-react';
import { portalApi } from '@/api/portalApi';
import { useAuthStore } from '@/store/authStore';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

const schema = z.object({
  newPassword: z.string().min(8, 'Password must be at least 8 characters'),
  confirmPassword: z.string(),
}).refine((d) => d.newPassword === d.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword'],
});
type FormData = z.infer<typeof schema>;

interface SetPasswordPageProps {
  role: 'doctor' | 'patient';
}

export function SetPasswordPage({ role }: SetPasswordPageProps) {
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const token = params.get('token') ?? '';
  const { user } = useAuthStore();

  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const mutationFn = role === 'doctor'
    ? (d: FormData) => portalApi.setDoctorPassword(token, d.newPassword)
    : (d: FormData) => portalApi.setPatientPassword(token, d.newPassword);

  const mutation = useMutation({
    mutationFn,
    onSuccess: () => {
      toast.success('Password set successfully. Please log in.');
      navigate(role === 'doctor' ? '/login/doctor' : '/login/patient');
    },
    onError: (err: Error) => toast.error(err.message),
  });

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-50 to-gray-100 p-4">
      <Card className="w-full max-w-md shadow-lg">
        <CardHeader className="text-center pb-2">
          <div className="flex justify-center mb-3">
            <div className="w-12 h-12 bg-slate-700 rounded-xl flex items-center justify-center">
              <KeyRound className="w-6 h-6 text-white" />
            </div>
          </div>
          <CardTitle className="text-2xl">Set Your Password</CardTitle>
          {user && <p className="text-sm text-gray-500 mt-1">Welcome, {user.fullName}</p>}
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit((d) => mutation.mutate(d))} className="space-y-4">
            <div className="space-y-1">
              <Label htmlFor="newPassword">New Password</Label>
              <Input id="newPassword" type="password" placeholder="At least 8 characters" {...register('newPassword')} />
              {errors.newPassword && <p className="text-xs text-red-500">{errors.newPassword.message}</p>}
            </div>
            <div className="space-y-1">
              <Label htmlFor="confirmPassword">Confirm Password</Label>
              <Input id="confirmPassword" type="password" placeholder="Repeat password" {...register('confirmPassword')} />
              {errors.confirmPassword && <p className="text-xs text-red-500">{errors.confirmPassword.message}</p>}
            </div>
            <Button type="submit" className="w-full" disabled={mutation.isPending}>
              {mutation.isPending ? 'Saving…' : 'Set Password'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}