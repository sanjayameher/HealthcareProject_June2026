import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, CalendarDays, Pill,
  LogOut, Heart, ChevronLeft, ChevronRight,
} from 'lucide-react';
import { cn } from '@/utils/cn';
import { useUIStore } from '@/store/uiStore';
import { useAuthStore } from '@/store/authStore';

const navItems = [
  { to: '/patient/dashboard',      icon: LayoutDashboard, label: 'My Health',     end: true },
  { to: '/patient/appointments',   icon: CalendarDays,    label: 'Appointments' },
  { to: '/patient/prescriptions',  icon: Pill,            label: 'Prescriptions' },
];

export function PatientLayout() {
  const { sidebarOpen, toggleSidebar } = useUIStore();
  const { user, logout } = useAuthStore();
  const navigate = useNavigate();

  const handleLogout = () => { logout(); navigate('/patient/login'); };

  return (
    <div className="flex h-screen bg-gray-50">
      <aside className={cn(
        'fixed left-0 top-0 z-40 h-screen bg-slate-900 text-white transition-all duration-300 flex flex-col',
        sidebarOpen ? 'w-64' : 'w-16'
      )}>
        <div className="flex items-center gap-3 px-4 py-5 border-b border-slate-700">
          <div className="flex items-center justify-center w-8 h-8 bg-sky-600 rounded-lg flex-shrink-0">
            <Heart className="w-4 h-4 text-white" />
          </div>
          {sidebarOpen && (
            <div className="overflow-hidden">
              <p className="text-sm font-bold text-white leading-tight">Patient Portal</p>
              <p className="text-xs text-slate-400 truncate">{user?.fullName}</p>
            </div>
          )}
        </div>

        <nav className="flex-1 py-4 overflow-y-auto">
          {navItems.map(({ to, icon: Icon, label, end }) => (
            <NavLink key={to} to={to} end={end}
              className={({ isActive }) => cn(
                'flex items-center gap-3 px-4 py-3 mx-2 rounded-lg text-sm transition-colors',
                isActive ? 'bg-sky-600 text-white' : 'text-slate-300 hover:bg-slate-800 hover:text-white'
              )}>
              <Icon className="w-5 h-5 flex-shrink-0" />
              {sidebarOpen && <span className="truncate">{label}</span>}
            </NavLink>
          ))}
        </nav>

        <button onClick={handleLogout}
          className="flex items-center gap-3 px-4 py-3 mx-2 mb-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors text-sm">
          <LogOut className="w-5 h-5 flex-shrink-0" />
          {sidebarOpen && <span>Sign out</span>}
        </button>

        <button onClick={toggleSidebar}
          className="flex items-center justify-center w-full py-3 border-t border-slate-700 text-slate-400 hover:text-white hover:bg-slate-800 transition-colors">
          {sidebarOpen ? <ChevronLeft className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />}
        </button>
      </aside>

      <main className={cn('flex-1 transition-all duration-300 overflow-auto', sidebarOpen ? 'ml-64' : 'ml-16')}>
        <Outlet />
      </main>
    </div>
  );
}