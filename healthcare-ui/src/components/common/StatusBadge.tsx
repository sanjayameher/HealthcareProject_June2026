import { Badge } from '@/components/ui/badge';
import {
  ENCOUNTER_STATUS_COLORS,
  ENCOUNTER_STATUS_LABELS,
  COVERAGE_STATUS_COLORS,
} from '@/utils/formatters';
import type { EncounterStatus, CoverageStatus } from '@/types';
import { cn } from '@/utils/cn';

interface EncounterStatusBadgeProps {
  status: EncounterStatus;
}

export function EncounterStatusBadge({ status }: EncounterStatusBadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold',
        ENCOUNTER_STATUS_COLORS[status]
      )}
    >
      {ENCOUNTER_STATUS_LABELS[status]}
    </span>
  );
}

interface CoverageStatusBadgeProps {
  status: CoverageStatus;
}

export function CoverageStatusBadge({ status }: CoverageStatusBadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold',
        COVERAGE_STATUS_COLORS[status]
      )}
    >
      {status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  );
}

interface ActiveBadgeProps {
  active: boolean;
}

export function ActiveBadge({ active }: ActiveBadgeProps) {
  return (
    <Badge variant={active ? 'success' : 'secondary'}>
      {active ? 'Active' : 'Inactive'}
    </Badge>
  );
}

const APPOINTMENT_STATUS_COLORS: Record<string, string> = {
  booked:      'bg-blue-100 text-blue-800',
  arrived:     'bg-amber-100 text-amber-800',
  checked_in:  'bg-violet-100 text-violet-800',
  fulfilled:   'bg-emerald-100 text-emerald-800',
  cancelled:   'bg-red-100 text-red-800',
  noshow:      'bg-gray-100 text-gray-600',
  in_progress: 'bg-orange-100 text-orange-800',
  pending:     'bg-sky-100 text-sky-800',
  proposed:    'bg-slate-100 text-slate-600',
  waitlist:    'bg-yellow-100 text-yellow-800',
};

export function StatusBadge({ status }: { status: string }) {
  const colorClass = APPOINTMENT_STATUS_COLORS[status] ?? 'bg-gray-100 text-gray-600';
  return (
    <span className={cn('inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold capitalize', colorClass)}>
      {status.replace('_', ' ')}
    </span>
  );
}
