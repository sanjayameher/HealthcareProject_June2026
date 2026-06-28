// ─── Common ───────────────────────────────────────────────────────────────────

export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data: T;
  errors?: { field: string; message: string }[];
  timestamp: string;
}

export interface Page<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
}

// ─── Organization ─────────────────────────────────────────────────────────────

// Matches backend OrganizationResponse record exactly
export interface Organization {
  id: string;
  npi?: string;
  name: string;
  typeCode?: string;
  typeDisplay?: string;
  alias?: string[];
  phone?: string;
  fax?: string;
  email?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  active: boolean;
  parentId?: string;
  createdAt: string;
}

// Matches backend CreateOrganizationRequest record exactly
export interface CreateOrganizationRequest {
  parentId?: string;
  npi?: string;
  name: string;
  typeCode?: string;
  typeDisplay?: string;
  alias?: string[];
  phone?: string;
  fax?: string;
  email?: string;
  city?: string;
  state?: string;    // @Pattern [A-Z]{2}
  postalCode?: string;
}

// ─── Practitioner ─────────────────────────────────────────────────────────────

// Matches backend PractitionerResponse record exactly
export interface Practitioner {
  id: string;
  npi?: string;
  givenName: string;
  familyName: string;
  fullNameDisplay?: string;
  prefix?: string;
  suffix?: string;
  gender?: GenderType;
  birthDate?: string;
  active: boolean;
  createdAt: string;
}

// Matches backend CreatePractitionerRequest record exactly (flat — no names array)
export interface CreatePractitionerRequest {
  npi?: string;
  familyName: string;
  givenName: string;
  prefix?: string;
  suffix?: string;
  gender?: GenderType;
  birthDate?: string;
}

// ─── Patient ──────────────────────────────────────────────────────────────────

export type GenderType = 'male' | 'female' | 'other' | 'unknown';
export type NameUse = 'official' | 'usual' | 'temp' | 'nickname' | 'anonymous' | 'old' | 'maiden';
export type TelecomSystem = 'phone' | 'email' | 'fax' | 'sms' | 'url' | 'pager' | 'other';
export type TelecomUse = 'home' | 'work' | 'temp' | 'old' | 'mobile';
export type AddressUse = 'home' | 'work' | 'temp' | 'old' | 'billing';
export type AddressType = 'postal' | 'physical' | 'both';

export interface NameRequest {
  use: NameUse;
  family: string;
  given: string[];
  prefix?: string;
  suffix?: string;
}

export interface TelecomRequest {
  system: TelecomSystem;
  value: string;
  use?: TelecomUse;
  rank?: number;
}

// Matches backend AddressRequest record (line1/line2, NOT line[])
export interface AddressRequest {
  use?: AddressUse;
  type?: AddressType;
  line1: string;       // @NotBlank — required when address is included
  line2?: string;
  city: string;        // @NotBlank — required when address is included
  state?: string;      // @Pattern [A-Z]{2}
  postalCode?: string; // @Pattern \d{5}(-\d{4})?
  country?: string;
}

export interface CreatePatientRequest {
  managingOrganizationId?: string;
  gender: GenderType;
  birthDate: string;
  preferredLanguage?: string;
  names: NameRequest[];
  addresses?: AddressRequest[];
  telecoms?: TelecomRequest[];
}

// Matches backend UpdatePatientRequest record exactly (no names/addresses/telecoms)
export interface UpdatePatientRequest {
  gender: GenderType;
  birthDate: string;
  preferredLanguage?: string;
  active?: boolean;
  managingOrganizationId?: string;
  version: number;
}

// Matches backend PatientResponse.NameResponse
export interface PatientName {
  id?: string;
  use: NameUse;
  family: string;
  given: string[];
  prefix?: string[];   // String[] in backend (not String)
  suffix?: string[];   // String[] in backend (not String)
  text?: string;
}

// Matches backend PatientResponse.TelecomResponse
export interface Telecom {
  id?: string;
  system: TelecomSystem;
  value: string;
  use?: TelecomUse;
  rank?: number;
}

// Matches backend PatientResponse.AddressResponse (line1/line2 not line[])
export interface Address {
  id?: string;
  use?: AddressUse;
  type?: AddressType;
  line1?: string;
  line2?: string;
  city?: string;
  state?: string;
  postalCode?: string;
  country?: string;
}

// Matches backend PatientResponse record exactly
export interface Patient {
  id: string;
  mrn?: string;
  gender: GenderType;
  birthDate?: string;
  active: boolean;
  managingOrganizationId?: string;
  managingOrganizationName?: string;
  names?: PatientName[];
  addresses?: Address[];
  telecoms?: Telecom[];
  createdAt: string;
  updatedAt?: string;
  version: number;
}

export interface PatientFlag {
  id?: string;
  code: string;
  display?: string;
  status: string;
  severity?: string;
}

// ─── Encounter ────────────────────────────────────────────────────────────────

export type EncounterStatus =
  | 'planned'
  | 'arrived'
  | 'in_progress'
  | 'finished'
  | 'cancelled';

export type EncounterClass =
  | 'outpatient'
  | 'inpatient'
  | 'ambulatory'
  | 'emergency'
  | 'home'
  | 'virtual'
  | 'observation';

export interface CreateEncounterRequest {
  patientId: string;
  status: EncounterStatus;
  encounterClass: EncounterClass;
  typeCode?: string;
  typeDisplay?: string;
  priorityCode?: string;
  periodStart?: string;
  periodEnd?: string;
  reasonCodes?: string[];
  reasonDisplays?: string[];
  telehealthPlatform?: string;
  chiefComplaint?: string;
}

export interface Encounter {
  id: string;
  patientId: string;
  status: EncounterStatus;
  encounterClass: EncounterClass;
  typeCode?: string;
  typeDisplay?: string;
  priorityCode?: string;
  periodStart?: string;
  periodEnd?: string;
  reasonCodes?: string[];
  reasonDisplays?: string[];
  telehealthPlatform?: string;
  chiefComplaint?: string;
  createdAt: string;
  updatedAt?: string;
}

// ─── Billing ──────────────────────────────────────────────────────────────────

export interface Payer {
  id: string;
  name: string;
  type?: string;
  payerId?: string;
  phone?: string;
  email?: string;
  active: boolean;
  createdAt: string;
}

export interface CreatePayerRequest {
  name: string;
  type?: string;
  payerId?: string;
  phone?: string;
  email?: string;
  active?: boolean;
}

export type CoverageType = 'medical' | 'dental' | 'vision' | 'pharmacy' | 'other';
export type CoverageStatus = 'active' | 'cancelled' | 'draft';
export type SubscriberRelationship = 'self' | 'spouse' | 'child' | 'parent' | 'other';

export interface CreateCoverageRequest {
  patientId: string;
  payerId: string;
  planName: string;
  type: CoverageType;
  status: CoverageStatus;
  subscriberRelationship: SubscriberRelationship;
  subscriberId: string;
  subscriberIdHash: string;
  groupNumber?: string;
  periodStart: string;
  periodEnd?: string;
  orderOfBenefit: number;
}

export interface Coverage {
  id: string;
  patientId: string;
  payerId: string;
  payerName?: string;
  planName: string;
  type: CoverageType;
  status: CoverageStatus;
  subscriberRelationship: SubscriberRelationship;
  subscriberId: string;
  groupNumber?: string;
  periodStart: string;
  periodEnd?: string;
  orderOfBenefit: number;
  createdAt: string;
}

// ─── Audit ────────────────────────────────────────────────────────────────────

export interface AuditEvent {
  id: string;
  eventType: string;
  entityType?: string;
  entityId?: string;
  userId?: string;
  patientId?: string;
  action: string;
  outcome?: string;
  details?: string;
  ipAddress?: string;
  userAgent?: string;
  occurredAt: string;
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  role: 'ADMIN' | 'CLINICIAN' | 'PATIENT';
  userId: string;
  fullName: string;
  mustChangePassword: boolean;
}

// ─── Appointment (Portal) ──────────────────────────────────────────────────────

export type AppointmentStatus =
  | 'proposed' | 'pending' | 'booked' | 'arrived'
  | 'fulfilled' | 'cancelled' | 'noshow' | 'checked_in' | 'waitlist';

export interface PortalAppointment {
  id: string;
  patientId: string;
  status: AppointmentStatus;
  cancellationReason?: string;
  appointmentTypeCode?: string;
  description?: string;
  startTime: string;
  endTime: string;
  durationMinutes?: number;
  slotId?: string;
  comment?: string;
  createdAt: string;
  updatedAt?: string;
}

export interface BookAppointmentRequest {
  patientId: string;
  practitionerId: string;
  slotId: string;
  startTime: string;
  endTime: string;
  appointmentTypeCode?: string;
  description?: string;
}

// ─── Availability Slots ────────────────────────────────────────────────────────

export type SlotType = 'regular' | 'leave' | 'blocked';

export interface AvailabilitySlot {
  id: string;
  practitionerId: string;
  slotDate: string;        // ISO date YYYY-MM-DD
  startTime: string;       // HH:mm:ss
  endTime: string;
  available: boolean;
  slotType: SlotType;
  maxAppointments: number;
  notes?: string;
  createdAt: string;
}

export interface AvailabilitySlotRequest {
  slotDate: string;
  startTime: string;
  endTime: string;
  slotType?: SlotType;
  notes?: string;
  maxAppointments?: number;
}

// ─── Admin / Doctor account DTOs ──────────────────────────────────────────────

export interface CreateAdminRequest {
  fullName: string;
  email: string;
  password?: string;
}

export interface CreateDoctorAccountRequest {
  email: string;
}

export interface UpdateAppointmentStatusRequest {
  status: AppointmentStatus;
  reassignPractitionerId?: string;
}
