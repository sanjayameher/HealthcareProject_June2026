import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export type UserRole = 'ADMIN' | 'CLINICIAN' | 'PATIENT';

export interface AuthUser {
  token: string;
  role: UserRole;
  userId: string;
  fullName: string;
  mustChangePassword: boolean;
}

interface AuthStore {
  user: AuthUser | null;
  login: (user: AuthUser) => void;
  logout: () => void;
  isAuthenticated: () => boolean;
  hasRole: (role: UserRole) => boolean;
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set, get) => ({
      user: null,

      login: (user) => set({ user }),

      logout: () => set({ user: null }),

      isAuthenticated: () => get().user !== null,

      hasRole: (role) => get().user?.role === role,
    }),
    {
      name: 'healthcare-auth',
      partialize: (s) => ({ user: s.user }),
    }
  )
);