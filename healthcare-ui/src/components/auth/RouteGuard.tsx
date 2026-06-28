import { Navigate, Outlet, useLocation } from 'react-router-dom';
import type { UserRole } from '@/store/authStore';
import { useAuthStore } from '@/store/authStore';

interface RouteGuardProps {
  requiredRole: UserRole;
}

const roleLoginMap: Record<UserRole, string> = {
  ADMIN:     '/login/admin',
  CLINICIAN: '/login/doctor',
  PATIENT:   '/login/patient',
};

const roleHomeMap: Record<UserRole, string> = {
  ADMIN:     '/admin/dashboard',
  CLINICIAN: '/doctor/dashboard',
  PATIENT:   '/patient/dashboard',
};

export function RouteGuard({ requiredRole }: RouteGuardProps) {
  const user = useAuthStore((s) => s.user);
  const location = useLocation();

  if (!user) {
    return <Navigate to={roleLoginMap[requiredRole]} state={{ from: location }} replace />;
  }

  if (user.role !== requiredRole) {
    return <Navigate to={roleHomeMap[user.role]} replace />;
  }

  if (user.mustChangePassword) {
    const setPasswordPath =
      user.role === 'CLINICIAN' ? '/doctor/set-password' : '/patient/set-password';
    if (location.pathname !== setPasswordPath) {
      return <Navigate to={setPasswordPath} replace />;
    }
  }

  return <Outlet />;
}