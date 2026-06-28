import axios from 'axios';
import type { ApiResponse, AuditEvent } from '@/types';

const auditAxios = axios.create({
  baseURL: '/audit-svc/api/v1',
  headers: { 'Content-Type': 'application/json' },
});

auditAxios.interceptors.response.use(
  (res) => res,
  (error) => {
    const msg =
      error.response?.data?.message ||
      error.response?.data?.error ||
      error.message ||
      'An unexpected error occurred';
    return Promise.reject(new Error(msg));
  }
);

function unwrap<T>(res: { data: ApiResponse<T> }): T {
  return res.data.data;
}

export const auditApi = {
  getPatientAuditTrail: (patientId: string, params?: { from?: string; to?: string }) =>
    auditAxios
      .get<ApiResponse<AuditEvent[]>>(`/audit/patient/${patientId}`, { params })
      .then(unwrap),

  getUserAuditTrail: (userId: string, params?: { from?: string; to?: string }) =>
    auditAxios
      .get<ApiResponse<AuditEvent[]>>(`/audit/user/${userId}`, { params })
      .then(unwrap),
};
