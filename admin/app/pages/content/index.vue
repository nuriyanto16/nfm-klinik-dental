<script setup lang="ts">
import type { Article, ArticleCategory, DoctorDetail, Promo, Testimonial, Video } from '~/types/api'

definePageMeta({ title: 'CMS' })

const { data: articles, status: articlesStatus, refresh: refreshArticles } = useApiFetch<Article[]>('/content/articles')
const { data: categories, refresh: refreshCategories } = useApiFetch<ArticleCategory[]>('/content/article-categories')
const { data: promos, status: promosStatus, refresh: refreshPromos } = useApiFetch<Promo[]>('/content/promos')
const { data: testimonials, status: testimonialsStatus, refresh: refreshTestimonials } = useApiFetch<Testimonial[]>('/content/testimonials')
const { data: videos, status: videosStatus, refresh: refreshVideos } = useApiFetch<Video[]>('/content/videos')
const { data: doctorsAdmin } = useApiFetch<DoctorDetail[]>('/doctors/admin')

const tabs = [
  { label: 'Artikel', value: 'articles', slot: 'articles' as const },
  { label: 'Promo', value: 'promos', slot: 'promos' as const },
  { label: 'Testimoni', value: 'testimonials', slot: 'testimonials' as const },
  { label: 'Video', value: 'videos', slot: 'videos' as const }
]

// --- Articles ---
const showArticleModal = ref(false)
const savingArticle = ref(false)
const articleError = ref('')
const newCategoryName = ref('')
const articleForm = reactive({ categoryId: null as string | null, title: '', slug: '', coverImageUrl: '', body: '', published: false })

function slugify(title: string) {
  return title.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')
}
watch(() => articleForm.title, (title) => {
  articleForm.slug = slugify(title)
})

function openCreateArticle() {
  articleForm.categoryId = null
  articleForm.title = ''
  articleForm.slug = ''
  articleForm.coverImageUrl = ''
  articleForm.body = ''
  articleForm.published = false
  articleError.value = ''
  showArticleModal.value = true
}
async function addCategory() {
  if (!newCategoryName.value) return
  await apiPost('/content/article-categories', { name: newCategoryName.value })
  newCategoryName.value = ''
  await refreshCategories()
}
async function saveArticle() {
  if (!articleForm.title) {
    articleError.value = 'Judul wajib diisi.'
    return
  }
  savingArticle.value = true
  try {
    await apiPost('/content/articles', { ...articleForm, coverImageUrl: articleForm.coverImageUrl || null })
    showArticleModal.value = false
    await refreshArticles()
  } catch (err) {
    articleError.value = apiErrorMessage(err)
  } finally {
    savingArticle.value = false
  }
}
async function deleteArticle(a: Article) {
  if (!confirm(`Hapus artikel "${a.title}"?`)) return
  await apiDelete(`/content/articles/${a.id}`)
  await refreshArticles()
}

// --- Promos ---
const showPromoModal = ref(false)
const savingPromo = ref(false)
const promoError = ref('')
const promoForm = reactive({ title: '', bannerImageUrl: '', description: '', startsAt: '', endsAt: '', isActive: true })

function openCreatePromo() {
  promoForm.title = ''
  promoForm.bannerImageUrl = ''
  promoForm.description = ''
  promoForm.startsAt = ''
  promoForm.endsAt = ''
  promoForm.isActive = true
  promoError.value = ''
  showPromoModal.value = true
}
async function savePromo() {
  if (!promoForm.title) {
    promoError.value = 'Judul wajib diisi.'
    return
  }
  savingPromo.value = true
  try {
    await apiPost('/content/promos', {
      ...promoForm,
      bannerImageUrl: promoForm.bannerImageUrl || null,
      description: promoForm.description || null,
      startsAt: promoForm.startsAt || null,
      endsAt: promoForm.endsAt || null
    })
    showPromoModal.value = false
    await refreshPromos()
  } catch (err) {
    promoError.value = apiErrorMessage(err)
  } finally {
    savingPromo.value = false
  }
}
async function deletePromo(p: Promo) {
  if (!confirm(`Hapus promo "${p.title}"?`)) return
  await apiDelete(`/content/promos/${p.id}`)
  await refreshPromos()
}

// --- Testimonials ---
const showTestimonialModal = ref(false)
const savingTestimonial = ref(false)
const testimonialError = ref('')
const testimonialForm = reactive({ patientName: '', staffId: null as string | null, photoUrl: '', rating: 5, quote: '' })

function openCreateTestimonial() {
  testimonialForm.patientName = ''
  testimonialForm.staffId = null
  testimonialForm.photoUrl = ''
  testimonialForm.rating = 5
  testimonialForm.quote = ''
  testimonialError.value = ''
  showTestimonialModal.value = true
}
async function saveTestimonial() {
  if (!testimonialForm.patientName || !testimonialForm.quote) {
    testimonialError.value = 'Nama pasien dan kutipan wajib diisi.'
    return
  }
  savingTestimonial.value = true
  try {
    await apiPost('/content/testimonials', { ...testimonialForm, photoUrl: testimonialForm.photoUrl || null })
    showTestimonialModal.value = false
    await refreshTestimonials()
  } catch (err) {
    testimonialError.value = apiErrorMessage(err)
  } finally {
    savingTestimonial.value = false
  }
}
async function deleteTestimonial(t: Testimonial) {
  if (!confirm(`Hapus testimoni dari "${t.patientName}"?`)) return
  await apiDelete(`/content/testimonials/${t.id}`)
  await refreshTestimonials()
}

// --- Videos ---
const showVideoModal = ref(false)
const savingVideo = ref(false)
const videoError = ref('')
const videoForm = reactive({ title: '', videoUrl: '', thumbnailUrl: '', published: true })

function openCreateVideo() {
  videoForm.title = ''
  videoForm.videoUrl = ''
  videoForm.thumbnailUrl = ''
  videoForm.published = true
  videoError.value = ''
  showVideoModal.value = true
}
async function saveVideo() {
  if (!videoForm.title || !videoForm.videoUrl) {
    videoError.value = 'Judul dan URL video wajib diisi.'
    return
  }
  savingVideo.value = true
  try {
    await apiPost('/content/videos', { ...videoForm, thumbnailUrl: videoForm.thumbnailUrl || null })
    showVideoModal.value = false
    await refreshVideos()
  } catch (err) {
    videoError.value = apiErrorMessage(err)
  } finally {
    savingVideo.value = false
  }
}
async function deleteVideo(v: Video) {
  if (!confirm(`Hapus video "${v.title}"?`)) return
  await apiDelete(`/content/videos/${v.id}`)
  await refreshVideos()
}
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div>
      <h1 class="text-xl font-semibold">
        CMS
      </h1>
      <p class="text-sm text-muted">
        Artikel edukasi, promo, testimoni, dan video untuk aplikasi mobile. Gambar/video pakai URL langsung (belum ada upload — lihat docs/architecture.md).
      </p>
    </div>

    <UTabs
      :items="tabs"
      class="w-full"
    >
      <template #articles>
        <div class="space-y-4 pt-4">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <UInput
                v-model="newCategoryName"
                placeholder="Kategori baru..."
                size="sm"
              />
              <UButton
                size="sm"
                variant="soft"
                label="Tambah Kategori"
                @click="addCategory"
              />
            </div>
            <UButton
              icon="i-lucide-plus"
              label="Tulis Artikel"
              @click="openCreateArticle"
            />
          </div>
          <SkeletonTableSkeleton
            v-if="articlesStatus === 'pending'"
            :columns="4"
          />
          <UTable
            v-else
            :data="articles ?? []"
            :columns="[
              { accessorKey: 'title', header: 'Judul' },
              { accessorKey: 'categoryName', header: 'Kategori' },
              { accessorKey: 'publishedAt', header: 'Status' },
              { id: 'actions', header: '' }
            ]"
          >
            <template #publishedAt-cell="{ row }">
              <UBadge
                :color="row.original.publishedAt ? 'success' : 'neutral'"
                variant="subtle"
              >
                {{ row.original.publishedAt ? 'Terbit' : 'Draft' }}
              </UBadge>
            </template>
            <template #actions-cell="{ row }">
              <UButton
                icon="i-lucide-trash-2"
                size="xs"
                color="error"
                variant="ghost"
                @click="deleteArticle(row.original)"
              />
            </template>
          </UTable>
        </div>
      </template>

      <template #promos>
        <div class="space-y-4 pt-4">
          <div class="flex justify-end">
            <UButton
              icon="i-lucide-plus"
              label="Tambah Promo"
              @click="openCreatePromo"
            />
          </div>
          <SkeletonTableSkeleton
            v-if="promosStatus === 'pending'"
            :columns="4"
          />
          <UTable
            v-else
            :data="promos ?? []"
            :columns="[
              { accessorKey: 'title', header: 'Judul' },
              { accessorKey: 'startsAt', header: 'Periode' },
              { accessorKey: 'isActive', header: 'Status' },
              { id: 'actions', header: '' }
            ]"
          >
            <template #startsAt-cell="{ row }">
              <span v-if="row.original.startsAt && row.original.endsAt">
                {{ formatDateShort(row.original.startsAt.slice(0, 10)) }} – {{ formatDateShort(row.original.endsAt.slice(0, 10)) }}
              </span>
              <span v-else>—</span>
            </template>
            <template #isActive-cell="{ row }">
              <UBadge
                :color="row.original.isActive ? 'success' : 'neutral'"
                variant="subtle"
              >
                {{ row.original.isActive ? 'Aktif' : 'Nonaktif' }}
              </UBadge>
            </template>
            <template #actions-cell="{ row }">
              <UButton
                icon="i-lucide-trash-2"
                size="xs"
                color="error"
                variant="ghost"
                @click="deletePromo(row.original)"
              />
            </template>
          </UTable>
        </div>
      </template>

      <template #testimonials>
        <div class="space-y-4 pt-4">
          <div class="flex justify-end">
            <UButton
              icon="i-lucide-plus"
              label="Tambah Testimoni"
              @click="openCreateTestimonial"
            />
          </div>
          <SkeletonTableSkeleton
            v-if="testimonialsStatus === 'pending'"
            :columns="5"
          />
          <UTable
            v-else
            :data="testimonials ?? []"
            :columns="[
              { accessorKey: 'patientName', header: 'Pasien' },
              { accessorKey: 'doctorName', header: 'Dokter' },
              { accessorKey: 'rating', header: 'Rating' },
              { accessorKey: 'quote', header: 'Kutipan' },
              { id: 'actions', header: '' }
            ]"
          >
            <template #rating-cell="{ row }">
              {{ '★'.repeat(row.original.rating) }}
            </template>
            <template #quote-cell="{ row }">
              <span class="line-clamp-1">{{ row.original.quote }}</span>
            </template>
            <template #actions-cell="{ row }">
              <UButton
                icon="i-lucide-trash-2"
                size="xs"
                color="error"
                variant="ghost"
                @click="deleteTestimonial(row.original)"
              />
            </template>
          </UTable>
        </div>
      </template>

      <template #videos>
        <div class="space-y-4 pt-4">
          <div class="flex justify-end">
            <UButton
              icon="i-lucide-plus"
              label="Tambah Video"
              @click="openCreateVideo"
            />
          </div>
          <SkeletonTableSkeleton
            v-if="videosStatus === 'pending'"
            :columns="4"
          />
          <UTable
            v-else
            :data="videos ?? []"
            :columns="[
              { accessorKey: 'title', header: 'Judul' },
              { accessorKey: 'videoUrl', header: 'URL' },
              { accessorKey: 'publishedAt', header: 'Status' },
              { id: 'actions', header: '' }
            ]"
          >
            <template #publishedAt-cell="{ row }">
              <UBadge
                :color="row.original.publishedAt ? 'success' : 'neutral'"
                variant="subtle"
              >
                {{ row.original.publishedAt ? 'Terbit' : 'Draft' }}
              </UBadge>
            </template>
            <template #actions-cell="{ row }">
              <UButton
                icon="i-lucide-trash-2"
                size="xs"
                color="error"
                variant="ghost"
                @click="deleteVideo(row.original)"
              />
            </template>
          </UTable>
        </div>
      </template>
    </UTabs>

    <!-- Article modal -->
    <UModal
      v-model:open="showArticleModal"
      title="Tulis Artikel"
      :ui="{ content: 'max-w-2xl' }"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="saveArticle"
        >
          <UFormField
            label="Judul"
            required
          >
            <UInput
              v-model="articleForm.title"
              class="w-full"
            />
          </UFormField>
          <UFormField label="Slug">
            <UInput
              v-model="articleForm.slug"
              class="w-full"
            />
          </UFormField>
          <UFormField label="Kategori">
            <USelect
              v-model="articleForm.categoryId"
              :items="[{ label: 'Tanpa Kategori', value: null }, ...(categories ?? []).map(c => ({ label: c.name, value: c.id }))]"
              class="w-full"
            />
          </UFormField>
          <UFormField label="Cover Image URL">
            <UInput
              v-model="articleForm.coverImageUrl"
              class="w-full"
              placeholder="https://..."
            />
          </UFormField>
          <UFormField
            label="Isi Artikel"
            required
          >
            <UTextarea
              v-model="articleForm.body"
              class="w-full"
              :rows="6"
            />
          </UFormField>
          <UFormField label="Publikasikan Sekarang">
            <USwitch v-model="articleForm.published" />
          </UFormField>
          <UAlert
            v-if="articleError"
            color="error"
            variant="subtle"
            :description="articleError"
          />
        </form>
      </template>
      <template #footer>
        <div class="flex justify-end gap-2 w-full">
          <UButton
            color="neutral"
            variant="ghost"
            label="Batal"
            @click="showArticleModal = false"
          />
          <UButton
            :loading="savingArticle"
            label="Simpan"
            @click="saveArticle"
          />
        </div>
      </template>
    </UModal>

    <!-- Promo modal -->
    <UModal
      v-model:open="showPromoModal"
      title="Tambah Promo"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="savePromo"
        >
          <UFormField
            label="Judul"
            required
          >
            <UInput
              v-model="promoForm.title"
              class="w-full"
            />
          </UFormField>
          <UFormField label="Deskripsi">
            <UTextarea
              v-model="promoForm.description"
              class="w-full"
              :rows="3"
            />
          </UFormField>
          <UFormField label="Banner Image URL">
            <UInput
              v-model="promoForm.bannerImageUrl"
              class="w-full"
              placeholder="https://..."
            />
          </UFormField>
          <div class="grid grid-cols-2 gap-4">
            <UFormField label="Mulai">
              <UInput
                v-model="promoForm.startsAt"
                type="date"
                class="w-full"
              />
            </UFormField>
            <UFormField label="Berakhir">
              <UInput
                v-model="promoForm.endsAt"
                type="date"
                class="w-full"
              />
            </UFormField>
          </div>
          <UFormField label="Aktif">
            <USwitch v-model="promoForm.isActive" />
          </UFormField>
          <UAlert
            v-if="promoError"
            color="error"
            variant="subtle"
            :description="promoError"
          />
        </form>
      </template>
      <template #footer>
        <div class="flex justify-end gap-2 w-full">
          <UButton
            color="neutral"
            variant="ghost"
            label="Batal"
            @click="showPromoModal = false"
          />
          <UButton
            :loading="savingPromo"
            label="Simpan"
            @click="savePromo"
          />
        </div>
      </template>
    </UModal>

    <!-- Testimonial modal -->
    <UModal
      v-model:open="showTestimonialModal"
      title="Tambah Testimoni"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="saveTestimonial"
        >
          <UFormField
            label="Nama Pasien"
            required
          >
            <UInput
              v-model="testimonialForm.patientName"
              class="w-full"
            />
          </UFormField>
          <UFormField label="Dokter yang Melayani">
            <USelect
              v-model="testimonialForm.staffId"
              :items="[{ label: 'Tidak disebutkan', value: null }, ...(doctorsAdmin ?? []).map(d => ({ label: d.fullName, value: d.id }))]"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Rating"
            required
          >
            <USelect
              v-model="testimonialForm.rating"
              :items="[1, 2, 3, 4, 5].map(r => ({ label: '★'.repeat(r), value: r }))"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Kutipan"
            required
          >
            <UTextarea
              v-model="testimonialForm.quote"
              class="w-full"
              :rows="3"
            />
          </UFormField>
          <UAlert
            v-if="testimonialError"
            color="error"
            variant="subtle"
            :description="testimonialError"
          />
        </form>
      </template>
      <template #footer>
        <div class="flex justify-end gap-2 w-full">
          <UButton
            color="neutral"
            variant="ghost"
            label="Batal"
            @click="showTestimonialModal = false"
          />
          <UButton
            :loading="savingTestimonial"
            label="Simpan"
            @click="saveTestimonial"
          />
        </div>
      </template>
    </UModal>

    <!-- Video modal -->
    <UModal
      v-model:open="showVideoModal"
      title="Tambah Video"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="saveVideo"
        >
          <UFormField
            label="Judul"
            required
          >
            <UInput
              v-model="videoForm.title"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="URL Video"
            required
          >
            <UInput
              v-model="videoForm.videoUrl"
              class="w-full"
              placeholder="https://youtube.com/watch?v=..."
            />
          </UFormField>
          <UFormField label="Thumbnail URL">
            <UInput
              v-model="videoForm.thumbnailUrl"
              class="w-full"
            />
          </UFormField>
          <UFormField label="Publikasikan Sekarang">
            <USwitch v-model="videoForm.published" />
          </UFormField>
          <UAlert
            v-if="videoError"
            color="error"
            variant="subtle"
            :description="videoError"
          />
        </form>
      </template>
      <template #footer>
        <div class="flex justify-end gap-2 w-full">
          <UButton
            color="neutral"
            variant="ghost"
            label="Batal"
            @click="showVideoModal = false"
          />
          <UButton
            :loading="savingVideo"
            label="Simpan"
            @click="saveVideo"
          />
        </div>
      </template>
    </UModal>
  </UContainer>
</template>
