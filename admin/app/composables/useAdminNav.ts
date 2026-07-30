export interface AdminNavItem {
  type?: 'label' | 'link'
  label: string
  icon?: string
  to?: string
  phase?: 1 | 2 | 3
}

/**
 * Sidebar navigation for the office/admin panel, grouped by workflow so the
 * sidebar reads as sections rather than one flat list of 12 links. `type:
 * 'label'` items render as section headers in UNavigationMenu (vertical
 * orientation only). `phase` tracks which roadmap phase wires the module up
 * to real data, for pages that still show a "coming soon" placeholder.
 */
export function useAdminNav() {
  const items: AdminNavItem[] = [
    { label: 'Dashboard', icon: 'i-lucide-layout-dashboard', to: '/', phase: 1 },

    { type: 'label', label: 'Operasional' },
    { label: 'Reservasi & Antrian', icon: 'i-lucide-calendar-check', to: '/reservations', phase: 1 },
    { label: 'Pasien', icon: 'i-lucide-users', to: '/patients', phase: 1 },
    { label: 'Dokter & Jadwal', icon: 'i-lucide-stethoscope', to: '/doctors', phase: 1 },
    { label: 'Cabang', icon: 'i-lucide-map-pin', to: '/branches', phase: 1 },
    { label: 'Perawatan & Harga', icon: 'i-lucide-list-checks', to: '/treatments', phase: 1 },

    { type: 'label', label: 'Klinis' },
    { label: 'Rekam Medis', icon: 'i-lucide-file-heart', to: '/medical-records', phase: 2 },
    { label: 'Inventaris (Alat & Obat)', icon: 'i-lucide-package', to: '/inventory', phase: 2 },

    { type: 'label', label: 'Keuangan' },
    { label: 'Billing & Transaksi', icon: 'i-lucide-credit-card', to: '/billing', phase: 2 },
    { label: 'Laporan Keuangan', icon: 'i-lucide-bar-chart-3', to: '/reports', phase: 3 },

    { type: 'label', label: 'Konten & Marketing' },
    { label: 'CMS', icon: 'i-lucide-newspaper', to: '/content', phase: 2 },
    { label: 'Notifikasi & Broadcast', icon: 'i-lucide-send', to: '/notifications', phase: 2 },

    { type: 'label', label: 'Sistem' },
    { label: 'User & Role', icon: 'i-lucide-shield-check', to: '/users', phase: 1 }
  ]

  return { items }
}
