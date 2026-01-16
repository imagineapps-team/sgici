<template>
  <Head :title="isEditing ? 'Editar Categoria' : 'Nova Categoria'" />

  <AppLayout :usuario="usuario">
    <div class="max-w-2xl mx-auto">
      <div class="mb-6">
        <Link href="/categorias_custo" class="text-brand-primary hover:underline">
          &larr; Voltar para Categorias
        </Link>
      </div>

      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 border-b border-gray-200">
          <h1 class="text-xl font-semibold text-gray-900">
            {{ isEditing ? 'Editar Categoria de Custo' : 'Nova Categoria de Custo' }}
          </h1>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <IInput
              v-model="form.nome"
              label="Nome"
              required
              :error="errors?.nome?.[0]"
            />
            <IInput
              v-model="form.codigo"
              label="Codigo"
              placeholder="Ex: FRETE, SEGURO"
            />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <ISelect
              v-model="form.tipo"
              label="Tipo"
              :options="tipoOptions"
              required
            />
            <ISelect
              v-model="form.grupo"
              label="Grupo"
              :options="grupoOptions"
              required
            />
          </div>

          <IInput
            v-model="form.descricao"
            label="Descricao"
          />

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <IInput
              v-model="form.ordem"
              label="Ordem de Exibicao"
              type="number"
            />
          </div>

          <div class="space-y-3">
            <label class="flex items-center gap-2">
              <input
                v-model="form.obrigatorio"
                type="checkbox"
                class="rounded border-gray-300 text-brand-primary focus:ring-brand-primary"
              />
              <span class="text-sm text-gray-700">Custo obrigatorio em todo processo</span>
            </label>

            <label class="flex items-center gap-2">
              <input
                v-model="form.ativo"
                type="checkbox"
                class="rounded border-gray-300 text-brand-primary focus:ring-brand-primary"
              />
              <span class="text-sm text-gray-700">Categoria ativa</span>
            </label>
          </div>

          <div class="flex justify-end gap-3 pt-4 border-t">
            <Link
              href="/categorias_custo"
              class="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
            >
              Cancelar
            </Link>
            <button
              type="submit"
              class="px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark"
              :disabled="isSubmitting"
            >
              {{ isSubmitting ? 'Salvando...' : 'Salvar' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { Head, Link, router, usePage } from '@inertiajs/vue3'
import AppLayout from '../../layouts/AppLayout.vue'
import { IInput } from '../../components/IInput'
import { ISelect } from '../../components/ISelect'
import type { UserInfo } from '../../types/navigation'
import type { SelectOption } from '../../components/ISelect/types'

interface CategoriaForm {
  id?: number
  nome: string
  codigo: string
  tipo: string
  grupo: string
  descricao: string
  ordem: number
  obrigatorio: boolean
  ativo: boolean
}

interface Props {
  usuario: UserInfo
  categoria: CategoriaForm | null
  tipoOptions: SelectOption[]
  grupoOptions: SelectOption[]
}

const props = defineProps<Props>()

const page = usePage()
const errors = computed(() => page.props.errors as Record<string, string[]>)

const isEditing = computed(() => !!props.categoria?.id)
const isSubmitting = ref(false)

const form = ref<CategoriaForm>({
  nome: props.categoria?.nome || '',
  codigo: props.categoria?.codigo || '',
  tipo: props.categoria?.tipo || '',
  grupo: props.categoria?.grupo || '',
  descricao: props.categoria?.descricao || '',
  ordem: props.categoria?.ordem || 0,
  obrigatorio: props.categoria?.obrigatorio ?? false,
  ativo: props.categoria?.ativo ?? true
})

function handleSubmit() {
  isSubmitting.value = true

  const data = {
    categoria_custo: {
      nome: form.value.nome,
      codigo: form.value.codigo,
      tipo: form.value.tipo,
      grupo: form.value.grupo,
      descricao: form.value.descricao,
      ordem: form.value.ordem,
      obrigatorio: form.value.obrigatorio,
      ativo: form.value.ativo
    }
  }

  if (isEditing.value) {
    router.put(`/categorias_custo/${props.categoria!.id}`, data, {
      onFinish: () => { isSubmitting.value = false }
    })
  } else {
    router.post('/categorias_custo', data, {
      onFinish: () => { isSubmitting.value = false }
    })
  }
}
</script>
