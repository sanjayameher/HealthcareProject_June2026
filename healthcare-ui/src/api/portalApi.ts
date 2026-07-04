import axios from 'axios';
import type {
  ApiResponse,
  Page,
  LoginRequest,
  LoginResponse,
  PortalAppointment,
  BookAppointmentRequest,
  AvailabilitySlot,
  AvailabilitySlotRequest,
  CreateAdminRequest,
  UpdateAppointmentStatusRequest,
  Practitioner,
} from '@/types';
import { useAuthStore } from '@/store/authStore';

const portalAxios = axios.create({
  baseURL: '/portal-svc/api/v1',
  headers: { 'Content-Type': 'application/json' },
});

// Attach JWT to every request
portalAxios.interceptors.request.use((config) => {
  const token = useAuthStore.getState().user?.token;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

portalAxios.interceptors.response.use(
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

export const portalApi = {
  // ── Auth ────────────────────────────────────────────────────────────────────
  adminLogin: (data: LoginRequest) =>
    portalAxios.post<ApiResponse<LoginResponse>>('/auth/admin/login', data).then(unwrap),

  doctorLogin: (data: LoginRequest) =>
    portalAxios.post<ApiResponse<LoginResponse>>('/auth/doctor/login', data).then(unwrap),

  patientLogin: (data: LoginRequest) =>
    portalAxios.post<ApiResponse<LoginResponse>>('/auth/patient/login', data).then(unwrap),

  setDoctorPassword: (token: string, newPassword: string) =>
    portalAxios.post<ApiResponse<void>>('/auth/doctor/set-password', { token, newPassword }).then(unwrap),

  setPatientPassword: (token: string, newPassword: string) =>
    portalAxios.post<ApiResponse<void>>('/auth/patient/set-password', { token, newPassword }).then(unwrap),

  // ── Admin: Dashboard stats ───────────────────────────────────────────────────
  getAdminStats: () =>
    portalAxios
      .get<ApiResponse<{ patients: number; doctors: number; upcoming: number }>>('/admin/stats')
      .then(unwrap),

  // ── Admin: Doctor management ─────────────────────────────────────────────────
  listDoctors: (active?: boolean) =>
    portalAxios
      .get<ApiResponse<Page<Practitioner>>>('/admin/doctors', { params: { active } })
      .then((r) => r.data.data.content),

  searchDoctors: (q: string) =>
    portalAxios
      .get<ApiResponse<Page<Practitioner>>>('/admin/doctors/search', { params: { q } })
      .then((r) => r.data.data.content),

  createDoctorAccount: (practitionerId: string, email: string) =>
    portalAxios
      .post<ApiResponse<unknown>>(`/admin/doctors/${practitionerId}/account`, null, { params: { email } })
      .then(unwrap),

  resendDoctorInvite: (practitionerId: string) =>
    portalAxios
      .post<ApiResponse<unknown>>(`/admin/doctors/${practitionerId}/resend-invite`)
      .then(unwrap),

  toggleDoctor: (practitionerId: string, active: boolean, reason?: string) =>
    portalAxios
      .patch<ApiResponse<void>>(`/admin/doctors/${practitionerId}/toggle`, null, {
        params: { active, reason },
      })
      .then(unwrap),

  // ── Admin: Patient management ────────────────────────────────────────────────
  listPatientsAdmin: (active?: boolean) =>
    portalAxios
      .get<ApiResponse<Page<{ id: string; mrn: string; gender: string; birthDate: string; active: boolean }>>>(
        '/admin/patients',
        { params: { active } }
      )
      .then((r) => r.data.data.content),

  createPatientAccount: (patientId: string, email: string) =>
    portalAxios
      .post<ApiResponse<unknown>>(`/admin/patients/${patientId}/account`, null, { params: { email } })
      .then(unwrap),

  resendPatientInvite: (patientId: string) =>
    portalAxios
      .post<ApiResponse<unknown>>(`/admin/patients/${patientId}/resend-invite`)
      .then(unwrap),

  togglePatient: (patientId: string, active: boolean, reason?: string) =>
    portalAxios
      .patch<ApiResponse<void>>(`/admin/patients/${patientId}/toggle`, null, {
        params: { active, reason },
      })
      .then(unwrap),

  // ── Admin: Appointments & queue ──────────────────────────────────────────────
  bookAppointmentAdmin: (data: BookAppointmentRequest) =>
    portalAxios.post<ApiResponse<PortalAppointment>>('/admin/appointments', data).then(unwrap),

  getAdminQueue: () =>
    portalAxios.get<ApiResponse<PortalAppointment[]>>('/admin/queue').then(unwrap),

  updateAppointmentStatus: (id: string, data: UpdateAppointmentStatusRequest) =>
    portalAxios.patch<ApiResponse<PortalAppointment>>(`/admin/appointments/${id}/status`, data).then(unwrap),

  cancelAppointmentAdmin: (id: string) =>
    portalAxios.delete<ApiResponse<PortalAppointment>>(`/admin/appointments/${id}`).then(unwrap),

  // ── Availability slots ───────────────────────────────────────────────────────
  getMonthSlots: (practitionerId: string, year: number, month: number) =>
    portalAxios
      .get<ApiResponse<AvailabilitySlot[]>>(`/availability/practitioners/${practitionerId}/month`, {
        params: { year, month },
      })
      .then(unwrap),

  getAvailableSlots: (practitionerId: string, date: string) =>
    portalAxios
      .get<ApiResponse<AvailabilitySlot[]>>(`/availability/practitioners/${practitionerId}/available`, {
        params: { date },
      })
      .then(unwrap),

  addSlot: (practitionerId: string, data: AvailabilitySlotRequest) =>
    portalAxios
      .post<ApiResponse<AvailabilitySlot>>(`/availability/practitioners/${practitionerId}/slots`, data)
      .then(unwrap),

  blockSlot: (slotId: string, slotType: string, notes?: string) =>
    portalAxios
      .patch<ApiResponse<AvailabilitySlot>>(`/availability/slots/${slotId}/block`, null, {
        params: { slotType, notes },
      })
      .then(unwrap),

  deleteSlot: (slotId: string) =>
    portalAxios.delete<ApiResponse<void>>(`/availability/slots/${slotId}`).then(unwrap),

  // ── Doctor portal ────────────────────────────────────────────────────────────
  getDoctorQueue: (practitionerId: string) =>
    portalAxios.get<ApiResponse<PortalAppointment[]>>(`/doctor/${practitionerId}/queue`).then(unwrap),

  getDoctorUpcoming: (practitionerId: string) =>
    portalAxios
      .get<ApiResponse<PortalAppointment[]>>(`/doctor/${practitionerId}/appointments/upcoming`)
      .then(unwrap),

  bookAppointmentDoctor: (practitionerId: string, data: BookAppointmentRequest) =>
    portalAxios
      .post<ApiResponse<PortalAppointment>>(`/doctor/${practitionerId}/appointments`, data)
      .then(unwrap),

  updateAppointmentStatusDoctor: (id: string, status: string) =>
    portalAxios
      .patch<ApiResponse<PortalAppointment>>(`/doctor/appointments/${id}/status`, { status })
      .then(unwrap),

  // ── Patient portal ───────────────────────────────────────────────────────────
  getPatientAppointments: (patientId: string) =>
    portalAxios
      .get<ApiResponse<Page<PortalAppointment>>>(`/patient/${patientId}/appointments`)
      .then((r) => r.data.data.content),

  getPatientUpcoming: (patientId: string) =>
    portalAxios
      .get<ApiResponse<PortalAppointment[]>>(`/patient/${patientId}/appointments/upcoming`)
      .then(unwrap),

  bookAppointmentPatient: (patientId: string, data: BookAppointmentRequest) =>
    portalAxios
      .post<ApiResponse<PortalAppointment>>(`/patient/${patientId}/appointments`, data)
      .then(unwrap),

  cancelAppointmentPatient: (id: string) =>
    portalAxios.delete<ApiResponse<PortalAppointment>>(`/patient/appointments/${id}`).then(unwrap),

  browseDoctors: (q?: string) =>
    portalAxios
      .get<ApiResponse<Page<Practitioner>>>('/patient/doctors', { params: { q } })
      .then((r) => r.data.data.content),

  getDoctorAvailability: (practitionerId: string, date: string) =>
    portalAxios
      .get<ApiResponse<AvailabilitySlot[]>>(`/patient/doctors/${practitionerId}/availability`, {
        params: { date },
      })
      .then(unwrap),
};