export interface Branch {
  id: string
  name: string
  slug: string
  address: string
  city: string
  phone: string | null
  opensAt: string
  closesAt: string
  isActive: boolean
}

export interface Doctor {
  id: string
  fullName: string
  specialization: string | null
  photoUrl: string | null
}

export interface DoctorSchedule {
  dayOfWeek: number
  branchId: string
  startTime: string
  endTime: string
  slotDurationMinutes: number
}

export interface DoctorDetail extends Doctor {
  email: string | null
  phoneWa: string | null
  isActive: boolean
  branchIds: string[] | null
  schedules: DoctorSchedule[] | null
}

export interface CreateDoctorInput {
  fullName: string
  email: string
  phoneWa: string | null
  specialization: string | null
  branchIds: string[]
  schedules: DoctorSchedule[]
}

export interface UpdateDoctorInput {
  fullName: string
  specialization: string | null
  isActive: boolean
  branchIds: string[]
  schedules: DoctorSchedule[]
}

export interface Patient {
  id: string
  fullName: string
  rmNumber: string | null
  relation: string
  gender: string | null
  dateOfBirth: string | null
  phoneWa: string | null
  email: string | null
  city: string | null
  address: string | null
  createdAt: string
}

export interface CreatePatientInput {
  fullName: string
  relation: string
  gender: string | null
  dateOfBirth: string | null
  address: string | null
  primaryAccountUserId: string | null
  email: string | null
  phoneWa: string | null
  city: string | null
}

export interface UpdatePatientInput {
  fullName: string
  relation: string
  gender: string | null
  dateOfBirth: string | null
  address: string | null
  rmNumber: string | null
}

export interface StaffUser {
  id: string
  fullName: string
  email: string | null
  phoneWa: string | null
  role: string
  isActive: boolean
  createdAt: string
}

export interface CreateUserInput {
  fullName: string
  email: string
  phoneWa: string | null
  role: string
  password: string
}

export interface UpdateUserInput {
  fullName: string
  role: string
  isActive: boolean
}

export interface Treatment {
  id: string
  name: string
  categoryName: string
  price: number
  durationMinutes: number
  isActive: boolean
}

export interface Reservation {
  id: string
  patientId: string
  branchId: string
  staffId: string
  scheduledAt: string
  status: string
  complaintNote: string | null
  patientName: string
  branchName: string
  doctorName: string
  treatments: string
}

export interface Payment {
  id: string
  reservationId: string
  patientId: string
  amount: number
  depositAmount: number
  status: string
  provider: string
  providerReference: string | null
  paymentMethod: string | null
  paidAt: string | null
  expiredAt: string | null
  createdAt: string
  patientName: string
  branchName: string
}

export interface CreatePaymentInput {
  reservationId: string
  amount: number
  depositAmount: number
  paymentMethod: string
  status: string
}

export interface InvoiceLineItem {
  name: string
  price: number
}

export interface InvoiceDetail {
  payment: Payment
  reservationId: string
  scheduledAt: string
  doctorName: string
  treatments: InvoiceLineItem[]
}

export interface CreateReservationInput {
  patientId: string
  branchId: string
  staffId: string
  scheduledAt: string
  complaintNote: string | null
  treatmentIds: string[]
  status?: string
}

export interface InventoryItem {
  id: string
  name: string
  category: string // obat, alat
  unit: string
  stockQuantity: number
  unitPrice: number
  reorderThreshold: number
  isActive: boolean
}

export interface InventoryItemInput {
  name: string
  category: string
  unit: string
  stockQuantity: number
  unitPrice: number
  reorderThreshold: number
  isActive: boolean
}

export interface OdontogramEntryInput {
  toothNumber: number
  condition: string
  notes: string | null
}

export interface ItemUsageInput {
  inventoryItemId: string
  quantity: number
  notes: string | null
}

export interface MedicalRecord {
  id: string
  patientId: string
  patientName: string
  reservationId: string | null
  staffId: string
  doctorName: string
  diagnosis: string | null
  treatmentNotes: string | null
  createdAt: string
}

export interface OdontogramEntry {
  id: string
  toothNumber: number
  condition: string
  notes: string | null
}

export interface ItemUsage {
  id: string
  inventoryItemId: string
  itemName: string
  category: string
  unit: string
  quantity: number
  notes: string | null
}

export interface MedicalRecordDetail extends MedicalRecord {
  odontogram: OdontogramEntry[] | null
  itemsUsed: ItemUsage[] | null
}

export interface CreateMedicalRecordInput {
  patientId: string
  reservationId: string | null
  staffId: string
  diagnosis: string | null
  treatmentNotes: string | null
  odontogram: OdontogramEntryInput[]
  itemsUsed: ItemUsageInput[]
}

export interface ArticleCategory {
  id: string
  name: string
}

export interface Article {
  id: string
  categoryId: string | null
  categoryName: string | null
  title: string
  slug: string
  coverImageUrl: string | null
  body: string
  publishedAt: string | null
  createdAt: string
}

export interface ArticleInput {
  categoryId: string | null
  title: string
  slug: string
  coverImageUrl: string | null
  body: string
  published: boolean
}

export interface Promo {
  id: string
  title: string
  bannerImageUrl: string | null
  description: string | null
  startsAt: string | null
  endsAt: string | null
  isActive: boolean
}

export interface PromoInput {
  title: string
  bannerImageUrl: string | null
  description: string | null
  startsAt: string | null
  endsAt: string | null
  isActive: boolean
}

export interface Testimonial {
  id: string
  patientName: string
  doctorName: string | null
  photoUrl: string | null
  rating: number
  quote: string
}

export interface TestimonialInput {
  patientName: string
  staffId: string | null
  photoUrl: string | null
  rating: number
  quote: string
}

export interface Video {
  id: string
  title: string
  videoUrl: string
  thumbnailUrl: string | null
  publishedAt: string | null
}

export interface VideoInput {
  title: string
  videoUrl: string
  thumbnailUrl: string | null
  published: boolean
}

export interface FinancialSummary {
  totalRevenue: number
  totalTransactions: number
  avgTransaction: number
  totalRefunded: number
  totalPending: number
}

export interface PaymentMethodRevenue {
  method: string
  revenue: number
  count: number
}

export interface DashboardSummary {
  reservationsToday: number
  revenueToday: number
  activeQueue: number
  attendanceRate7d: number
  totalPatients: number
  revenueThisMonth: number
}

export interface DailyRevenue {
  date: string
  revenue: number
}

export interface StatusCount {
  status: string
  count: number
}

export interface BranchRevenue {
  branchName: string
  revenue: number
  reservationCount: number
}

export interface TreatmentCount {
  treatmentName: string
  bookingCount: number
}
