import axios from 'axios';
import type { ApiResponse, CreateEncounterRequest, Encounter } from '@/types';

const clinicalAxios = axios.create({
  baseURL: '/clinical-svc/api/v1',
  headers: { 'Content-Type': 'application/json' },
});

clinicalAxios.interceptors.response.use(
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

export const clinicalApi = {
  createEncounter: (data: CreateEncounterRequest) =>
    clinicalAxios.post<ApiResponse<Encounter>>('/encounters', data).then(unwrap),

  getEncounter: (id: string) =>
    clinicalAxios.get<ApiResponse<Encounter>>(`/encounters/${id}`).then(unwrap),

  getPatientEncounters: (patientId: string) =>
    clinicalAxios
      .get<ApiResponse<Encounter[]>>(`/encounters/patient/${patientId}`)
      .then(unwrap),
};
