<template>
  <div class="space-y-4">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <h3 class="text-lg font-semibold text-gray-900">Documentos Anexados</h3>
      <button
        v-if="!readonly"
        @click="openUploadModal = true"
        class="inline-flex items-center gap-2 px-3 py-1.5 text-sm bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark transition-colors"
      >
        <PlusIcon class="h-4 w-4" />
        Anexar Documento
      </button>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-2 border-brand-primary border-t-transparent"></div>
    </div>

    <!-- Lista de anexos -->
    <div v-else-if="anexos.length > 0" class="grid grid-cols-1 md:grid-cols-2 gap-3">
      <div
        v-for="anexo in anexos"
        :key="anexo.id"
        class="bg-white border border-gray-200 rounded-lg p-4 flex items-start gap-4 hover:shadow-sm transition-shadow"
      >
        <!-- Icone do arquivo -->
        <div
          :class="[
            'flex-shrink-0 w-10 h-10 rounded-lg flex items-center justify-center',
            iconClass(anexo)
          ]"
        >
          <component :is="fileIcon(anexo)" class="h-5 w-5" />
        </div>

        <!-- Informacoes -->
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-900 truncate" :title="anexo.nome">
            {{ anexo.nome }}
          </p>
          <p class="text-xs text-gray-500">
            {{ anexo.tipoDocumentoLabel }}
            <span v-if="anexo.numeroDocumento"> - {{ anexo.numeroDocumento }}</span>
          </p>
          <p class="text-xs text-gray-400 mt-1">
            {{ anexo.tamanho }} - {{ formatDateTime(anexo.createdAt) }}
          </p>
        </div>

        <!-- Acoes -->
        <div class="flex items-center gap-1">
          <button
            v-if="anexo.urlPreview"
            @click="openPreview(anexo)"
            class="p-1.5 text-gray-400 hover:text-brand-primary rounded"
            title="Visualizar"
          >
            <EyeIcon class="h-4 w-4" />
          </button>
          <a
            v-if="anexo.urlDownload"
            :href="anexo.urlDownload"
            class="p-1.5 text-gray-400 hover:text-brand-primary rounded"
            title="Download"
          >
            <ArrowDownTrayIcon class="h-4 w-4" />
          </a>
          <button
            v-if="!readonly"
            @click="confirmRemove(anexo)"
            class="p-1.5 text-gray-400 hover:text-red-600 rounded"
            title="Remover"
          >
            <TrashIcon class="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- Estado vazio -->
    <div v-else class="bg-gray-50 rounded-lg p-8 text-center">
      <DocumentIcon class="h-12 w-12 mx-auto text-gray-300" />
      <p class="mt-2 text-sm text-gray-500">Nenhum documento anexado</p>
      <button
        v-if="!readonly"
        @click="openUploadModal = true"
        class="mt-4 text-sm text-brand-primary hover:underline"
      >
        Anexar primeiro documento
      </button>
    </div>

    <!-- Modal de Upload -->
    <IModal v-model="openUploadModal" title="Anexar Documento" size="md">
      <div class="space-y-4">
        <!-- Tipo de Documento -->
        <ISelect
          v-model="uploadForm.tipoDocumento"
          label="Tipo de Documento"
          :options="tiposDocumento"
          placeholder="Selecione o tipo"
          required
        />

        <!-- Numero do Documento -->
        <IInput
          v-model="uploadForm.numeroDocumento"
          label="Numero do Documento"
          placeholder="Ex: INV-2024-001"
        />

        <!-- Area de Upload -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">
            Arquivo <span class="text-red-500">*</span>
          </label>
          <div
            @drop.prevent="handleDrop"
            @dragover.prevent="isDragging = true"
            @dragleave.prevent="isDragging = false"
            :class="[
              'border-2 border-dashed rounded-lg p-6 text-center transition-colors cursor-pointer',
              isDragging ? 'border-brand-primary bg-brand-primary/5' : 'border-gray-300 hover:border-gray-400'
            ]"
            @click="triggerFileInput"
          >
            <input
              ref="fileInput"
              type="file"
              class="hidden"
              :accept="acceptedTypes"
              @change="handleFileSelect"
            />

            <div v-if="uploadForm.arquivo">
              <DocumentCheckIcon class="h-10 w-10 mx-auto text-green-500" />
              <p class="mt-2 text-sm font-medium text-gray-900">{{ uploadForm.arquivo.name }}</p>
              <p class="text-xs text-gray-500">{{ formatFileSize(uploadForm.arquivo.size) }}</p>
              <button
                @click.stop="uploadForm.arquivo = null"
                class="mt-2 text-xs text-red-600 hover:underline"
              >
                Remover
              </button>
            </div>
            <div v-else>
              <CloudArrowUpIcon class="h-10 w-10 mx-auto text-gray-400" />
              <p class="mt-2 text-sm text-gray-600">
                Arraste um arquivo ou <span class="text-brand-primary">clique para selecionar</span>
              </p>
              <p class="mt-1 text-xs text-gray-400">
                PDF, Word, Excel, XML ou imagens (max 10MB)
              </p>
            </div>
          </div>
        </div>

        <!-- Progresso -->
        <div v-if="uploading" class="space-y-2">
          <div class="flex items-center justify-between text-sm">
            <span class="text-gray-600">Enviando...</span>
            <span class="text-gray-900 font-medium">{{ uploadProgress }}%</span>
          </div>
          <div class="h-2 bg-gray-200 rounded-full overflow-hidden">
            <div
              class="h-full bg-brand-primary transition-all duration-300"
              :style="{ width: `${uploadProgress}%` }"
            ></div>
          </div>
        </div>
      </div>

      <template #footer>
        <button
          @click="closeUploadModal"
          :disabled="uploading"
          class="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 disabled:opacity-50"
        >
          Cancelar
        </button>
        <button
          @click="handleUpload"
          :disabled="uploading || !uploadForm.arquivo || !uploadForm.tipoDocumento"
          class="px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark disabled:opacity-50"
        >
          {{ uploading ? 'Enviando...' : 'Anexar' }}
        </button>
      </template>
    </IModal>

    <!-- Modal de Confirmacao -->
    <ConfirmationModal
      v-model="confirmModalOpen"
      title="Remover Documento"
      :message="`Tem certeza que deseja remover o documento '${anexoToRemove?.nome}'?`"
      confirm-text="Remover"
      type="danger"
      @confirm="handleRemove"
    />

    <!-- Modal de Preview -->
    <IModal v-model="previewModalOpen" :title="anexoParaPreview?.nome || 'Visualizar'" size="xl">
      <div class="min-h-[400px]">
        <img
          v-if="anexoParaPreview?.imagem"
          :src="anexoParaPreview.urlPreview"
          :alt="anexoParaPreview.nome"
          class="max-w-full max-h-[70vh] mx-auto"
        />
        <iframe
          v-else-if="anexoParaPreview?.pdf"
          :src="anexoParaPreview.urlPreview"
          class="w-full h-[70vh] border-0"
        ></iframe>
        <div v-else class="flex flex-col items-center justify-center h-64">
          <DocumentIcon class="h-16 w-16 text-gray-300" />
          <p class="mt-4 text-gray-500">Visualizacao nao disponivel para este tipo de arquivo</p>
          <a
            :href="anexoParaPreview?.urlDownload"
            class="mt-4 text-brand-primary hover:underline"
          >
            Fazer download
          </a>
        </div>
      </div>
    </IModal>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import {
  PlusIcon,
  DocumentIcon,
  EyeIcon,
  ArrowDownTrayIcon,
  TrashIcon,
  CloudArrowUpIcon,
  DocumentCheckIcon,
  DocumentTextIcon,
  PhotoIcon,
  TableCellsIcon
} from '@heroicons/vue/24/outline'
import IModal from '../IModal/IModal.vue'
import { IInput } from '../IInput'
import { ISelect } from '../ISelect'
import ConfirmationModal from '../ConfirmationModal/ConfirmationModal.vue'
import { formatDateTime } from '../../utils'
import { useNotifications } from '../../composables/useNotification'
import api from '../../lib/axios'

interface Anexo {
  id: number
  nome: string
  tipoDocumento: string
  tipoDocumentoLabel: string
  numeroDocumento: string | null
  contentType: string
  tamanho: string
  tamanhoBytes: number
  enviadoPor: { id: number; nome: string }
  createdAt: string
  urlDownload: string | null
  urlPreview: string | null
  imagem: boolean
  pdf: boolean
  extensao: string
}

interface TipoDocumento {
  value: string
  label: string
}

interface Props {
  baseUrl: string  // Ex: /processos_importacao/1/anexos
  readonly?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  readonly: false
})

const { success, error: showError } = useNotifications()

// State
const loading = ref(false)
const uploading = ref(false)
const uploadProgress = ref(0)
const isDragging = ref(false)
const openUploadModal = ref(false)
const confirmModalOpen = ref(false)
const previewModalOpen = ref(false)

const anexos = ref<Anexo[]>([])
const tiposDocumento = ref<TipoDocumento[]>([])
const anexoToRemove = ref<Anexo | null>(null)
const anexoParaPreview = ref<Anexo | null>(null)

const fileInput = ref<HTMLInputElement | null>(null)

const uploadForm = ref({
  tipoDocumento: '',
  numeroDocumento: '',
  arquivo: null as File | null
})

const acceptedTypes = '.pdf,.doc,.docx,.xls,.xlsx,.xml,.jpg,.jpeg,.png,.gif'

// Methods
async function fetchAnexos() {
  loading.value = true
  try {
    const response = await api.get(props.baseUrl)
    anexos.value = response.data.anexos
    tiposDocumento.value = response.data.tiposDocumento
  } catch (err) {
    showError('Erro ao carregar documentos')
  } finally {
    loading.value = false
  }
}

function triggerFileInput() {
  fileInput.value?.click()
}

function handleFileSelect(event: Event) {
  const input = event.target as HTMLInputElement
  if (input.files && input.files[0]) {
    uploadForm.value.arquivo = input.files[0]
  }
}

function handleDrop(event: DragEvent) {
  isDragging.value = false
  if (event.dataTransfer?.files && event.dataTransfer.files[0]) {
    uploadForm.value.arquivo = event.dataTransfer.files[0]
  }
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} bytes`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`
}

async function handleUpload() {
  if (!uploadForm.value.arquivo || !uploadForm.value.tipoDocumento) return

  uploading.value = true
  uploadProgress.value = 0

  const formData = new FormData()
  formData.append('anexo[arquivo]', uploadForm.value.arquivo)
  formData.append('anexo[tipo_documento]', uploadForm.value.tipoDocumento)
  if (uploadForm.value.numeroDocumento) {
    formData.append('anexo[numero_documento]', uploadForm.value.numeroDocumento)
  }

  try {
    const response = await api.post(props.baseUrl, formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      },
      onUploadProgress: (progressEvent) => {
        if (progressEvent.total) {
          uploadProgress.value = Math.round((progressEvent.loaded * 100) / progressEvent.total)
        }
      }
    })

    if (response.data.success) {
      success(response.data.message)
      anexos.value.unshift(response.data.anexo)
      closeUploadModal()
    } else {
      showError(response.data.message)
    }
  } catch (err) {
    showError('Erro ao enviar documento')
  } finally {
    uploading.value = false
  }
}

function closeUploadModal() {
  openUploadModal.value = false
  uploadForm.value = {
    tipoDocumento: '',
    numeroDocumento: '',
    arquivo: null
  }
  uploadProgress.value = 0
}

function confirmRemove(anexo: Anexo) {
  anexoToRemove.value = anexo
  confirmModalOpen.value = true
}

async function handleRemove() {
  if (!anexoToRemove.value) return

  try {
    const response = await api.delete(`${props.baseUrl}/${anexoToRemove.value.id}`)
    if (response.data.success) {
      success(response.data.message)
      anexos.value = anexos.value.filter(a => a.id !== anexoToRemove.value!.id)
    }
  } catch (err) {
    showError('Erro ao remover documento')
  } finally {
    confirmModalOpen.value = false
    anexoToRemove.value = null
  }
}

function openPreview(anexo: Anexo) {
  anexoParaPreview.value = anexo
  previewModalOpen.value = true
}

function iconClass(anexo: Anexo): string {
  if (anexo.imagem) return 'bg-purple-100 text-purple-600'
  if (anexo.pdf) return 'bg-red-100 text-red-600'
  if (anexo.extensao === 'xlsx' || anexo.extensao === 'xls') return 'bg-green-100 text-green-600'
  if (anexo.extensao === 'docx' || anexo.extensao === 'doc') return 'bg-blue-100 text-blue-600'
  if (anexo.extensao === 'xml') return 'bg-orange-100 text-orange-600'
  return 'bg-gray-100 text-gray-600'
}

function fileIcon(anexo: Anexo) {
  if (anexo.imagem) return PhotoIcon
  if (anexo.extensao === 'xlsx' || anexo.extensao === 'xls') return TableCellsIcon
  return DocumentTextIcon
}

// Lifecycle
onMounted(() => {
  fetchAnexos()
})
</script>
