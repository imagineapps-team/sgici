<template>
  <Head :title="isEditing ? 'Editar Bairro' : 'Novo Bairro'" />

  <AppLayout :usuario="usuario">
    <div class="max-w-2xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <Link
          href="/bairros"
          class="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-2"
        >
          <ArrowLeftIcon class="h-4 w-4" />
          Voltar para lista
        </Link>
        <h1 class="text-2xl font-bold text-gray-900">
          {{ isEditing ? 'Editar Bairro' : 'Novo Bairro' }}
        </h1>
      </div>

      <!-- Form -->
      <form @submit.prevent="handleSubmit" class="bg-white rounded-lg shadow p-6 space-y-6">
        <!-- Nome -->
        <div>
          <IInput
            v-model="form.nome"
            label="Nome"
            placeholder="Nome do bairro"
            required
            :error="errors.nome"
          />
        </div>

        <!-- UF e Cidade -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <ISelect
            v-model="form.uf_id"
            label="UF"
            :options="ufOptions"
            placeholder="Selecione a UF"
            required
            searchable
            @update:model-value="onUfChange"
            :error="errors.uf_id"
          />

          <ISelect
            v-model="form.cidade_id"
            label="Cidade"
            :options="cidadeOptions"
            placeholder="Selecione a cidade"
            required
            searchable
            :disabled="!form.uf_id"
            :error="errors.cidade_id"
          />
        </div>

        <!-- Actions -->
        <div class="border-t pt-6 flex justify-end gap-3">
          <Link
            href="/bairros"
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            Cancelar
          </Link>
          <button
            type="submit"
            :disabled="processing"
            class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ processing ? 'Salvando...' : 'Salvar' }}
          </button>
        </div>
      </form>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { Head, Link, router } from '@inertiajs/vue3'
import { ArrowLeftIcon } from '@heroicons/vue/24/outline'
import AppLayout from '../../layouts/AppLayout.vue'
import { IInput } from '../../components/IInput'
import { ISelect } from '../../components/ISelect'
import type { SelectOption } from '../../components/ISelect/types'
import type { UserInfo } from '../../types/navigation'
import api from '../../lib/axios'

interface BairroData {
  id?: number
  nome: string | null
  cidade_id: number | null
}

interface UfItem {
  id: number
  nome: string
  sigla: string
}

interface CidadeItem {
  id: number
  nome: string
}

interface Props {
  usuario: UserInfo
  bairro: BairroData | null
  ufs: UfItem[]
  cidades: CidadeItem[]
  ufSelecionada: number | null
}

const props = defineProps<Props>()

const isEditing = computed(() => !!props.bairro?.id)

const form = ref({
  nome: props.bairro?.nome || '',
  cidade_id: props.bairro?.cidade_id || null,
  uf_id: props.ufSelecionada || null
})

const errors = ref<Record<string, string>>({})
const processing = ref(false)

// Listas para cascata de selects
const cidadesLoaded = ref<CidadeItem[]>(props.cidades || [])

// Options computadas
const ufOptions = computed<SelectOption[]>(() =>
  props.ufs.map(u => ({ value: u.id, label: `${u.sigla} - ${u.nome}` }))
)

const cidadeOptions = computed<SelectOption[]>(() =>
  cidadesLoaded.value.map(c => ({ value: c.id, label: c.nome }))
)

// Handler para cascata
async function onUfChange(ufId: number | string | null) {
  form.value.cidade_id = null
  cidadesLoaded.value = []

  if (!ufId) return

  try {
    const response = await api.get(`/bairros/cidades_by_uf?uf_id=${ufId}`)
    cidadesLoaded.value = response.data
  } catch (e) {
    console.error('Erro ao carregar cidades:', e)
  }
}

function validate(): boolean {
  errors.value = {}

  if (!form.value.nome?.trim()) {
    errors.value.nome = 'O nome é obrigatório'
  }

  if (!form.value.uf_id) {
    errors.value.uf_id = 'A UF é obrigatória'
  }

  if (!form.value.cidade_id) {
    errors.value.cidade_id = 'A cidade é obrigatória'
  }

  return Object.keys(errors.value).length === 0
}

function handleSubmit() {
  if (!validate()) return

  processing.value = true

  const url = isEditing.value
    ? `/bairros/${props.bairro?.id}`
    : '/bairros'

  const method = isEditing.value ? 'put' : 'post'

  const payload = {
    nome: form.value.nome.trim(),
    cidade_id: form.value.cidade_id
  }

  router[method](url, { bairro: payload }, {
    onFinish: () => { processing.value = false }
  })
}
</script>
