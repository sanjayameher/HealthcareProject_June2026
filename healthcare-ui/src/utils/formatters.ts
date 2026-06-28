import { format, parseISO, formatDistanceToNow } from 'date-fns';
import type { PatientName, Patient, EncounterStatus, CoverageStatus } from '@/types';

export function formatDate(dateStr?: string | null, fmt = 'MMM d, yyyy'): string {
  if (!dateStr) return '—';
  try {
    return format(parseISO(dateStr), fmt);
  } catch {
    return dateStr;
  }
}

export function formatDateTime(dateStr?: string | null): string {
  return formatDate(dateStr, 'MMM d, yyyy h:mm a');
}

export function timeAgo(dateStr?: string | null): string {
  if (!dateStr) return '—';
  try {
    return formatDistanceToNow(parseISO(dateStr), { addSuffix: true });
  } catch {
    return dateStr;
  }
}

export function formatPatientName(names?: PatientName[]): string {
  if (!names || names.length === 0) return 'Unknown Patient';
  const official = names.find((n) => n.use === 'official') ?? names[0];
  const given = official.given?.join(' ') ?? '';
  return `${official.family}, ${given}`.trim().replace(/,$/, '');
}

export function getPatientDisplayName(patient: Patient): string {
  return formatPatientName(patient.names);
}

export function formatGender(gender?: string): string {
  if (!gender) return '—';
  return gender.charAt(0).toUpperCase() + gender.slice(1);
}

export function calculateAge(birthDate?: string): string {
  if (!birthDate) return '—';
  try {
    const birth = parseISO(birthDate);
    const today = new Date();
    const age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      return `${age - 1} yrs`;
    }
    return `${age} yrs`;
  } catch {
    return '—';
  }
}

export const ENCOUNTER_STATUS_COLORS: Record<EncounterStatus, string> = {
  planned: 'bg-blue-100 text-blue-700',
  arrived: 'bg-purple-100 text-purple-700',
  in_progress: 'bg-yellow-100 text-yellow-700',
  finished: 'bg-green-100 text-green-700',
  cancelled: 'bg-red-100 text-red-700',
};

export const ENCOUNTER_STATUS_LABELS: Record<EncounterStatus, string> = {
  planned: 'Planned',
  arrived: 'Arrived',
  in_progress: 'In Progress',
  finished: 'Finished',
  cancelled: 'Cancelled',
};

export const COVERAGE_STATUS_COLORS: Record<CoverageStatus, string> = {
  active: 'bg-green-100 text-green-700',
  cancelled: 'bg-red-100 text-red-700',
  draft: 'bg-gray-100 text-gray-700',
};

export function toBase64(str: string): string {
  return btoa(str);
}
