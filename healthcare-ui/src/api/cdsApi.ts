import axios from 'axios';
import type {
  ApiResponse,
  DiagnosisInputRequest,
  CdsResponse,
  SavePrescriptionRequest,
  Prescription,
} from '@/types';
import { useAuthStore } from '@/store/authStore';

const cdsAxios = axios.create({
  baseURL: '/cds-svc/api/v1',
  headers: { 'Content-Type': 'application/json' },
  timeout: 60000, // LLM calls can take longer than typical CRUD requests
});

// Attach JWT to every request
cdsAxios.interceptors.request.use((config) => {
  const token = useAuthStore.getState().user?.token;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

cdsAxios.interceptors.response.use(
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

export const cdsApi = {
  diagnose: (payload: DiagnosisInputRequest) =>
    cdsAxios.post<ApiResponse<CdsResponse>>('/cds/diagnose', payload).then(unwrap),

  savePrescription: (payload: SavePrescriptionRequest) =>
    cdsAxios
      .post<ApiResponse<{ prescriptionId: string }>>('/cds/prescriptions', payload)
      .then(unwrap),

  getPrescriptions: (patientId: string) =>
    cdsAxios
      .get<ApiResponse<Prescription[]>>('/cds/prescriptions', { params: { patientId } })
      .then(unwrap),

  getPrescription: (id: string) =>
    cdsAxios.get<ApiResponse<Prescription>>(`/cds/prescriptions/${id}`).then(unwrap),
};
