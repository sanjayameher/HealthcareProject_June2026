import axios from 'axios';
import type {
  ApiResponse,
  Page,
  CreatePatientRequest,
  UpdatePatientRequest,
  Patient,
  CreateOrganizationRequest,
  Organization,
  CreatePractitionerRequest,
  Practitioner,
} from '@/types';

const patientAxios = axios.create({
  baseURL: '/patient-svc/api/v1',
  headers: { 'Content-Type': 'application/json' },
});

patientAxios.interceptors.response.use(
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

export const patientApi = {
  // ── Patients ────────────────────────────────────────────────────────────────
  createPatient: (data: CreatePatientRequest) =>
    patientAxios.post<ApiResponse<Patient>>('/patients', data).then(unwrap),

  getPatient: (id: string) =>
    patientAxios.get<ApiResponse<Patient>>(`/patients/${id}`).then(unwrap),

  getPatientByMrn: (mrn: string) =>
    patientAxios.get<ApiResponse<Patient>>(`/patients/by-mrn/${mrn}`).then(unwrap),

  updatePatient: (id: string, data: UpdatePatientRequest) =>
    patientAxios.put<ApiResponse<Patient>>(`/patients/${id}`, data).then(unwrap),

  deletePatient: (id: string) =>
    patientAxios.delete<ApiResponse<void>>(`/patients/${id}`).then(unwrap),

  // Backend only has /patients/search (Page<Patient>) — no list-all endpoint
  searchPatients: (params: { name?: string; mrn?: string }) =>
    patientAxios
      .get<ApiResponse<Page<Patient>>>('/patients/search', { params })
      .then((res) => res.data.data.content),

  listPatients: () =>
    patientAxios
      .get<ApiResponse<Page<Patient>>>('/patients/search')
      .then((res) => res.data.data.content),

  // ── Organizations ───────────────────────────────────────────────────────────
  createOrganization: (data: CreateOrganizationRequest) =>
    patientAxios.post<ApiResponse<Organization>>('/organizations', data).then(unwrap),

  listOrganizations: () =>
    patientAxios
      .get<ApiResponse<Page<Organization>>>('/organizations')
      .then((res) => res.data.data.content),

  getOrganization: (id: string) =>
    patientAxios.get<ApiResponse<Organization>>(`/organizations/${id}`).then(unwrap),

  // ── Practitioners ───────────────────────────────────────────────────────────
  createPractitioner: (data: CreatePractitionerRequest) =>
    patientAxios.post<ApiResponse<Practitioner>>('/practitioners', data).then(unwrap),

  listPractitioners: () =>
    patientAxios
      .get<ApiResponse<Page<Practitioner>>>('/practitioners')
      .then((res) => res.data.data.content),

  getPractitioner: (id: string) =>
    patientAxios.get<ApiResponse<Practitioner>>(`/practitioners/${id}`).then(unwrap),
};
