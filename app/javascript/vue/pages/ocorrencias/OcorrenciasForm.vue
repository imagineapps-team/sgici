<template>
  <Head :title="isEditing ? 'Editar Ocorrencia' : 'Nova Ocorrencia'" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">
            {{ isEditing ? 'Editar Ocorrencia' : 'Nova Ocorrencia' }}
          </h1>
          <p class="mt-1 text-sm text-gray-500">
            {{ isEditing ? 'Atualize os dados da ocorrencia' : 'Registre uma nova ocorrencia no processo' }}
          </p>
        </div>
        <Link href="/ocorrencias" class="text-brand-primary hover:underline">
          &larr; Voltar
        </Link>
      </div>

      <!-- Form -->
      <form @submit.prevent="handleSubmit" class="space-y-6">
        <!-- Card Principal -->
        <div class="bg-white rounded-lg shadow p-6 space-y-6">
          <h3 class="text-lg font-semibold text-gray-900 border-b pb-2">Dados da Ocorrencia</h3>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Processo -->
            <ISelect
              v-model="form.processoImportacaoId"
              label="Processo de Importacao"
              :options="processosOptions"
              placeholder="Selecione o processo"
              required
              searchable
              :error="errors.processo_importacao"
            />

            <!-- Responsavel -->
            <ISelect
              v-model="form.responsavelId"
              label="Responsavel"
              :options="responsaveisOptions"
              placeholder="Selecione o responsavel"
              searchable
              :error="errors.responsavel"
            />

            <!-- Tipo -->
            <ISelect
              v-model="form.tipo"
              label="Tipo"
              :options="tipoOptions"
              placeholder="Selecione o tipo"
              required
              :error="errors.tipo"
            />

            <!-- Gravidade -->
            <ISelect
              v-model="form.gravidade"
              label="Gravidade"
              :options="gravidadeOptions"
              placeholder="Selecione a gravidade"
              required
              :error="errors.gravidade"
            />

            <!-- Titulo -->
            <div class="md:col-span-2">
              <IInput
                v-model="form.titulo"
                label="Titulo"
                placeholder="Descreva brevemente a ocorrencia"
                required
                :maxlength="255"
                :error="errors.titulo"
              />
            </div>

            <!-- Descricao -->
            <div class="md:col-span-2">
              <label class="block text-sm font-medium text-gray-700 mb-1">
                Descricao <span class="text-red-500">*</span>
              </label>
              <textarea
                v-model="form.descricao"
                rows="4"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-primary focus:border-transparent resize-none"
                placeholder="Descreva em detalhes a ocorrencia..."
              ></textarea>
              <p v-if="errors.descricao" class="mt-1 text-sm text-red-600">{{ errors.descricao }}</p>
            </div>

            <!-- Data da Ocorrencia -->
            <IInput
              v-model="form.dataOcorrencia"
              type="date"
              label="Data da Ocorrencia"
              required
              :error="errors.data_ocorrencia"
            />

            <!-- Impacto Financeiro -->
            <IInput
              v-model="form.impactoFinanceiro"
              type="money"
              label="Impacto Financeiro Estimado"
              placeholder="0,00"
              :error="errors.impacto_financeiro"
            />
          </div>
        </div>

        <!-- Actions -->
        <div class="flex justify-end gap-3">
          <Link
            href="/ocorrencias"
            class="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            Cancelar
          </Link>
          <button
            type="submit"
            :disabled="submitting"
            class="px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark disabled:opacity-50 transition-colors"
          >
            {{ submitting ? 'Salvando...' : (isEditing ? 'Atualizar' : 'Registrar') }}
          </button>
        </div>
      </form>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Head, Link, router, usePage } from '@inertiajs/vue3'
import AppLayout from '../../layouts/AppLayout.vue'
import { IInput } from '../../components/IInput'
import { ISelect } from '../../components/ISelect'
import type { UserInfo } from '../../types/navigation'
import type { SelectOption } from '../../components/ISelect/types'
import { parseMoney } from '../../utils'

interface OcorrenciaForm {
  id?: number
  processoImportacaoId: number | null
  responsavelId: number | null
  tipo: string
  gravidade: string
  titulo: string
  descricao: string
  dataOcorrencia: string
  impactoFinanceiro: number | null
}

interface Props {
  usuario: UserInfo
  ocorrencia: OcorrenciaForm | null
  processosOptions: SelectOption[]
  responsaveisOptions: SelectOption[]
  tipoOptions: SelectOption[]
  gravidadeOptions: SelectOption[]
}

const props = defineProps<Props>()
const page = usePage()

const submitting = ref(false)

const isEditing = computed(() => !!props.ocorrencia?.id)

const errors = computed(() => {
  const pageErrors = page.props.errors as Record<string, string> | undefined
  return pageErrors || {}
})

const form = ref<OcorrenciaForm>({
  processoImportacaoId: null,
  responsavelId: null,
  tipo: '',
  gravidade: 'media',
  titulo: '',
  descricao: '',
  dataOcorrencia: new Date().toISOString().split('T')[0],
  impactoFinanceiro: null
})

function handleSubmit() {
  submitting.value = true

  const data = {
    ocorrencia: {
      processo_importacao_id: form.value.processoImportacaoId,
      responsavel_id: form.value.responsavelId || null,
      tipo: form.value.tipo,
      gravidade: form.value.gravidade,
      titulo: form.value.titulo,
      descricao: form.value.descricao,
      data_ocorrencia: form.value.dataOcorrencia,
      impacto_financeiro: form.value.impactoFinanceiro ? parseMoney(String(form.value.impactoFinanceiro)) : null
    }
  }

  if (isEditing.value) {
    router.put(`/ocorrencias/${props.ocorrencia!.id}`, data, {
      onFinish: () => { submitting.value = false }
    })
  } else {
    router.post('/ocorrencias', data, {
      onFinish: () => { submitting.value = false }
    })
  }
}

onMounted(() => {
  if (props.ocorrencia) {
    form.value = {
      processoImportacaoId: props.ocorrencia.processoImportacaoId,
      responsavelId: props.ocorrencia.responsavelId,
      tipo: props.ocorrencia.tipo,
      gravidade: props.ocorrencia.gravidade,
      titulo: props.ocorrencia.titulo,
      descricao: props.ocorrencia.descricao,
      dataOcorrencia: props.ocorrencia.dataOcorrencia,
      impactoFinanceiro: props.ocorrencia.impactoFinanceiro
    }
  }
})
</script>
