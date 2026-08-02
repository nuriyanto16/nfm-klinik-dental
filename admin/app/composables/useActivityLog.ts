import type { ActivityLog, ActivityScope, ActivityCategory, ActivitySeverity } from '~/types/api'

// Initial seed mock data representing real admin panel access & mobile app activities
const initialLogs: ActivityLog[] = [
  {
    id: 'log-1001',
    scope: 'admin',
    category: 'auth',
    action: 'ADMIN_LOGIN_SUCCESS',
    description: 'Admin drg. Siti Aminah berhasil masuk ke Panel Admin',
    userName: 'drg. Siti Aminah',
    userRole: 'Super Admin',
    userEmail: 'siti.aminah@ninadental.com',
    ipAddress: '180.252.12.44',
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/127.0.0.0',
    status: 'SUCCESS',
    severity: 'INFO',
    details: { method: 'JWT_BEARER', loginAt: '2026-08-02T08:15:00Z', location: 'Bandung, Indonesia' },
    createdAt: '2026-08-02T08:15:00.000Z'
  },
  {
    id: 'log-1002',
    scope: 'mobile',
    category: 'booking',
    action: 'CREATE_RESERVATION',
    description: 'Pasien Budi Santoso membuat reservasi perawatan Scaling 6-in-1',
    userName: 'Budi Santoso',
    userRole: 'Pasien Mobile',
    userEmail: 'budi.santoso@gmail.com',
    ipAddress: '114.124.201.89',
    userAgent: 'NinaDentalMobile/1.2.0 (Android 14; Mobile)',
    status: 'SUCCESS',
    severity: 'INFO',
    details: {
      reservationId: 'res-51000000-0001',
      branch: 'Cabang Baleendah',
      doctor: 'drg. Siti Aminah',
      scheduledAt: '2026-08-04T10:00:00Z',
      treatments: ['Scaling 6-in-1 Super Clean']
    },
    createdAt: '2026-08-02T08:20:12.000Z'
  },
  {
    id: 'log-1003',
    scope: 'mobile',
    category: 'payment',
    action: 'SUBMIT_PAYMENT',
    description: 'Pasien Budi Santoso melakukan pembayaran via Bank BCA Virtual Account',
    userName: 'Budi Santoso',
    userRole: 'Pasien Mobile',
    userEmail: 'budi.santoso@gmail.com',
    ipAddress: '114.124.201.89',
    userAgent: 'NinaDentalMobile/1.2.0 (Android 14; Mobile)',
    status: 'SUCCESS',
    severity: 'INFO',
    details: {
      paymentId: 'pay-771029',
      method: 'BCA',
      amount: 199000,
      status: 'VERIFIED'
    },
    createdAt: '2026-08-02T08:22:45.000Z'
  },
  {
    id: 'log-1004',
    scope: 'admin',
    category: 'medical',
    action: 'VIEW_MEDICAL_RECORD',
    description: 'Dokter drg. Friski Raisis mengakses Rekam Medis pasien #RM-000421',
    userName: 'drg. Friski Raisis, Sp.Ort',
    userRole: 'Dokter Spesialis',
    userEmail: 'friski.raisis@ninadental.com',
    ipAddress: '180.252.12.44',
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Safari/605.1.15',
    status: 'SUCCESS',
    severity: 'INFO',
    details: { rmNumber: 'RM-000421', patientName: 'Dewi Lestari', section: 'Odontogram' },
    createdAt: '2026-08-02T08:35:10.000Z'
  },
  {
    id: 'log-1005',
    scope: 'admin',
    category: 'system',
    action: 'UPDATE_DOCTOR_SCHEDULE',
    description: 'Admin memperbarui jadwal jam praktik drg. Budi Santoso',
    userName: 'Admin Operasional',
    userRole: 'Admin',
    userEmail: 'admin@ninadental.com',
    ipAddress: '180.252.12.44',
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/126.0.0.0',
    status: 'SUCCESS',
    severity: 'INFO',
    details: { doctorId: '21000000-0003', doctorName: 'drg. Budi Santoso, Sp.KGA', changedDays: ['Selasa', 'Kamis'] },
    createdAt: '2026-08-02T08:45:00.000Z'
  },
  {
    id: 'log-1006',
    scope: 'mobile',
    category: 'auth',
    action: 'FAILED_LOGIN_ATTEMPT',
    description: 'Percobaan masuk aplikasi mobile gagal: Kata sandi tidak cocok',
    userName: 'Dewi Lestari',
    userRole: 'Pasien Mobile',
    userEmail: 'dewi.lestari@gmail.com',
    ipAddress: '180.244.110.12',
    userAgent: 'NinaDentalMobile/1.2.0 (iOS 17.5; iPhone)',
    status: 'FAILED',
    severity: 'WARNING',
    details: { attemptCount: 2, reason: 'INVALID_CREDENTIALS' },
    createdAt: '2026-08-02T08:50:30.000Z'
  },
  {
    id: 'log-1007',
    scope: 'admin',
    category: 'system',
    action: 'UNAUTHORIZED_ACCESS_BLOCKED',
    description: 'Upaya akses endpoint sensitif /api/v1/admin/users dari IP tidak dikenal dicegah',
    userName: 'Tidak Terotentikasi',
    userRole: 'Guest',
    userEmail: null,
    ipAddress: '203.0.113.195',
    userAgent: 'curl/7.88.1',
    status: 'FAILED',
    severity: 'SECURITY',
    details: { endpoint: '/api/v1/admin/users', blockedReason: 'MISSING_JWT_TOKEN' },
    createdAt: '2026-08-02T09:01:15.000Z'
  },
  {
    id: 'log-1008',
    scope: 'mobile',
    category: 'profile',
    action: 'UPDATE_PATIENT_PROFILE',
    description: 'Pasien Budi Santoso memperbarui nomor Telepon WhatsApp dan alamat',
    userName: 'Budi Santoso',
    userRole: 'Pasien Mobile',
    userEmail: 'budi.santoso@gmail.com',
    ipAddress: '114.124.201.89',
    userAgent: 'NinaDentalMobile/1.2.0 (Android 14; Mobile)',
    status: 'SUCCESS',
    severity: 'INFO',
    details: { fieldsUpdated: ['phoneWa', 'address'] },
    createdAt: '2026-08-02T09:12:00.000Z'
  }
]

export function useActivityLog() {
  const logsState = useState<ActivityLog[]>('activity-logs-store', () => initialLogs)

  // Reactive filters
  const scopeFilter = ref<'all' | ActivityScope>('all')
  const categoryFilter = ref<'all' | ActivityCategory>('all')
  const severityFilter = ref<'all' | ActivitySeverity>('all')
  const searchQuery = ref('')
  const currentPage = ref(1)
  const pageSize = ref(10)

  const filteredLogs = computed(() => {
    return logsState.value.filter((log) => {
      // Scope match
      if (scopeFilter.value !== 'all' && log.scope !== scopeFilter.value) return false
      // Category match
      if (categoryFilter.value !== 'all' && log.category !== categoryFilter.value) return false
      // Severity match
      if (severityFilter.value !== 'all' && log.severity !== severityFilter.value) return false

      // Search query match
      if (searchQuery.value.trim()) {
        const q = searchQuery.value.toLowerCase().trim()
        const matchUser = log.userName.toLowerCase().includes(q)
        const matchEmail = (log.userEmail || '').toLowerCase().includes(q)
        const matchDesc = log.description.toLowerCase().includes(q)
        const matchAction = log.action.toLowerCase().includes(q)
        const matchIp = log.ipAddress.toLowerCase().includes(q)
        return matchUser || matchEmail || matchDesc || matchAction || matchIp
      }

      return true
    })
  })

  const paginatedLogs = computed(() => {
    const start = (currentPage.value - 1) * pageSize.value
    return filteredLogs.value.slice(start, start + pageSize.value)
  })

  const totalPages = computed(() => Math.ceil(filteredLogs.value.length / pageSize.value) || 1)

  const stats = computed(() => {
    const total = logsState.value.length
    const adminCount = logsState.value.filter((l) => l.scope === 'admin').length
    const mobileCount = logsState.value.filter((l) => l.scope === 'mobile').length
    const securityCount = logsState.value.filter((l) => l.severity === 'SECURITY' || l.severity === 'WARNING' || l.severity === 'ERROR').length

    return { total, adminCount, mobileCount, securityCount }
  })

  function addLog(log: Omit<ActivityLog, 'id' | 'createdAt'>) {
    const newLog: ActivityLog = {
      ...log,
      id: `log-${Date.now()}`,
      createdAt: new Date().toISOString()
    }
    logsState.value.unshift(newLog)
  }

  function clearLogs() {
    logsState.value = []
  }

  return {
    logs: paginatedLogs,
    allLogs: filteredLogs,
    stats,
    scopeFilter,
    categoryFilter,
    severityFilter,
    searchQuery,
    currentPage,
    pageSize,
    totalPages,
    addLog,
    clearLogs
  }
}
