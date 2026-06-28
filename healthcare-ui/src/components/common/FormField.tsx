import { Label } from '@/components/ui/label';
import { cn } from '@/utils/cn';

interface FormFieldProps {
  label: string;
  required?: boolean;
  error?: string;
  children: React.ReactNode;
  className?: string;
  hint?: string;
}

export function FormField({ label, required, error, children, className, hint }: FormFieldProps) {
  return (
    <div className={cn('space-y-1.5', className)}>
      <Label className={cn('text-sm font-medium', error && 'text-destructive')}>
        {label}
        {required && <span className="text-destructive ml-1">*</span>}
      </Label>
      {children}
      {hint && !error && <p className="text-xs text-muted-foreground">{hint}</p>}
      {error && <p className="text-xs text-destructive">{error}</p>}
    </div>
  );
}
