import { Sidebar } from './Sidebar';
import { Header } from './Header';
import { useUIStore } from '@/store/uiStore';
import { cn } from '@/utils/cn';
import { useEffect } from 'react';
import { toast } from 'sonner';

interface PageWrapperProps {
  title: string;
  children: React.ReactNode;
}

const SESSION_WARN_MS = 14 * 60 * 1000;
const SESSION_TIMEOUT_MS = 15 * 60 * 1000;

export function PageWrapper({ title, children }: PageWrapperProps) {
  const { sidebarOpen, updateActivity, lastActivity } = useUIStore();

  useEffect(() => {
    const events = ['mousedown', 'keydown', 'scroll', 'touchstart'];
    events.forEach((e) => window.addEventListener(e, updateActivity));
    return () => events.forEach((e) => window.removeEventListener(e, updateActivity));
  }, [updateActivity]);

  useEffect(() => {
    const interval = setInterval(() => {
      const idle = Date.now() - lastActivity;
      if (idle >= SESSION_TIMEOUT_MS) {
        toast.error('Session expired due to inactivity.');
      } else if (idle >= SESSION_WARN_MS) {
        toast.warning('Your session will expire in 1 minute due to inactivity.');
      }
    }, 30_000);
    return () => clearInterval(interval);
  }, [lastActivity]);

  return (
    <div className="flex h-screen bg-gray-50 overflow-hidden">
      <Sidebar />
      <div
        className={cn(
          'flex flex-col flex-1 overflow-hidden transition-all duration-300',
          sidebarOpen ? 'ml-64' : 'ml-16'
        )}
      >
        <Header title={title} />
        <main className="flex-1 overflow-y-auto p-6">{children}</main>
      </div>
    </div>
  );
}
