export interface FollowUpPatient {
  id: string
  patientId: string
  patientName: string
  rmNumber: string
  phoneWa: string
  lastVisitDate: string
  recommendedControlDate: string
  daysRemaining: number
  treatmentName: string
  doctorName: string
  branchName: string
  controlReason: string
  status: 'PENDING' | 'REMINDED' | 'SCHEDULED'
}

const initialFollowUpList: FollowUpPatient[] = [
  {
    id: 'fu-101',
    patientId: 'pat-001',
    patientName: 'Budi Santoso',
    rmNumber: 'RM-001092',
    phoneWa: '081298765432',
    lastVisitDate: '2026-07-03',
    recommendedControlDate: '2026-08-03',
    daysRemaining: 1,
    treatmentName: 'Pemasangan Behel Metal Premium',
    doctorName: 'drg. Friski Raisis, Sp.Ort',
    branchName: 'Soreang',
    controlReason: 'Kontrol Penyesuaian Behel Rutin Bulanan',
    status: 'PENDING'
  },
  {
    id: 'fu-102',
    patientId: 'pat-002',
    patientName: 'Dewi Lestari',
    rmNumber: 'RM-001140',
    phoneWa: '081311223344',
    lastVisitDate: '2026-07-20',
    recommendedControlDate: '2026-08-04',
    daysRemaining: 2,
    treatmentName: 'Cabut Gigi Bungsu (Odontektomi)',
    doctorName: 'drg. Siti Aminah',
    branchName: 'Baleendah',
    controlReason: 'Evaluasi Jahitan & Penyembuhan Gusi Pasca Operasi',
    status: 'PENDING'
  },
  {
    id: 'fu-103',
    patientId: 'pat-003',
    patientName: 'Ahmad Fauzi',
    rmNumber: 'RM-000980',
    phoneWa: '085712345678',
    lastVisitDate: '2026-02-05',
    recommendedControlDate: '2026-08-05',
    daysRemaining: 3,
    treatmentName: 'Scaling 6-in-1 Super Clean',
    doctorName: 'drg. Budi Santoso, Sp.KGA',
    branchName: 'Soreang',
    controlReason: 'Pembersihan Karang Gigi Rutin 6 Bulan Sekali',
    status: 'PENDING'
  },
  {
    id: 'fu-104',
    patientId: 'pat-004',
    patientName: 'Siti Rahmawati',
    rmNumber: 'RM-001205',
    phoneWa: '081909876543',
    lastVisitDate: '2026-07-22',
    recommendedControlDate: '2026-08-06',
    daysRemaining: 4,
    treatmentName: 'Penambalan Gigi Komposit Estetis',
    doctorName: 'drg. Siti Aminah',
    branchName: 'Baleendah',
    controlReason: 'Pengecekan Polishing & Kontak Gigitan Tambalan',
    status: 'REMINDED'
  }
]

export function useFollowUpPatients() {
  const followUpList = useState<FollowUpPatient[]>('follow-up-patients-store', () => initialFollowUpList)

  function markAsReminded(id: string) {
    const item = followUpList.value.find(f => f.id === id)
    if (item) {
      item.status = 'REMINDED'
    }
  }

  function getWhatsAppLink(patient: FollowUpPatient) {
    const cleanPhone = patient.phoneWa.replace(/\D/g, '')
    const formattedPhone = cleanPhone.startsWith('0') ? `62${cleanPhone.slice(1)}` : cleanPhone
    const message = encodeURIComponent(
      `Halo Kak ${patient.patientName},\n\nSalam dari Nina Dental Care! 😊\n\nBerdasarkan riwayat perawatan ${patient.treatmentName} Anda pada ${patient.lastVisitDate}, kami merekomendasikan kontrol ulang untuk: *${patient.controlReason}* pada tanggal *${patient.recommendedControlDate}*.\n\nApakah Kak ${patient.patientName} ingin kami bantu jadwalkan sesi reservasi jadwal dengan ${patient.doctorName} di cabang ${patient.branchName}?\n\nTerima kasih!`
    )
    return `https://wa.me/${formattedPhone}?text=${message}`
  }

  return {
    followUpList,
    markAsReminded,
    getWhatsAppLink
  }
}
