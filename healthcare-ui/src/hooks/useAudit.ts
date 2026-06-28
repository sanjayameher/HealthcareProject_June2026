import { useQuery } from '@tanstack/react-query';
import { auditApi } from '@/api/auditApi';

export function usePatientAuditTrail(
  patientId: string,
  params?: { from?: string; to?: string }
) {
  return useQuery({
    queryKey: ['audit', 'patient', patientId, params],
    queryFn: () => auditApi.getPatientAuditTrail(patientId, params),
    enabled: !!patientId,
  });
}

export function useUserAuditTrail(
  userId: string,
  params?: { from?: string; to?: string }
) {
  return useQuery({
    queryKey: ['audit', 'user', userId, params],
    queryFn: () => auditApi.getUserAuditTrail(userId, params),
    enabled: !!userId,
  });
}
