import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from 'sonner';

// Existing pages
import { DashboardPage } from './pages/DashboardPage';
import { PatientListPage } from './pages/patients/PatientListPage';
import { PatientRegisterPage } from './pages/patients/PatientRegisterPage';
import { PatientDetailPage } from './pages/patients/PatientDetailPage';
import { PatientEditPage } from './pages/patients/PatientEditPage';
import { OrganizationListPage } from './pages/organizations/OrganizationListPage';
import { OrganizationCreatePage } from './pages/organizations/OrganizationCreatePage';
import { OrganizationDetailPage } from './pages/organizations/OrganizationDetailPage';
import { PractitionerListPage } from './pages/practitioners/PractitionerListPage';
import { PractitionerCreatePage } from './pages/practitioners/PractitionerCreatePage';
import { PractitionerDetailPage } from './pages/practitioners/PractitionerDetailPage';
import { EncounterCreatePage } from './pages/encounters/EncounterCreatePage';
import { PayerListPage } from './pages/billing/PayerListPage';
import { PayerCreatePage } from './pages/billing/PayerCreatePage';
import { CoverageCreatePage } from './pages/billing/CoverageCreatePage';
import { AuditPage } from './pages/audit/AuditPage';

// Auth pages
import { AdminLoginPage } from './pages/auth/AdminLoginPage';
import { DoctorLoginPage } from './pages/auth/DoctorLoginPage';
import { PatientLoginPage } from './pages/auth/PatientLoginPage';
import { SetPasswordPage } from './pages/auth/SetPasswordPage';

// Layouts
import { AdminLayout } from './components/layout/AdminLayout';
import { DoctorLayout } from './components/layout/DoctorLayout';
import { PatientLayout } from './components/layout/PatientLayout';

// Route guard
import { RouteGuard } from './components/auth/RouteGuard';

// Admin portal pages
import { AdminDashboard } from './pages/admin/AdminDashboard';
import { AdminQueuePage } from './pages/admin/AdminQueuePage';
import { AdminDoctorListPage } from './pages/admin/doctors/AdminDoctorListPage';
import { AdminDoctorCreatePage } from './pages/admin/doctors/AdminDoctorCreatePage';
import { AdminDoctorCalendarPage } from './pages/admin/doctors/AdminDoctorCalendarPage';
import { AdminPatientListPage } from './pages/admin/patients/AdminPatientListPage';
import { BookAppointmentPage } from './pages/admin/appointments/BookAppointmentPage';

// Doctor portal pages
import { DoctorDashboard } from './pages/doctor/DoctorDashboard';
import { DoctorQueuePage } from './pages/doctor/DoctorQueuePage';
import { DoctorCalendarPage } from './pages/doctor/DoctorCalendarPage';
import { DoctorPrescriptionsPage } from './pages/doctor/DoctorPrescriptionsPage';

// Patient portal pages
import { PatientDashboard } from './pages/patient/PatientDashboard';
import { PatientAppointmentsPage } from './pages/patient/PatientAppointmentsPage';
import { PatientDoctorsPage } from './pages/patient/PatientDoctorsPage';
import { PatientPrescriptionsPage } from './pages/patient/PatientPrescriptionsPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 30_000,
    },
  },
});

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          {/* ── Legacy / staff app ─────────────────────────────────── */}
          <Route path="/" element={<DashboardPage />} />

          <Route path="/organizations" element={<OrganizationListPage />} />
          <Route path="/organizations/new" element={<OrganizationCreatePage />} />
          <Route path="/organizations/:id" element={<OrganizationDetailPage />} />

          <Route path="/practitioners" element={<PractitionerListPage />} />
          <Route path="/practitioners/new" element={<PractitionerCreatePage />} />
          <Route path="/practitioners/:id" element={<PractitionerDetailPage />} />

          <Route path="/patients" element={<PatientListPage />} />
          <Route path="/patients/new" element={<PatientRegisterPage />} />
          <Route path="/patients/:id" element={<PatientDetailPage />} />
          <Route path="/patients/:id/edit" element={<PatientEditPage />} />

          <Route path="/encounters/new" element={<EncounterCreatePage />} />

          <Route path="/billing/payers" element={<PayerListPage />} />
          <Route path="/billing/payers/new" element={<PayerCreatePage />} />
          <Route path="/billing/coverage/new" element={<CoverageCreatePage />} />

          <Route path="/audit" element={<AuditPage />} />

          {/* ── Auth (public) ───────────────────────────────────────── */}
          <Route path="/login/admin"   element={<AdminLoginPage />} />
          <Route path="/login/doctor"  element={<DoctorLoginPage />} />
          <Route path="/login/patient" element={<PatientLoginPage />} />
          <Route path="/doctor/set-password"  element={<SetPasswordPage role="doctor" />} />
          <Route path="/patient/set-password" element={<SetPasswordPage role="patient" />} />

          {/* ── Admin portal ────────────────────────────────────────── */}
          <Route element={<RouteGuard requiredRole="ADMIN" />}>
            <Route element={<AdminLayout />}>
              <Route path="/admin/dashboard"               element={<AdminDashboard />} />
              <Route path="/admin/doctors"                 element={<AdminDoctorListPage />} />
              <Route path="/admin/doctors/new"             element={<AdminDoctorCreatePage />} />
              <Route path="/admin/doctors/:id/calendar"    element={<AdminDoctorCalendarPage />} />
              <Route path="/admin/patients"                element={<AdminPatientListPage />} />
              <Route path="/admin/appointments/new"        element={<BookAppointmentPage />} />
              <Route path="/admin/queue"                   element={<AdminQueuePage />} />
            </Route>
          </Route>

          {/* ── Doctor portal ───────────────────────────────────────── */}
          <Route element={<RouteGuard requiredRole="CLINICIAN" />}>
            <Route element={<DoctorLayout />}>
              <Route path="/doctor/dashboard"      element={<DoctorDashboard />} />
              <Route path="/doctor/queue"          element={<DoctorQueuePage />} />
              <Route path="/doctor/calendar"       element={<DoctorCalendarPage />} />
              <Route path="/doctor/prescriptions"  element={<DoctorPrescriptionsPage />} />
            </Route>
          </Route>

          {/* ── Patient portal ──────────────────────────────────────── */}
          <Route element={<RouteGuard requiredRole="PATIENT" />}>
            <Route element={<PatientLayout />}>
              <Route path="/patient/dashboard"        element={<PatientDashboard />} />
              <Route path="/patient/appointments"     element={<PatientAppointmentsPage />} />
              <Route path="/patient/doctors"          element={<PatientDoctorsPage />} />
              <Route path="/patient/prescriptions"    element={<PatientPrescriptionsPage />} />
            </Route>
          </Route>
        </Routes>
      </BrowserRouter>
      <Toaster richColors position="top-right" />
    </QueryClientProvider>
  );
}