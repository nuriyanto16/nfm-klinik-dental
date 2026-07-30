<script setup lang="ts">
import type { NotificationLog, NotificationTemplate, NotificationTemplateInput } from '~/types/api'

definePageMeta({ title: 'Notifikasi & Broadcast' })

const { data: templates, status, refresh, error } = useApiFetch<NotificationTemplate[]>('/notifications/templates')
const { data: logs, refresh: refreshLogs } = useApiFetch<NotificationLog[]>('/notifications/logs')

const CHANNEL_LABEL: Record<string, string> = { wa: 'WhatsApp', push: 'Push Notification', email: 'Email' }
const CHANNELS = [
  { label: 'WhatsApp', value: 'wa' },
  { label: 'Push Notification', value: 'push' },
  { label: 'Email', value: 'email' }
]

const tabs = [
  { label: 'Template', value: 'templates' },
  { label: 'Kirim Broadcast', value: 'send' },
  { label: 'Log Pengiriman', value: 'logs' }
]
const activeTab = ref('templates')

// --- Template CRUD ---
const showModal = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)
const formError = ref('')
const form = reactive<NotificationTemplateInput>({ code: '', channel: 'wa', subject: '', body: '' })
const subjectText = computed({
  get: () => form.subject ?? '',
  set: (v: string) => { form.subject = v || null }
})

function openCreate() {
  editingId.value = null
  form.code = ''
  form.channel = 'wa'
  form.subject = ''
  form.body = ''
  formError.value = ''
  showModal.value = true
}

function openEdit(template: NotificationTemplate) {
  editingId.value = template.id
  form.code = template.code
  form.channel = template.channel
  form.subject = template.subject ?? ''
  form.body = template.body
  formError.value = ''
  showModal.value = true
}

async function onSubmit() {
  if (!form.code || !form.body) {
    formError.value = 'Kode dan isi pesan wajib diisi.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    const payload = { ...form, subject: form.subject || null }
    if (editingId.value) {
      await apiPut(`/notifications/templates/${editingId.value}`, payload as unknown as Record<string, unknown>)
    } else {
      await apiPost('/notifications/templates', payload as unknown as Record<string, unknown>)
    }
    showModal.value = false
    await refresh()
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}

async function onDelete(template: NotificationTemplate) {
  if (!confirm(`Hapus template "${template.code}"?`)) return
  try {
    await apiDelete(`/notifications/templates/${template.id}`)
    await refresh()
  } catch (err) {
    alert(apiErrorMessage(err))
  }
}

// --- Send broadcast (simulated — no 3rd-party WA gateway wired up yet) ---
const sendForm = reactive({ templateCode: '', recipient: '' })
const sending = ref(false)
const sendError = ref('')
const sendSuccess = ref(false)

async function onSend() {
  if (!sendForm.templateCode || !sendForm.recipient) {
    sendError.value = 'Template dan penerima wajib diisi.'
    return
  }
  sending.value = true
  sendError.value = ''
  sendSuccess.value = false
  try {
    await apiPost('/notifications/send', sendForm as unknown as Record<string, unknown>)
    sendSuccess.value = true
    sendForm.recipient = ''
    await refreshLogs()
  } catch (err) {
    sendError.value = apiErrorMessage(err)
  } finally {
    sending.value = false
  }
}
</script>

<template>
  <div class="p-4 space-y-4 w-full max-w-none">
    <div>
      <h1 class="text-xl font-semibold">
        Notifikasi & Broadcast
      </h1>
      <p class="text-sm text-muted">
        Kelola template pesan dan lihat log pengiriman. Pengiriman WA/push nyata menunggu integrasi gateway pihak ketiga — untuk sekarang, "kirim" langsung tercatat sebagai terkirim di log.
      </p>
    </div>

    <UAlert
      v-if="error"
      color="error"
      variant="subtle"
      icon="i-lucide-alert-triangle"
      title="Gagal memuat data"
      :description="`core-api belum bisa dihubungi: ${error.message}`"
    />

    <UTabs
      v-model="activeTab"
      :items="tabs"
    >
      <template #content="{ item }">
        <div
          v-if="item.value === 'templates'"
          class="space-y-4 pt-4"
        >
          <div class="flex justify-end">
            <UButton
              icon="i-lucide-plus"
              label="Tambah Template"
              @click="openCreate"
            />
          </div>
          <UCard :ui="{ body: 'p-0 sm:p-0' }">
            <SkeletonTableSkeleton
              v-if="status === 'pending'"
              :columns="4"
            />
            <UTable
              v-else
              :data="templates ?? []"
              :columns="[
                { accessorKey: 'code', header: 'Kode' },
                { accessorKey: 'channel', header: 'Channel' },
                { accessorKey: 'body', header: 'Isi Pesan' },
                { id: 'actions', header: '' }
              ]"
            >
              <template #channel-cell="{ row }">
                <UBadge
                  color="primary"
                  variant="subtle"
                >
                  {{ CHANNEL_LABEL[row.original.channel] ?? row.original.channel }}
                </UBadge>
              </template>
              <template #body-cell="{ row }">
                <span class="line-clamp-1">{{ row.original.body }}</span>
              </template>
              <template #actions-cell="{ row }">
                <div class="flex justify-end gap-1">
                  <UButton
                    icon="i-lucide-pencil"
                    size="xs"
                    color="neutral"
                    variant="ghost"
                    @click="openEdit(row.original)"
                  />
                  <UButton
                    icon="i-lucide-trash-2"
                    size="xs"
                    color="error"
                    variant="ghost"
                    @click="onDelete(row.original)"
                  />
                </div>
              </template>
            </UTable>
          </UCard>
        </div>

        <div
          v-else-if="item.value === 'send'"
          class="pt-4 max-w-md"
        >
          <UCard>
            <template #header>
              <h2 class="font-medium">
                Kirim Notifikasi
              </h2>
            </template>
            <form
              class="space-y-4"
              @submit.prevent="onSend"
            >
              <UFormField
                label="Template"
                required
              >
                <USelect
                  v-model="sendForm.templateCode"
                  :items="(templates ?? []).map(t => ({ label: `${t.code} (${CHANNEL_LABEL[t.channel]})`, value: t.code }))"
                  class="w-full"
                />
              </UFormField>
              <UFormField
                label="Penerima (No. HP / Email)"
                required
              >
                <UInput
                  v-model="sendForm.recipient"
                  class="w-full"
                />
              </UFormField>
              <UAlert
                v-if="sendSuccess"
                color="success"
                variant="subtle"
                description="Notifikasi berhasil dikirim (tercatat di log)."
              />
              <UAlert
                v-if="sendError"
                color="error"
                variant="subtle"
                :description="sendError"
              />
              <UButton
                type="submit"
                icon="i-lucide-send"
                label="Kirim"
                :loading="sending"
              />
            </form>
          </UCard>
        </div>

        <div
          v-else-if="item.value === 'logs'"
          class="pt-4"
        >
          <UCard :ui="{ body: 'p-0 sm:p-0' }">
            <SkeletonTableSkeleton
              v-if="!logs"
              :columns="5"
            />
            <UTable
              v-else
              :data="logs"
              :columns="[
                { accessorKey: 'sentAt', header: 'Waktu' },
                { accessorKey: 'templateCode', header: 'Template' },
                { accessorKey: 'channel', header: 'Channel' },
                { accessorKey: 'recipient', header: 'Penerima' },
                { accessorKey: 'status', header: 'Status' }
              ]"
            >
              <template #sentAt-cell="{ row }">
                {{ formatDateTime(row.original.sentAt) }}
              </template>
              <template #channel-cell="{ row }">
                {{ CHANNEL_LABEL[row.original.channel] ?? row.original.channel }}
              </template>
              <template #status-cell="{ row }">
                <UBadge
                  :color="row.original.status === 'sent' ? 'success' : 'error'"
                  variant="subtle"
                >
                  {{ row.original.status === 'sent' ? 'Terkirim' : 'Gagal' }}
                </UBadge>
              </template>
            </UTable>
          </UCard>
        </div>
      </template>
    </UTabs>

    <UModal
      v-model:open="showModal"
      :title="editingId ? 'Edit Template' : 'Tambah Template'"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="onSubmit"
        >
          <UFormField
            label="Kode"
            required
          >
            <UInput
              v-model="form.code"
              class="w-full"
              placeholder="reminder_h1"
              :disabled="!!editingId"
            />
          </UFormField>
          <UFormField
            label="Channel"
            required
          >
            <USelect
              v-model="form.channel"
              :items="CHANNELS"
              class="w-full"
            />
          </UFormField>
          <UFormField
            v-if="form.channel === 'email'"
            label="Subjek"
          >
            <UInput
              v-model="subjectText"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Isi Pesan"
            required
          >
            <UTextarea
              v-model="form.body"
              class="w-full"
              :rows="4"
            />
          </UFormField>
          <UAlert
            v-if="formError"
            color="error"
            variant="subtle"
            :description="formError"
          />
        </form>
      </template>
      <template #footer>
        <div class="flex justify-end gap-2 w-full">
          <UButton
            color="neutral"
            variant="ghost"
            label="Batal"
            @click="showModal = false"
          />
          <UButton
            :loading="saving"
            label="Simpan"
            @click="onSubmit"
          />
        </div>
      </template>
    </UModal>
  </div>
</template>
