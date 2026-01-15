<template>
  <Head :title="isEditing ? 'Editar Unidade de Medida' : 'Nova Unidade de Medida'" />

  <AppLayout :usuario="usuario">
    <div class="max-w-2xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <Link
          href="/unidade_medidas"
          class="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-2"
        >
          <ArrowLeftIcon class="h-4 w-4" />
          Voltar para lista
        </Link>
        <h1 class="text-2xl font-bold text-gray-900">
          {{ isEditing ? 'Editar Unidade de Medida' : 'Nova Unidade de Medida' }}
        </h1>
      </div>

      <!-- Form -->
      <form @submit.prevent="handleSubmit" class="bg-white rounded-lg shadow p-6 space-y-6">
        <!-- Nome e Sigla -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="md:col-span-2">
            <IInput
              v-model="form.nome"
              label="Nome"
              placeholder="Nome da unidade de medida"
              required
              :error="errors.nome"
            />
          </div>

          <IInput
            v-model="form.sigla"
            label="Sigla"
            placeholder="Ex: kg, un, L"
            required
            :maxlength="10"
            :error="errors.sigla"
          />
        </div>

        <!-- Actions -->
        <div class="border-t pt-6 flex justify-end gap-3">
          <Link
            href="/unidade_medidas"
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
import type { UserInfo } from '../../types/navigation'

interface UnidadeMedidaData {
  id?: number
  nome: string | null
  sigla: string | null
}

interface Props {
  usuario: UserInfo
  unidadeMedida: UnidadeMedidaData | null
}

const props = defineProps<Props>()

const isEditing = computed(() => !!props.unidadeMedida?.id)

const form = ref({
  nome: props.unidadeMedida?.nome || '',
  sigla: props.unidadeMedida?.sigla || ''
})

const errors = ref<Record<string, string>>({})
const processing = ref(false)

function validate(): boolean {
  errors.value = {}

  if (!form.value.nome?.trim()) {
    errors.value.nome = 'O nome é obrigatório'
  }

  if (!form.value.sigla?.trim()) {
    errors.value.sigla = 'A sigla é obrigatória'
  }

  return Object.keys(errors.value).length === 0
}

function handleSubmit() {
  if (!validate()) return

  processing.value = true

  const url = isEditing.value
    ? `/unidade_medidas/${props.unidadeMedida?.id}`
    : '/unidade_medidas'

  const method = isEditing.value ? 'put' : 'post'

  const payload = {
    nome: form.value.nome.trim(),
    sigla: form.value.sigla.trim()
  }

  router[method](url, { unidade_medida: payload }, {
    onFinish: () => { processing.value = false }
  })
}
</script>
