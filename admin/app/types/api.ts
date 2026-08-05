export interface PaginatedResponse<T> {
  data: T[]
  page: number
  pageSize: number
  total: number
  totalPages: number
}

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

export interface StaffSkill {
  id: string
  skillName: string
  proficiency: number
  yearsExperience: number | null
}

export interface StaffSkillInput {
  skillName: string
  proficiency: number
  yearsExperience: number | null
}

export interface DoctorDetail extends Doctor {
  email: string | null
  phoneWa: string | null
  bio: string | null
  commissionRate: number
  isActive: boolean
  branchIds: string[] | null
  schedules: DoctorSchedule[] | null
  skills: StaffSkill[] | null
}

export interface CreateDoctorInput {
  fullName: string
  email: string
  phoneWa: string | null
  specialization: string | null
  bio: string | null
  photoUrl: string | null
  commissionRate: number
  branchIds: string[]
  schedules: DoctorSchedule[]
  skills: StaffSkillInput[]
}

export interface UpdateDoctorInput {
  fullName: string
  specialization: string | null
  bio: string | null
  photoUrl: string | null
  commissionRate: number
  isActive: boolean
  branchIds: string[]
  schedules: DoctorSchedule[]
  skills: StaffSkillInput[]
}

export interface DailyRevenuePair {
  period: string
  revenue: number
}

export interface TreatmentCountPair {
  treatmentName: string
  count: number
}

export interface DoctorStats {
  totalRevenue: number
  commissionEarned: number
  reservationsCount: number
  patientsServed: number
  monthlyRevenue: DailyRevenuePair[] | null
  topTreatments: TreatmentCountPair[] | null
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
  photoUrl: string | null
  nik?: string | null
  bloodType?: string | null
  occupation?: string | null
  emergencyContactName?: string | null
  emergencyContactPhone?: string | null
  allergiesMedicalHistory?: string | null
  insuranceType?: string | null
  insuranceNumber?: string | null
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
  photoUrl: string | null
  nik?: string | null
  bloodType?: string | null
  occupation?: string | null
  emergencyContactName?: string | null
  emergencyContactPhone?: string | null
  allergiesMedicalHistory?: string | null
  insuranceType?: string | null
  insuranceNumber?: string | null
}

export interface UpdatePatientInput {
  fullName: string
  relation: string
  gender: string | null
  dateOfBirth: string | null
  address: string | null
  rmNumber: string | null
  photoUrl: string | null
  nik?: string | null
  bloodType?: string | null
  occupation?: string | null
  emergencyContactName?: string | null
  emergencyContactPhone?: string | null
  allergiesMedicalHistory?: string | null
  insuranceType?: string | null
  insuranceNumber?: string | null
}

export interface MonthlySpendingRow {
  period: string
  amount: number
}

export interface PatientStats {
  loyaltyPoints: number
  totalSpent: number
  visitsCount: number
  monthlySpending: MonthlySpendingRow[] | null
}

export interface PatientOdontogramTimeline {
  medicalRecordId: string
  createdAt: string
  odontogram: OdontogramEntry[] | null
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

export interface AuthUser {
  id: string
  fullName: string
  email: string
  phoneWa: string | null
  role: string
}

export interface UpdateOwnProfileInput {
  fullName: string
  phoneWa: string | null
}

export interface ChangePasswordInput {
  currentPassword: string
  newPassword: string
}

export interface TreatmentCategory {
  id: string
  name: string
  sortOrder: number
}

export interface Treatment {
  id: string
  categoryId: string
  name: string
  categoryName: string
  description: string | null
  price: number
  durationMinutes: number
  imageUrl: string | null
  isActive: boolean
}

export interface TreatmentInput {
  categoryId: string
  name: string
  description: string | null
  price: number
  durationMinutes: number
  imageUrl: string | null
  isActive: boolean
}

export interface TreatmentStat {
  treatmentId: string
  treatmentName: string
  bookingCount: number
  revenue: number
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
  promoId: string | null
  promoTitle: string | null
  discountAmount: number
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
  promoId?: string | null
  discountAmount?: number
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
  photoUrl: string | null
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
  photoUrl: string | null
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
  discountType: 'percentage' | 'fixed' | null
  discountValue: number | null
}

export interface PromoInput {
  title: string
  bannerImageUrl: string | null
  description: string | null
  startsAt: string | null
  endsAt: string | null
  isActive: boolean
  discountType: 'percentage' | 'fixed' | null
  discountValue: number | null
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

export interface NotificationTemplate {
  id: string
  code: string
  channel: 'wa' | 'push' | 'email'
  subject: string | null
  body: string
  updatedAt: string
}

export interface NotificationTemplateInput {
  code: string
  channel: 'wa' | 'push' | 'email'
  subject: string | null
  body: string
}

export interface NotificationLog {
  id: string
  templateCode: string
  channel: string
  recipient: string
  status: string
  errorMessage: string | null
  sentAt: string
}

export interface SendNotificationInput {
  templateCode: string
  recipient: string
}

export interface Expense {
  id: string
  branchId: string | null
  branchName: string | null
  category: string
  description: string | null
  amount: number
  expenseDate: string
  createdAt: string
}

export interface ExpenseInput {
  branchId: string | null
  category: string
  description: string | null
  amount: number
  expenseDate: string
}

export interface ExpenseCategoryTotal {
  category: string
  total: number
}

export interface CommissionRow {
  staffId: string
  doctorName: string
  revenue: number
  commissionRate: number
  commission: number
}

export interface ProfitReport {
  totalRevenue: number
  totalCommission: number
  totalExpenses: number
  netProfit: number
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

export type ActivityScope = 'admin' | 'mobile'
export type ActivityCategory = 'auth' | 'booking' | 'medical' | 'payment' | 'profile' | 'system'
export type ActivitySeverity = 'INFO' | 'WARNING' | 'ERROR' | 'SECURITY'
export type ActivityStatus = 'SUCCESS' | 'FAILED' | 'PENDING'

export interface ActivityLog {
  id: string
  scope: ActivityScope
  category: ActivityCategory
  action: string
  description: string
  userName: string
  userRole: string
  userEmail: string | null
  ipAddress: string
  userAgent: string
  status: ActivityStatus
  severity: ActivitySeverity
  details?: Record<string, any> | null
  createdAt: string
}

export interface ActivityLogQuery {
  scope?: string
  category?: string
  severity?: string
  search?: string
  page?: number
  pageSize?: number
}

