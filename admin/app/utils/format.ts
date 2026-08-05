export function formatIDR(amount: number): string {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(amount)
}

export function formatDateTime(iso: string): string {
  return new Intl.DateTimeFormat('id-ID', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(iso))
}

export function formatCompactIDR(amount: number): string {
  return new Intl.NumberFormat('id-ID', { notation: 'compact', maximumFractionDigits: 1 }).format(amount)
}

export function formatDateShort(isoDate?: string | null): string {
  if (!isoDate || typeof isoDate !== 'string') return '—'
  try {
    const date = isoDate.includes('T') ? new Date(isoDate) : new Date(`${isoDate}T00:00:00`)
    if (isNaN(date.getTime())) return '—'
    return new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short' }).format(date)
  } catch {
    return '—'
  }
}

export function safeDateShort(isoDate?: string | null): string {
  return formatDateShort(isoDate)
}

export function safeQueueTicket(id?: string | null): string {
  if (!id || typeof id !== 'string') return 'NDC-001'
  if (id.startsWith('NDC-') || id.startsWith('ANT-') || id.startsWith('RES-')) {
    return id.toUpperCase()
  }
  const clean = id.replace(/[^a-zA-Z0-9]/g, '')
  if (clean.length >= 6) {
    const end = clean.slice(-4).toUpperCase()
    return `NDC-${end}`
  }
  const match = id.match(/\d+/)
  const num = match ? match[0].padStart(3, '0') : '001'
  return `NDC-${num}`
}

export type BadgeColor = 'error' | 'primary' | 'secondary' | 'success' | 'info' | 'warning' | 'neutral'

const RESERVATION_STATUS_COLOR: Record<string, BadgeColor> = {
  pending: 'neutral',
  confirmed: 'info',
  checked_in: 'warning',
  in_progress: 'warning',
  completed: 'success',
  cancelled: 'error',
  no_show: 'error'
}

export function reservationStatusColor(status: string): BadgeColor {
  return RESERVATION_STATUS_COLOR[status] ?? 'neutral'
}

const RESERVATION_STATUS_LABEL: Record<string, string> = {
  pending: 'Menunggu',
  confirmed: 'Terkonfirmasi',
  checked_in: 'Check-in',
  in_progress: 'Sedang Ditangani',
  completed: 'Selesai',
  cancelled: 'Dibatalkan',
  no_show: 'Tidak Hadir'
}

export function reservationStatusLabel(status: string): string {
  return RESERVATION_STATUS_LABEL[status] ?? status
}

const PAYMENT_STATUS_COLOR: Record<string, BadgeColor> = {
  pending: 'warning',
  paid: 'success',
  expired: 'neutral',
  failed: 'error',
  refunded: 'info'
}

export function paymentStatusColor(status: string): BadgeColor {
  return PAYMENT_STATUS_COLOR[status] ?? 'neutral'
}

const PAYMENT_STATUS_LABEL: Record<string, string> = {
  pending: 'Menunggu Pembayaran',
  paid: 'Lunas',
  expired: 'Kedaluwarsa',
  failed: 'Gagal',
  refunded: 'Dikembalikan'
}

export function paymentStatusLabel(status: string): string {
  return PAYMENT_STATUS_LABEL[status] ?? status
}

export function formatTransactionId(id?: string | null, dateStr?: string | Date | null): string {
  if (!id || typeof id !== 'string') return 'TRX-00000000-0000'
  if (id.startsWith('TRX-') || id.startsWith('INV-')) return id
  const d = dateStr ? new Date(dateStr) : new Date()
  const year = isNaN(d.getTime()) ? '2026' : String(d.getFullYear())
  const month = isNaN(d.getTime()) ? '08' : String(d.getMonth() + 1).padStart(2, '0')
  const day = isNaN(d.getTime()) ? '04' : String(d.getDate()).padStart(2, '0')
  const clean = id.replace(/-/g, '').toUpperCase()
  const shortCode = clean.length >= 6 ? clean.slice(-6) : clean.padStart(6, '0')
  return `TRX-${year}${month}${day}-${shortCode}`
}

