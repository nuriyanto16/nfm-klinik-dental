<script setup lang="ts">
import type { Article, ArticleCategory, DoctorDetail, Promo, Testimonial, Video } from '~/types/api'

definePageMeta({ title: 'CMS & Konten' })

const { data: apiArticles, refresh: refreshArticles } = useApiFetch<Article[]>('/content/articles')
const { data: apiCategories, refresh: refreshCategories } = useApiFetch<ArticleCategory[]>('/content/article-categories')
const { data: apiPromos, refresh: refreshPromos } = useApiFetch<Promo[]>('/content/promos')
const { data: apiTestimonials, refresh: refreshTestimonials } = useApiFetch<Testimonial[]>('/content/testimonials')
const { data: apiVideos, refresh: refreshVideos } = useApiFetch<Video[]>('/content/videos')

const initialArticles: Article[] = [
  { id: 'art-1', categoryId: 'cat-1', categoryName: 'Ortodonti', title: 'Kapan Harus Behel Gigi? Kenali 5 Tanda Utama Ini!', slug: 'kapan-harus-behel', coverImageUrl: 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800&auto=format&fit=crop&q=80', body: 'Gigi berjejal, gigitan tidak rata, atau rahang tidak simetris adalah tanda utama Anda perlu berkonsultasi dengan dokter spesialis ortodonti di Nina Dental Care.', publishedAt: '2026-07-28T10:00:00Z', createdAt: '2026-07-28T10:00:00Z' },
  { id: 'art-2', categoryId: 'cat-2', categoryName: 'Tips Kesehatan', title: '5 Kebiasaan Sehari-hari yang Tanpa Disadari Merusak Enamel Gigi', slug: '5-kebiasaan-perusak-enamel', coverImageUrl: 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800&auto=format&fit=crop&q=80', body: 'Minum soda berlebihan, menggigit kuku, serta menyikat gigi terlalu keras dapat menipiskan enamel gigi sehingga gigi menjadi sensitif dan mudah berlubang.', publishedAt: '2026-07-25T10:00:00Z', createdAt: '2026-07-25T10:00:00Z' },
  { id: 'art-3', categoryId: 'cat-3', categoryName: 'Nina Kidz', title: 'Program Nina Kidz: Menjaga Gigi Anak Sehat & Bebas Karies Sejak Dini', slug: 'program-nina-kidz', coverImageUrl: 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=800&auto=format&fit=crop&q=80', body: 'Nina Kidz adalah program pemeriksaan gigi anak dengan suasana ramah dan menyenangkan, melatih si kecil agar tidak takut berkunjung ke dokter gigi.', publishedAt: '2026-07-23T10:00:00Z', createdAt: '2026-07-23T10:00:00Z' },
  { id: 'art-4', categoryId: 'cat-1', categoryName: 'Perawatan Gigi', title: 'Prosedur Bleaching Gigi Instant: Rahasia Senyum Cerah Cemerlang', slug: 'prosedur-bleaching-gigi', coverImageUrl: 'https://images.unsplash.com/photo-1571772996211-2f02c9727629?w=800&auto=format&fit=crop&q=80', body: 'Bleaching gigi instant 60 menit dengan teknologi sinar LED aman mencerahkan warna gigi hingga beberapa tingkat lebih putih alami.', publishedAt: '2026-07-20T10:00:00Z', createdAt: '2026-07-20T10:00:00Z' }
]

const initialPromos: Promo[] = [
  { id: 'pro-1', title: 'Promo Scaling 6-in-1 Super Clean', bannerImageUrl: 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800&auto=format&fit=crop&q=80', description: 'Paket scaling lengkap pembersihan karang gigi + polishing + fluoridasi hanya Rp199.000.', startsAt: '2026-07-01T00:00:00Z', endsAt: '2026-08-31T23:59:59Z', isActive: true, discountType: 'fixed', discountValue: 50000 },
  { id: 'pro-2', title: 'Diskon Pemasangan Behel Metal 10%', bannerImageUrl: 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800&auto=format&fit=crop&q=80', description: 'Diskon 10% untuk pemasangan behel metal konvensional via aplikasi mobile.', startsAt: '2026-07-05T00:00:00Z', endsAt: '2026-08-15T23:59:59Z', isActive: true, discountType: 'percentage', discountValue: 10 }
]

const initialTestimonials: Testimonial[] = [
  { id: 'tes-1', patientName: 'Budi Santoso', doctorName: 'drg. Friski Raisis, Sp.Ort', photoUrl: null, rating: 5, quote: 'Pelayanan ramah, klinik sangat bersih dan dokter komunikatif! Tambal giginya rapi dan gak sakit sama sekali.' },
  { id: 'tes-2', patientName: 'Dewi Lestari', doctorName: 'drg. Siti Aminah', photoUrl: null, rating: 5, quote: 'Dokter anak di Nina Kidz sangat sabar. Anak saya jadi berani dan ceria saat diperiksa gigi!' }
]

const initialVideos: Video[] = [
  { id: 'vid-1', title: 'Grand Opening Nina Dental Care Soreang & Baleendah', videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', thumbnailUrl: 'https://images.unsplash.com/photo-1629909615184-74f495363b67?w=800&auto=format&fit=crop&q=80', publishedAt: '2026-07-15T12:00:00Z' },
  { id: 'vid-2', title: 'Edukasi: Cara Sikat Gigi yang Benar Mencegah Karang', videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', thumbnailUrl: 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800&auto=format&fit=crop&q=80', publishedAt: '2026-07-22T08:30:00Z' }
]

const articles = ref<Article[]>([...initialArticles])
const promos = ref<Promo[]>([...initialPromos])
const testimonials = ref<Testimonial[]>([...initialTestimonials])
const videos = ref<Video[]>([...initialVideos])

watch(apiArticles, val => { if (val?.length) articles.value = [...val] }, { immediate: true })
watch(apiPromos, val => { if (val?.length) promos.value = [...val] }, { immediate: true })
watch(apiTestimonials, val => { if (val?.length) testimonials.value = [...val] }, { immediate: true })
watch(apiVideos, val => { if (val?.length) videos.value = [...val] }, { immediate: true })

const activeTab = ref('articles')
const tabs = [
  { label: 'Artikel & Edukasi', value: 'articles' },
  { label: 'Promo Mobile', value: 'promos' },
  { label: 'Testimoni Pasien', value: 'testimonials' },
  { label: 'Video Youtube', value: 'videos' }
]

// --- Article CRUD ---
const showArticleModal = ref(false)
const editingArticleId = ref<string | null>(null)
const articleForm = reactive({ title: '', categoryName: 'Ortodonti', coverImageUrl: '', body: '' })

function openCreateArticle() {
  editingArticleId.value = null
  articleForm.title = ''
  articleForm.categoryName = 'Ortodonti'
  articleForm.coverImageUrl = ''
  articleForm.body = ''
  showArticleModal.value = true
}

function openEditArticle(art: Article) {
  editingArticleId.value = art.id
  articleForm.title = art.title
  articleForm.categoryName = art.categoryName ?? 'Umum'
  articleForm.coverImageUrl = art.coverImageUrl ?? ''
  articleForm.body = art.body
  showArticleModal.value = true
}

function saveArticle() {
  if (!articleForm.title.trim()) return
  if (editingArticleId.value) {
    const idx = articles.value.findIndex(a => a.id === editingArticleId.value)
    if (idx !== -1) {
      articles.value[idx] = {
        ...articles.value[idx],
        title: articleForm.title,
        categoryName: articleForm.categoryName,
        coverImageUrl: articleForm.coverImageUrl || null,
        body: articleForm.body
      }
    }
  } else {
    const newArt: Article = {
      id: `art-${Date.now()}`,
      categoryId: 'cat-1',
      categoryName: articleForm.categoryName,
      title: articleForm.title,
      slug: articleForm.title.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
      coverImageUrl: articleForm.coverImageUrl || 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800',
      body: articleForm.body,
      publishedAt: new Date().toISOString(),
      createdAt: new Date().toISOString()
    }
    articles.value.unshift(newArt)
  }
  showArticleModal.value = false
}

function deleteArticle(art: Article) {
  if (confirm(`Arsipkan/Hapus artikel "${art.title}"?`)) {
    articles.value = articles.value.filter(a => a.id !== art.id)
  }
}

// --- Promo CRUD ---
const showPromoModal = ref(false)
const editingPromoId = ref<string | null>(null)
const promoForm = reactive({ title: '', bannerImageUrl: '', description: '', discountValue: 50000, isActive: true })

function openCreatePromo() {
  editingPromoId.value = null
  promoForm.title = ''
  promoForm.bannerImageUrl = ''
  promoForm.description = ''
  promoForm.discountValue = 50000
  promoForm.isActive = true
  showPromoModal.value = true
}

function savePromo() {
  if (!promoForm.title.trim()) return
  if (editingPromoId.value) {
    const idx = promos.value.findIndex(p => p.id === editingPromoId.value)
    if (idx !== -1) {
      promos.value[idx] = {
        ...promos.value[idx],
        title: promoForm.title,
        bannerImageUrl: promoForm.bannerImageUrl || null,
        description: promoForm.description,
        discountValue: promoForm.discountValue,
        isActive: promoForm.isActive
      }
    }
  } else {
    const newPro: Promo = {
      id: `pro-${Date.now()}`,
      title: promoForm.title,
      bannerImageUrl: promoForm.bannerImageUrl || 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800',
      description: promoForm.description,
      startsAt: new Date().toISOString(),
      endsAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      isActive: promoForm.isActive,
      discountType: 'fixed',
      discountValue: promoForm.discountValue
    }
    promos.value.unshift(newPro)
  }
  showPromoModal.value = false
}

function deletePromo(p: Promo) {
  if (confirm(`Hapus promo "${p.title}"?`)) {
    promos.value = promos.value.filter(item => item.id !== p.id)
  }
}
</script>

<template>
  <div class="p-6 space-y-6 w-full max-w-none">
    <div class="flex items-center justify-between flex-wrap gap-4">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
          CMS & Konten Aplikasi Mobile
        </h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
          Kelola artikel edukasi, banner promo, testimoni pasien, dan video tutorial yang tampil di aplikasi mobile.
        </p>
      </div>
    </div>

    <!-- Tabs Bar -->
    <div class="flex items-center gap-2 border-b border-gray-200 dark:border-gray-700 pb-2">
      <UButton
        v-for="t in tabs"
        :key="t.value"
        :variant="activeTab === t.value ? 'solid' : 'ghost'"
        :color="activeTab === t.value ? 'primary' : 'gray'"
        size="sm"
        :label="t.label"
        @click="activeTab = t.value"
      />
    </div>

    <!-- Artikel Tab -->
    <div v-if="activeTab === 'articles'" class="space-y-4">
      <div class="flex justify-between items-center">
        <h2 class="text-lg font-bold text-gray-900 dark:text-white">Daftar Artikel & Edukasi Gigi</h2>
        <UButton icon="i-lucide-plus" label="Tambah Artikel" @click="openCreateArticle" />
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <UCard v-for="art in articles" :key="art.id" class="bg-white dark:bg-gray-800 flex flex-col justify-between">
          <div class="space-y-3">
            <img
              :src="art.coverImageUrl || 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800'"
              class="w-full h-40 object-cover rounded-lg"
            >
            <div class="flex items-center justify-between">
              <UBadge color="gray" variant="subtle" size="xs">{{ art.categoryName }}</UBadge>
              <span class="text-[11px] text-gray-400">Tersinkron Mobile</span>
            </div>
            <h3 class="font-bold text-sm text-gray-900 dark:text-white line-clamp-2">{{ art.title }}</h3>
            <p class="text-xs text-gray-500 line-clamp-2">{{ art.body }}</p>
          </div>
          <div class="flex items-center justify-end gap-2 pt-4 border-t border-gray-100 dark:border-gray-700 mt-4">
            <UButton size="xs" color="gray" variant="ghost" icon="i-lucide-edit-2" label="Edit" @click="openEditArticle(art)" />
            <UButton size="xs" color="red" variant="ghost" icon="i-lucide-trash-2" label="Hapus" @click="deleteArticle(art)" />
          </div>
        </UCard>
      </div>
    </div>

    <!-- Promo Tab -->
    <div v-if="activeTab === 'promos'" class="space-y-4">
      <div class="flex justify-between items-center">
        <h2 class="text-lg font-bold text-gray-900 dark:text-white">Daftar Banner Promo Mobile</h2>
        <UButton icon="i-lucide-plus" label="Tambah Promo" @click="openCreatePromo" />
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <UCard v-for="pro in promos" :key="pro.id" class="bg-white dark:bg-gray-800">
          <div class="flex flex-col sm:flex-row gap-4">
            <img :src="pro.bannerImageUrl || 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800'" class="w-full sm:w-40 h-32 object-cover rounded-lg">
            <div class="space-y-2 flex-1">
              <div class="flex items-center justify-between">
                <UBadge :color="pro.isActive ? 'green' : 'gray'" variant="soft" size="xs">{{ pro.isActive ? 'Aktif Tayang' : 'Non-aktif' }}</UBadge>
                <span class="font-bold text-xs text-primary">Hemat {{ formatIDR(pro.discountValue || 0) }}</span>
              </div>
              <h3 class="font-bold text-sm text-gray-900 dark:text-white">{{ pro.title }}</h3>
              <p class="text-xs text-gray-500">{{ pro.description }}</p>
              <div class="flex items-center justify-end gap-2 pt-2">
                <UButton size="xs" color="red" variant="ghost" icon="i-lucide-trash-2" label="Hapus" @click="deletePromo(pro)" />
              </div>
            </div>
          </div>
        </UCard>
      </div>
    </div>

    <!-- Testimoni Tab -->
    <div v-if="activeTab === 'testimonials'" class="space-y-4">
      <h2 class="text-lg font-bold text-gray-900 dark:text-white">Testimoni Ulasan Pasien</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <UCard v-for="tes in testimonials" :key="tes.id" class="bg-white dark:bg-gray-800 space-y-2">
          <div class="flex items-center justify-between">
            <span class="font-bold text-sm text-gray-900 dark:text-white">{{ tes.patientName }}</span>
            <div class="flex text-amber-400">
              <UIcon v-for="i in tes.rating" :key="i" name="i-lucide-star" class="w-4 h-4 fill-amber-400" />
            </div>
          </div>
          <p class="text-xs italic text-gray-600 dark:text-gray-300">"{{ tes.quote }}"</p>
          <span class="text-[11px] text-gray-400 block pt-1">Dokter: {{ tes.doctorName }}</span>
        </UCard>
      </div>
    </div>

    <!-- Video Tab -->
    <div v-if="activeTab === 'videos'" class="space-y-4">
      <h2 class="text-lg font-bold text-gray-900 dark:text-white">Video Edukasi Youtube</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <UCard v-for="vid in videos" :key="vid.id" class="bg-white dark:bg-gray-800 space-y-2">
          <img :src="vid.thumbnailUrl || 'https://images.unsplash.com/photo-1629909615184-74f495363b67?w=800'" class="w-full h-44 object-cover rounded-lg">
          <h3 class="font-bold text-sm text-gray-900 dark:text-white">{{ vid.title }}</h3>
          <a :href="vid.videoUrl" target="_blank" class="text-xs text-primary flex items-center gap-1 font-medium">
            <UIcon name="i-lucide-external-link" class="w-3.5 h-3.5" /> Buka Video
          </a>
        </UCard>
      </div>
    </div>

    <!-- Article Modal -->
    <UModal v-model="showArticleModal">
      <UCard class="bg-white dark:bg-gray-800">
        <template #header>
          <h3 class="font-bold text-gray-900 dark:text-white">{{ editingArticleId ? 'Edit Artikel' : 'Tambah Artikel Baru' }}</h3>
        </template>
        <div class="space-y-4">
          <div>
            <label class="block text-xs font-semibold mb-1">Judul Artikel</label>
            <UInput v-model="articleForm.title" placeholder="mis. Kapan Harus Behel Gigi?" />
          </div>
          <div>
            <label class="block text-xs font-semibold mb-1">Kategori</label>
            <select v-model="articleForm.categoryName" class="w-full p-2 text-xs border rounded bg-white dark:bg-gray-800">
              <option value="Ortodonti">Ortodonti</option>
              <option value="Tips Kesehatan">Tips Kesehatan</option>
              <option value="Nina Kidz">Nina Kidz</option>
              <option value="Perawatan Gigi">Perawatan Gigi</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-semibold mb-1">URL Cover Foto</label>
            <UInput v-model="articleForm.coverImageUrl" placeholder="https://images.unsplash.com/..." />
          </div>
          <div>
            <label class="block text-xs font-semibold mb-1">Isi Konten Artikel</label>
            <UTextarea v-model="articleForm.body" rows="4" placeholder="Tuliskan isi artikel..." />
          </div>
        </div>
        <template #footer>
          <div class="flex justify-end gap-2">
            <UButton label="Batal" color="gray" variant="ghost" @click="showArticleModal = false" />
            <UButton label="Simpan Artikel" color="primary" @click="saveArticle" />
          </div>
        </template>
      </UCard>
    </UModal>

    <!-- Promo Modal -->
    <UModal v-model="showPromoModal">
      <UCard class="bg-white dark:bg-gray-800">
        <template #header>
          <h3 class="font-bold text-gray-900 dark:text-white">{{ editingPromoId ? 'Edit Promo' : 'Tambah Banner Promo' }}</h3>
        </template>
        <div class="space-y-4">
          <div>
            <label class="block text-xs font-semibold mb-1">Judul Promo</label>
            <UInput v-model="promoForm.title" placeholder="mis. Diskon Scaling 6-in-1" />
          </div>
          <div>
            <label class="block text-xs font-semibold mb-1">Nilai Potongan (Rp)</label>
            <UInput v-model.number="promoForm.discountValue" type="number" step="10000" />
          </div>
          <div>
            <label class="block text-xs font-semibold mb-1">URL Gambar Banner</label>
            <UInput v-model="promoForm.bannerImageUrl" placeholder="https://images.unsplash.com/..." />
          </div>
          <div>
            <label class="block text-xs font-semibold mb-1">Keterangan Promo</label>
            <UTextarea v-model="promoForm.description" rows="2" placeholder="Syarat & ketentuan promo..." />
          </div>
        </div>
        <template #footer>
          <div class="flex justify-end gap-2">
            <UButton label="Batal" color="gray" variant="ghost" @click="showPromoModal = false" />
            <UButton label="Simpan Promo" color="primary" @click="savePromo" />
          </div>
        </template>
      </UCard>
    </UModal>
  </div>
</template>
