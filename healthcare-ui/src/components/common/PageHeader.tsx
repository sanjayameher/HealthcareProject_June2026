import { ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  backTo?: string;
  actions?: React.ReactNode;
}

export function PageHeader({ title, subtitle, backTo, actions }: PageHeaderProps) {
  const navigate = useNavigate();

  return (
    <div className="flex items-start justify-between mb-6">
      <div className="flex items-start gap-3">
        {backTo && (
          <Button
            variant="ghost"
            size="icon"
            onClick={() => navigate(backTo)}
            className="mt-0.5"
          >
            <ArrowLeft className="w-4 h-4" />
          </Button>
        )}
        <div>
          <h2 className="text-2xl font-bold text-gray-900">{title}</h2>
          {subtitle && <p className="text-sm text-gray-500 mt-1">{subtitle}</p>}
        </div>
      </div>
      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </div>
  );
}
