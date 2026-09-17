<script setup lang="ts">
definePageMeta({ title: 'Display Antrian TV' })

export interface QueueItem {
  id: string
  ticketNumber: string
  patientName: string
  treatmentName: string
  doctorName: string
  polyName: string
  unitNumber: number
  branchName: string
  status: 'CALLING' | 'SERVING' | 'WAITING' | 'COMPLETED' | 'SKIPPED'
  estimatedTime?: string
  calledAt?: string
}

export interface DentalUnit {
  id: number
  unitName: string
  polyName: string
  doctorName: string
  status: 'BUSY' | 'AVAILABLE' | 'PREPARING'
  currentTicket?: string
  currentPatient?: string
}

const selectedBranch = ref<'Soreang' | 'Baleendah'>('Soreang')
const isMuted = ref(false)
const isFullscreen = ref(false)
const showControls = ref(true)
const isAnnouncing = ref(false)
const showWalkinModal = ref(false)

// Real-time Clock
const currentTime = ref('')
const currentDate = ref('')

function updateClock() {
  const now = new Date()
  currentTime.value = now.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' }) + ' WIB'
  currentDate.value = now.toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })
}

let timer: any = null
onMounted(() => {
  updateClock()
  timer = setInterval(updateClock, 1000)
  document.addEventListener('fullscreenchange', onFullscreenChange)
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
  document.removeEventListener('fullscreenchange', onFullscreenChange)
})

function onFullscreenChange() {
  isFullscreen.value = Boolean(document.fullscreenElement)
}

function toggleFullscreen() {
  if (!document.fullscreenElement) {
    document.documentElement.requestFullscreen().catch(() => {})
  } else {
    document.exitFullscreen().catch(() => {})
  }
}

// Dental Units
const dentalUnits = ref<DentalUnit[]>([
  {
    id: 1,
    unitName: 'Dental Unit 1',
    polyName: 'Poli Spesialis Ortodonti',
    doctorName: 'drg. Friski Raisis, Sp.Ort',
    status: 'BUSY',
    currentTicket: 'A-005',
    currentPatient: 'Budi Santoso'
  },
  {
    id: 2,
    unitName: 'Dental Unit 2',
    polyName: 'Poli Gigi Umum & Bedah',
    doctorName: 'drg. Siti Aminah',
    status: 'BUSY',
    currentTicket: 'B-002',
    currentPatient: 'Dewi Lestari'
  },
  {
    id: 3,
    unitName: 'Dental Unit 3',
    polyName: 'Poli Spesialis Gigi Anak (Pedodonti)',
    doctorName: 'drg. Budi Santoso, Sp.KGA',
    status: 'AVAILABLE'
  },
  {
    id: 4,
    unitName: 'Dental Unit 4',
    polyName: 'Poli Konservasi & Estetika Gigi',
    doctorName: 'drg. Nina Marlina, Sp.KG',
    status: 'AVAILABLE'
  }
])

// Current Active Calling Ticket
const activeQueue = ref<QueueItem>({
  id: 'q-active',
  ticketNumber: 'A-005',
  patientName: 'Budi Santoso',
  treatmentName: 'Pemasangan Behel Metal Premium',
  doctorName: 'drg. Friski Raisis, Sp.Ort',
  polyName: 'Poli Spesialis Ortodonti',
  unitNumber: 1,
  branchName: 'Soreang',
  status: 'CALLING',
  calledAt: 'Baru saja'
})

// Upcoming Queues
const waitingQueues = ref<QueueItem[]>([
  {
    id: 'q-101',
    ticketNumber: 'A-006',
    patientName: 'Ahmad Fauzi',
    treatmentName: 'Scaling 6-in-1 Super Clean',
    doctorName: 'drg. Siti Aminah',
    polyName: 'Poli Gigi Umum',
    unitNumber: 2,
    branchName: 'Soreang',
    status: 'WAITING',
    estimatedTime: '10 Menit'
  },
  {
    id: 'q-102',
    ticketNumber: 'B-003',
    patientName: 'Siti Rahmawati',
    treatmentName: 'Penambalan Gigi Komposit',
    doctorName: 'drg. Nina Marlina, Sp.KG',
    polyName: 'Poli Konservasi',
    unitNumber: 4,
    branchName: 'Soreang',
    status: 'WAITING',
    estimatedTime: '20 Menit'
  },
  {
    id: 'q-103',
    ticketNumber: 'A-007',
    patientName: 'Rizky Pratama',
    treatmentName: 'Cabut Gigi Bungsu (Odontektomi)',
    doctorName: 'drg. Friski Raisis, Sp.Ort',
    polyName: 'Poli Spesialis Ortodonti',
    unitNumber: 1,
    branchName: 'Soreang',
    status: 'WAITING',
    estimatedTime: '35 Menit'
  },
  {
    id: 'q-104',
    ticketNumber: 'C-001',
    patientName: 'Kenzo Alfarizi',
    treatmentName: 'Perawatan Gigi Anak & Fluoride',
    doctorName: 'drg. Budi Santoso, Sp.KGA',
    polyName: 'Poli Gigi Anak',
    unitNumber: 3,
    branchName: 'Soreang',
    status: 'WAITING',
    estimatedTime: '45 Menit'
  },
  {
    id: 'q-105',
    ticketNumber: 'A-008',
    patientName: 'Jessica Tan',
    treatmentName: 'Bleaching Gigi Laser Glow',
    doctorName: 'drg. Nina Marlina, Sp.KG',
    polyName: 'Poli Konservasi',
    unitNumber: 4,
    branchName: 'Soreang',
    status: 'WAITING',
    estimatedTime: '60 Menit'
  }
])

// History called queues
const completedQueues = ref<QueueItem[]>([
  {
    id: 'q-099',
    ticketNumber: 'A-004',
    patientName: 'Hendra Gunawan',
    treatmentName: 'Kontrol Kawat Gigi',
    doctorName: 'drg. Friski Raisis, Sp.Ort',
    polyName: 'Poli Ortodonti',
    unitNumber: 1,
    branchName: 'Soreang',
    status: 'COMPLETED'
  },
  {
    id: 'q-098',
    ticketNumber: 'B-001',
    patientName: 'Rina Kusuma',
    treatmentName: 'Pembersihan Karang Gigi',
    doctorName: 'drg. Siti Aminah',
    polyName: 'Poli Gigi Umum',
    unitNumber: 2,
    branchName: 'Soreang',
    status: 'COMPLETED'
  }
])

// --- Audio & Web Speech Chime Engine ---
function playChimeSound(): Promise<void> {
  return new Promise((resolve) => {
    if (isMuted.value) {
      resolve()
      return
    }

    try {
      const AudioCtx = window.AudioContext || (window as any).webkitAudioContext
      if (!AudioCtx) {
        resolve()
        return
      }

      const ctx = new AudioCtx()
      const now = ctx.currentTime

      // 3-tone chime: D5 (587.33Hz) -> F#5 (739.99Hz) -> A5 (880Hz)
      const notes = [587.33, 739.99, 880]
      notes.forEach((freq, idx) => {
        const osc = ctx.createOscillator()
        const gain = ctx.createGain()
        osc.type = 'sine'
        osc.frequency.setValueAtTime(freq, now + idx * 0.22)

        gain.gain.setValueAtTime(0, now + idx * 0.22)
        gain.gain.linearRampToValueAtTime(0.3, now + idx * 0.22 + 0.04)
        gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.22 + 0.6)

        osc.connect(gain)
        gain.connect(ctx.destination)

        osc.start(now + idx * 0.22)
        osc.stop(now + idx * 0.22 + 0.65)
      })

      setTimeout(() => {
        resolve()
      }, 1000)
    } catch (_) {
      resolve()
    }
  })
}

async function announceVoice(ticket: string, name: string, unit: string, doctor: string) {
  if (isMuted.value) return

  isAnnouncing.value = true
  await playChimeSound()

  if ('speechSynthesis' in window) {
    window.speechSynthesis.cancel()

    // Format ticket for pronunciation (e.g. "A-005" -> "A, nol, nol, lima")
    const formattedTicket = ticket.split('').join(' ')
    const text = `Nomor Antrian, ${formattedTicket}. ${name}. Silakan menuju ${unit}, ${doctor}.`

    const utterance = new SpeechSynthesisUtterance(text)
    utterance.lang = 'id-ID'
    utterance.rate = 0.9
    utterance.pitch = 1.0

    // Try to find Indonesian voice
    const voices = window.speechSynthesis.getVoices()
    const idVoice = voices.find(v => v.lang.includes('id') || v.lang.includes('ID'))
    if (idVoice) utterance.voice = idVoice

    utterance.onend = () => {
      isAnnouncing.value = false
    }
    utterance.onerror = () => {
      isAnnouncing.value = false
    }

    window.speechSynthesis.speak(utterance)
  } else {
    setTimeout(() => {
      isAnnouncing.value = false
    }, 2500)
  }
}

// Controls
function callNextQueue() {
  if (waitingQueues.value.length === 0) {
    alert('Tidak ada antrian berikutnya yang sedang menunggu.')
    return
  }

  // Move current active to completed
  if (activeQueue.value) {
    completedQueues.value.unshift({
      ...activeQueue.value,
      status: 'COMPLETED'
    })
  }

  // Take first waiting
  const next = waitingQueues.value.shift()!
  activeQueue.value = {
    ...next,
    status: 'CALLING',
    calledAt: 'Baru saja'
  }

  // Update relevant unit
  const targetUnit = dentalUnits.value.find(u => u.id === next.unitNumber)
  if (targetUnit) {
    targetUnit.status = 'BUSY'
    targetUnit.currentTicket = next.ticketNumber
    targetUnit.currentPatient = next.patientName
  }

  announceVoice(
    activeQueue.value.ticketNumber,
    activeQueue.value.patientName,
    `Dental Unit ${activeQueue.value.unitNumber}`,
    activeQueue.value.doctorName
  )
}

function recallCurrentQueue() {
  if (!activeQueue.value) return
  announceVoice(
    activeQueue.value.ticketNumber,
    activeQueue.value.patientName,
    `Dental Unit ${activeQueue.value.unitNumber}`,
    activeQueue.value.doctorName
  )
}

function markCompleted() {
  if (activeQueue.value) {
    completedQueues.value.unshift({
      ...activeQueue.value,
      status: 'COMPLETED'
    })
    const targetUnit = dentalUnits.value.find(u => u.id === activeQueue.value.unitNumber)
    if (targetUnit) {
      targetUnit.status = 'AVAILABLE'
      targetUnit.currentTicket = undefined
      targetUnit.currentPatient = undefined
    }
  }
}

function skipCurrentQueue() {
  if (activeQueue.value) {
    waitingQueues.value.push({
      ...activeQueue.value,
      status: 'SKIPPED'
    })
    callNextQueue()
  }
}

// Walkin registration
const walkinForm = reactive({
  patientName: '',
  doctorName: 'drg. Friski Raisis, Sp.Ort',
  treatmentName: 'Konsultasi & Pemeriksaan Gigi',
  unitNumber: 1
})

function registerWalkinTicket() {
  if (!walkinForm.patientName) {
    alert('Nama pasien wajib diisi.')
    return
  }

  const prefix = walkinForm.unitNumber === 1 ? 'A' : (walkinForm.unitNumber === 2 ? 'B' : 'C')
  const num = String(waitingQueues.value.length + completedQueues.value.length + 8).padStart(3, '0')
  const newTicket = `${prefix}-${num}`

  waitingQueues.value.push({
    id: `q-walkin-${Date.now()}`,
    ticketNumber: newTicket,
    patientName: walkinForm.patientName,
    treatmentName: walkinForm.treatmentName,
    doctorName: walkinForm.doctorName,
    polyName: `Poli Unit ${walkinForm.unitNumber}`,
    unitNumber: walkinForm.unitNumber,
    branchName: selectedBranch.value,
    status: 'WAITING',
    estimatedTime: '25 Menit'
  })

  useAppNotification().success(
    `Tiket ${newTicket} berhasil dicetak untuk ${walkinForm.patientName}.`,
    'Tiket Antrian Diterbitkan'
  )

  walkinForm.patientName = ''
  showWalkinModal.value = false
}

// Ticker News
const tickerMessages = [
  '🦷 Selamat Datang di Nina Dental Care — Senyum Sehat & Percaya Diri Anda Adalah Prioritas Kami',
  '✨ Promo Spesial Bulan Ini: Paket Scaling 6-in-1 Diskon 20% melalui Mobile App',
  '📱 Pasien dapat mengunduh Aplikasi Mobile Nina Dental Care di Google Play Store untuk reservasi mudah & riwayat rekam medis digital',
  '⏰ Jadwal Praktik: Senin s/d Sabtu Pukul 08.00 - 20.00 WIB • Hari Minggu dengan Perjanjian Khusus',
  '🛡️ Seluruh alat kedokteran gigi disterilisasi sesuai standar klinis medis internasional'
]
</script>

<template>
  <div
    class="min-h-screen bg-slate-950 text-white font-sans flex flex-col justify-between select-none relative overflow-hidden"
    :class="{ 'fixed inset-0 z-50': isFullscreen }"
  >
    <!-- Background Ambient Glows -->
    <div class="absolute -top-40 -left-40 w-96 h-96 bg-primary-600/15 rounded-full blur-3xl pointer-events-none"></div>
    <div class="absolute top-1/2 -right-40 w-96 h-96 bg-emerald-600/10 rounded-full blur-3xl pointer-events-none"></div>
    <div class="absolute -bottom-40 left-1/3 w-96 h-96 bg-blue-600/10 rounded-full blur-3xl pointer-events-none"></div>

    <!-- 1. TOP HEADER BAR -->
    <header class="bg-slate-900/80 backdrop-blur-md border-b border-slate-800 px-6 py-3.5 flex items-center justify-between gap-4 z-10">
      <!-- Clinic Brand -->
      <div class="flex items-center gap-3">
        <div class="w-11 h-11 rounded-xl bg-gradient-to-br from-primary-500 to-primary-700 flex items-center justify-center text-white shadow-lg shadow-primary-500/25">
          <UIcon name="i-lucide-activity" class="w-6 h-6" />
        </div>
        <div>
          <div class="flex items-center gap-2">
            <h1 class="font-extrabold text-xl tracking-wider text-white">NINA DENTAL CARE</h1>
            <span class="px-2 py-0.5 text-[10px] font-bold rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
              LIVE DISPLAY
            </span>
          </div>
          <p class="text-xs text-slate-400 font-medium">Klinik Dokter Gigi Spesialis & Keluarga</p>
        </div>
      </div>

      <!-- Center: Branch Selector -->
      <div class="hidden md:flex items-center gap-1.5 bg-slate-800/80 p-1 rounded-xl border border-slate-700">
        <button
          class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5"
          :class="selectedBranch === 'Soreang' ? 'bg-primary-600 text-white shadow-sm' : 'text-slate-400 hover:text-white'"
          @click="selectedBranch = 'Soreang'"
        >
          <UIcon name="i-lucide-map-pin" class="w-3.5 h-3.5" />
          Cabang Soreang
        </button>
        <button
          class="px-3 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5"
          :class="selectedBranch === 'Baleendah' ? 'bg-primary-600 text-white shadow-sm' : 'text-slate-400 hover:text-white'"
          @click="selectedBranch = 'Baleendah'"
        >
          <UIcon name="i-lucide-map-pin" class="w-3.5 h-3.5" />
          Cabang Baleendah
        </button>
      </div>

      <!-- Right: Clock & Top Controls -->
      <div class="flex items-center gap-4">
        <div class="text-right">
          <div class="font-mono font-extrabold text-lg text-emerald-400 tracking-wider flex items-center justify-end gap-1.5">
            <span class="inline-block w-2 h-2 rounded-full bg-emerald-400 animate-ping"></span>
            {{ currentTime }}
          </div>
          <div class="text-xs text-slate-400 font-medium">{{ currentDate }}</div>
        </div>

        <div class="flex items-center gap-1 border-l border-slate-800 pl-3">
          <!-- Audio mute toggle -->
          <button
            class="p-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
            :title="isMuted ? 'Aktifkan Suara Panggilan' : 'Matikan Suara'"
            @click="isMuted = !isMuted"
          >
            <UIcon :name="isMuted ? 'i-lucide-volume-x' : 'i-lucide-volume-2'" class="w-5 h-5 text-emerald-400" />
          </button>

          <!-- Toggle Controls Bar -->
          <button
            class="p-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
            title="Sembunyikan / Tampilkan Tombol Operator"
            @click="showControls = !showControls"
          >
            <UIcon name="i-lucide-sliders" class="w-5 h-5" />
          </button>

          <!-- Fullscreen toggle -->
          <button
            class="p-2 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
            :title="isFullscreen ? 'Keluar Layar Penuh' : 'Mode TV Layar Penuh'"
            @click="toggleFullscreen"
          >
            <UIcon :name="isFullscreen ? 'i-lucide-minimize' : 'i-lucide-maximize'" class="w-5 h-5 text-primary-400" />
          </button>
        </div>
      </div>
    </header>

    <!-- 2. MAIN DISPLAY CONTENT -->
    <main class="flex-1 p-6 grid grid-cols-1 lg:grid-cols-12 gap-6 z-10">
      <!-- LEFT / CENTER COLUMN: ACTIVE CALLING TICKET HERO (Col 12 / 8) -->
      <div class="lg:col-span-8 flex flex-col gap-6">
        <!-- HERO CARD: SEDANG DILAYANI -->
        <div class="flex-1 rounded-3xl bg-gradient-to-br from-slate-900 via-slate-900/90 to-slate-800/80 border-2 border-primary-500/50 p-7 flex flex-col justify-between shadow-2xl shadow-primary-950/50 relative overflow-hidden">
          <!-- Sound wave pulsing banner if calling -->
          <div
            v-if="isAnnouncing"
            class="absolute top-0 left-0 right-0 py-1 bg-gradient-to-r from-emerald-600 to-teal-500 text-center font-bold text-xs uppercase tracking-widest text-white flex items-center justify-center gap-2 animate-pulse"
          >
            <UIcon name="i-lucide-volume-2" class="w-4 h-4 animate-bounce" />
            SEDANG MEMANGGIL NOMOR ANTRIAN...
          </div>

          <!-- Top Label -->
          <div class="flex items-center justify-between pt-2">
            <div class="flex items-center gap-2">
              <span class="w-3 h-3 rounded-full bg-emerald-400 animate-ping"></span>
              <span class="text-sm font-extrabold uppercase tracking-widest text-emerald-400">
                PANGGILAN SAAT INI
              </span>
            </div>
            <div class="flex items-center gap-2">
              <span class="px-3 py-1 rounded-full text-xs font-bold bg-primary-500/20 text-primary-300 border border-primary-500/30">
                {{ activeQueue.polyName }}
              </span>
            </div>
          </div>

          <!-- Center Massive Ticket -->
          <div class="text-center my-auto py-6">
            <div class="inline-block px-10 py-5 rounded-3xl bg-slate-950/80 border-4 border-primary-500 shadow-inner shadow-primary-500/20">
              <div class="text-7xl sm:text-8xl md:text-9xl font-black font-mono tracking-tighter text-transparent bg-clip-text bg-gradient-to-b from-white via-slate-100 to-primary-300 drop-shadow-md">
                {{ activeQueue.ticketNumber }}
              </div>
            </div>

            <!-- Patient Name -->
            <div class="mt-5">
              <h2 class="text-3xl sm:text-4xl font-black text-white tracking-tight">
                {{ activeQueue.patientName }}
              </h2>
              <p class="text-sm sm:text-base text-primary-300 font-semibold mt-1">
                {{ activeQueue.treatmentName }}
              </p>
            </div>
          </div>

          <!-- Bottom Room & Doctor Indicator -->
          <div class="pt-4 border-t border-slate-800/80 grid grid-cols-2 gap-4 bg-slate-950/40 p-4 rounded-2xl">
            <div class="flex items-center gap-3">
              <div class="w-12 h-12 rounded-xl bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400">
                <UIcon name="i-lucide-map-pin" class="w-6 h-6" />
              </div>
              <div>
                <span class="text-[10px] uppercase font-bold text-slate-400 block">Ruangan / Unit</span>
                <span class="text-base sm:text-lg font-black text-emerald-300">Dental Unit {{ activeQueue.unitNumber }}</span>
              </div>
            </div>

            <div class="flex items-center gap-3">
              <div class="w-12 h-12 rounded-xl bg-primary-500/10 border border-primary-500/30 flex items-center justify-center text-primary-400">
                <UIcon name="i-lucide-stethoscope" class="w-6 h-6" />
              </div>
              <div>
                <span class="text-[10px] uppercase font-bold text-slate-400 block">Dokter Penanggung Jawab</span>
                <span class="text-base sm:text-lg font-bold text-white truncate block">{{ activeQueue.doctorName }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- MULTI-UNIT STATUS BAR (ROW OF 4 UNITS) -->
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div
            v-for="u in dentalUnits"
            :key="u.id"
            class="p-3.5 rounded-2xl border transition-all duration-300 flex flex-col justify-between gap-2"
            :class="u.status === 'BUSY'
              ? 'bg-slate-900/90 border-emerald-500/40 shadow-md shadow-emerald-950/20'
              : 'bg-slate-900/40 border-slate-800 hover:border-slate-700'"
          >
            <div class="flex items-center justify-between">
              <span class="text-xs font-extrabold text-white">{{ u.unitName }}</span>
              <span
                class="px-2 py-0.5 rounded text-[10px] font-bold uppercase"
                :class="u.status === 'BUSY' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-800 text-slate-400'"
              >
                {{ u.status === 'BUSY' ? 'Melayani' : 'Tersedia' }}
              </span>
            </div>

            <div>
              <div v-if="u.status === 'BUSY'" class="flex items-center gap-1.5 font-mono font-black text-xl text-emerald-400">
                <UIcon name="i-lucide-ticket-percent" class="w-4 h-4" />
                {{ u.currentTicket }}
              </div>
              <div v-else class="text-slate-500 text-xs italic">
                Siap periksa pasien
              </div>
              <div class="text-[11px] text-slate-300 font-medium truncate mt-0.5">{{ u.doctorName }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- RIGHT COLUMN: UPCOMING QUEUE LIST (Col 12 / 4) -->
      <div class="lg:col-span-4 flex flex-col gap-4">
        <!-- Card Antrian Menunggu -->
        <div class="flex-1 rounded-3xl bg-slate-900/80 border border-slate-800 p-5 flex flex-col justify-between shadow-xl">
          <div>
            <div class="flex items-center justify-between pb-3 border-b border-slate-800">
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-users" class="w-5 h-5 text-primary-400" />
                <h3 class="font-extrabold text-sm tracking-wide text-white">ANTRIAN BERIKUTNYA</h3>
              </div>
              <span class="px-2.5 py-0.5 rounded-full text-xs font-bold bg-primary-500/20 text-primary-300">
                {{ waitingQueues.length }} Menunggu
              </span>
            </div>

            <!-- List of upcoming tickets -->
            <div class="space-y-2.5 mt-3 overflow-y-auto max-h-[380px] pr-1">
              <div
                v-if="waitingQueues.length === 0"
                class="py-12 text-center text-slate-500 text-xs italic"
              >
                Tidak ada antrian yang menunggu saat ini.
              </div>
              <div
                v-for="(item, idx) in waitingQueues"
                :key="item.id"
                class="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80 flex items-center justify-between gap-3 hover:border-slate-700 transition-colors"
              >
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-xl bg-slate-800 text-primary-300 font-mono font-black text-sm flex items-center justify-center border border-slate-700">
                    {{ item.ticketNumber }}
                  </div>
                  <div>
                    <h4 class="font-bold text-xs text-white leading-snug">{{ item.patientName }}</h4>
                    <p class="text-[10px] text-slate-400 truncate">{{ item.doctorName }}</p>
                  </div>
                </div>

                <div class="text-right">
                  <span class="px-2 py-0.5 rounded text-[10px] font-bold bg-slate-800 text-amber-400 block mb-0.5">
                    Unit {{ item.unitNumber }}
                  </span>
                  <span class="text-[10px] text-slate-500 font-mono">~{{ item.estimatedTime }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Bottom: Quick stats & Completed ticker -->
          <div class="pt-3 border-t border-slate-800 text-xs text-slate-400 flex items-center justify-between">
            <span>Selesai Dilayani Hari Ini:</span>
            <span class="font-bold text-emerald-400">{{ completedQueues.length }} Pasien</span>
          </div>
        </div>

        <!-- OPERATOR CONTROL BAR (Quick Buttons) -->
        <div v-if="showControls" class="p-4 rounded-2xl bg-slate-900 border border-slate-800 space-y-2.5">
          <div class="flex items-center justify-between">
            <span class="text-[11px] font-bold text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
              <UIcon name="i-lucide-sliders" class="w-3.5 h-3.5 text-primary" />
              Kontrol Petugas / Resepsionis
            </span>
            <button
              class="text-[11px] text-primary-400 hover:underline font-bold flex items-center gap-1"
              @click="showWalkinModal = true"
            >
              <UIcon name="i-lucide-plus" class="w-3 h-3" />
              + Tiket Walk-in
            </button>
          </div>

          <div class="grid grid-cols-2 gap-2">
            <button
              class="px-3 py-2.5 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold text-xs flex items-center justify-center gap-1.5 shadow-md shadow-emerald-900/30 hover:opacity-95 active:scale-95 transition-all"
              @click="callNextQueue"
            >
              <UIcon name="i-lucide-megaphone" class="w-4 h-4" />
              Panggil Berikutnya
            </button>

            <button
              class="px-3 py-2.5 rounded-xl bg-slate-800 border border-slate-700 text-white font-bold text-xs flex items-center justify-center gap-1.5 hover:bg-slate-700 active:scale-95 transition-all"
              @click="recallCurrentQueue"
            >
              <UIcon name="i-lucide-volume-2" class="w-4 h-4 text-emerald-400" />
              Panggil Ulang (Suara)
            </button>

            <button
              class="px-3 py-2 rounded-xl bg-slate-800/80 hover:bg-slate-800 text-slate-300 font-semibold text-xs flex items-center justify-center gap-1"
              @click="markCompleted"
            >
              <UIcon name="i-lucide-check-circle" class="w-3.5 h-3.5 text-emerald-400" />
              Tandai Selesai
            </button>

            <button
              class="px-3 py-2 rounded-xl bg-slate-800/80 hover:bg-slate-800 text-slate-300 font-semibold text-xs flex items-center justify-center gap-1"
              @click="skipCurrentQueue"
            >
              <UIcon name="i-lucide-skip-forward" class="w-3.5 h-3.5 text-amber-400" />
              Lewati Antrian
            </button>
          </div>
        </div>
      </div>
    </main>

    <!-- 3. BOTTOM LIVE RUNNING TICKER -->
    <footer class="bg-slate-900/95 border-t border-slate-800 py-2.5 px-6 flex items-center gap-4 z-10 overflow-hidden">
      <div class="flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-primary-600 text-white font-extrabold text-[11px] uppercase tracking-wider shrink-0">
        <UIcon name="i-lucide-bell" class="w-3.5 h-3.5" />
        INFO KLINIK
      </div>

      <div class="overflow-hidden whitespace-nowrap w-full">
        <div class="inline-block animate-marquee text-xs text-slate-300 font-medium">
          <span v-for="(msg, i) in tickerMessages" :key="i" class="mx-6">
            {{ msg }}
          </span>
        </div>
      </div>
    </footer>

    <!-- MODAL PENDAFTARAN TIKET WALK-IN -->
    <UModal v-model:open="showWalkinModal" title="Pendaftaran Antrian Walk-in (Di Tempat)">
      <template #body>
        <form class="space-y-3.5 text-xs text-gray-800 dark:text-white" @submit.prevent="registerWalkinTicket">
          <div>
            <label class="block font-semibold mb-1">Nama Pasien *</label>
            <input
              v-model="walkinForm.patientName"
              type="text"
              placeholder="Nama lengkap pasien..."
              class="w-full p-2.5 border rounded-lg bg-white dark:bg-gray-800 font-semibold"
              required
            >
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-semibold mb-1">Dental Unit / Poli</label>
              <select
                v-model.number="walkinForm.unitNumber"
                class="w-full p-2 border rounded-lg bg-white dark:bg-gray-800"
              >
                <option :value="1">Unit 1 - Poli Spesialis Ortodonti</option>
                <option :value="2">Unit 2 - Poli Gigi Umum & Bedah</option>
                <option :value="3">Unit 3 - Poli Gigi Anak</option>
                <option :value="4">Unit 4 - Poli Konservasi Gigi</option>
              </select>
            </div>

            <div>
              <label class="block font-semibold mb-1">Dokter</label>
              <select
                v-model="walkinForm.doctorName"
                class="w-full p-2 border rounded-lg bg-white dark:bg-gray-800"
              >
                <option value="drg. Friski Raisis, Sp.Ort">drg. Friski Raisis, Sp.Ort</option>
                <option value="drg. Siti Aminah">drg. Siti Aminah</option>
                <option value="drg. Budi Santoso, Sp.KGA">drg. Budi Santoso, Sp.KGA</option>
                <option value="drg. Nina Marlina, Sp.KG">drg. Nina Marlina, Sp.KG</option>
              </select>
            </div>
          </div>

          <div>
            <label class="block font-semibold mb-1">Layanan / Keluhan</label>
            <input
              v-model="walkinForm.treatmentName"
              type="text"
              placeholder="Contoh: Scaling karang gigi / Cabut gigi..."
              class="w-full p-2 border rounded-lg bg-white dark:bg-gray-800"
            >
          </div>

          <div class="flex justify-end gap-2 pt-3 border-t">
            <UButton label="Batal" color="neutral" variant="ghost" @click="showWalkinModal = false" />
            <UButton label="Cetak & Masukkan Antrian" color="primary" type="submit" />
          </div>
        </form>
      </template>
    </UModal>
  </div>
</template>

<style scoped>
@keyframes marquee {
  0% {
    transform: translateX(0%);
  }
  100% {
    transform: translateX(-50%);
  }
}

.animate-marquee {
  display: inline-block;
  white-space: nowrap;
  animation: marquee 35s linear infinite;
}

.animate-marquee:hover {
  animation-play-state: paused;
}
</style>
