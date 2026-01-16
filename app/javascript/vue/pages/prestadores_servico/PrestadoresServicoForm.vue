<template>
  <Head :title="isEditing ? 'Editar Prestador' : 'Novo Prestador'" />

  <AppLayout :usuario="usuario">
    <div class="max-w-4xl mx-auto">
      <div class="mb-6">
        <Link href="/prestadores_servico" class="text-brand-primary hover:underline">
          &larr; Voltar para Prestadores
        </Link>
      </div>

      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 border-b border-gray-200">
          <h1 class="text-xl font-semibold text-gray-900">
            {{ isEditing ? 'Editar Prestador de Servico' : 'Novo Prestador de Servico' }}
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
              v-model="form.nomeFantasia"
              label="Nome Fantasia"
            />
            <IInput
              v-model="form.cnpj"
              label="CNPJ"
              type="cpf_cnpj"
            />
            <ISelect
              v-model="form.tipo"
              label="Tipo"
              :options="tipoOptions"
              required
            />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <IInput
              v-model="form.email"
              label="Email"
              type="email"
            />
            <IInput
              v-model="form.telefone"
              label="Telefone"
              type="tel"
            />
            <IInput
              v-model="form.website"
              label="Website"
            />
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <IInput
              v-model="form.cidade"
              label="Cidade"
            />
            <IInput
              v-model="form.estado"
              label="Estado"
            />
            <IInput
              v-model="form.pais"
              label="Pais"
            />
          </div>

          <IInput
            v-model="form.endereco"
            label="Endereco"
          />

          <div>
            <h3 class="text-sm font-medium text-gray-700 mb-3">Contato</h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <IInput
                v-model="form.contatoNome"
                label="Nome"
              />
              <IInput
                v-model="form.contatoEmail"
                label="Email"
                type="email"
              />
              <IInput
                v-model="form.contatoTelefone"
                label="Telefone"
                type="tel"
              />
            </div>
          </div>

          <IInput
            v-model="form.servicosOferecidos"
            label="Servicos Oferecidos"
          />

          <div>
            <label class="flex items-center gap-2">
              <input
                v-model="form.ativo"
                type="checkbox"
                class="rounded border-gray-300 text-brand-primary focus:ring-brand-primary"
              />
              <span class="text-sm text-gray-700">Prestador ativo</span>
            </label>
          </div>

          <div class="flex justify-end gap-3 pt-4 border-t">
            <Link
              href="/prestadores_servico"
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

interface PrestadorForm {
  id?: number
  nome: string
  nomeFantasia: string
  cnpj: string
  tipo: string
  email: string
  telefone: string
  website: string
  pais: string
  estado: string
  cidade: string
  endereco: string
  cep: string
  contatoNome: string
  contatoEmail: string
  contatoTelefone: string
  servicosOferecidos: string
  ativo: boolean
}

interface Props {
  usuario: UserInfo
  prestador: PrestadorForm | null
  tipoOptions: SelectOption[]
}

const props = defineProps<Props>()

const page = usePage()
const errors = computed(() => page.props.errors as Record<string, string[]>)

const isEditing = computed(() => !!props.prestador?.id)
const isSubmitting = ref(false)

const form = ref<PrestadorForm>({
  nome: props.prestador?.nome || '',
  nomeFantasia: props.prestador?.nomeFantasia || '',
  cnpj: props.prestador?.cnpj || '',
  tipo: props.prestador?.tipo || '',
  email: props.prestador?.email || '',
  telefone: props.prestador?.telefone || '',
  website: props.prestador?.website || '',
  pais: props.prestador?.pais || 'Brasil',
  estado: props.prestador?.estado || '',
  cidade: props.prestador?.cidade || '',
  endereco: props.prestador?.endereco || '',
  cep: props.prestador?.cep || '',
  contatoNome: props.prestador?.contatoNome || '',
  contatoEmail: props.prestador?.contatoEmail || '',
  contatoTelefone: props.prestador?.contatoTelefone || '',
  servicosOferecidos: props.prestador?.servicosOferecidos || '',
  ativo: props.prestador?.ativo ?? true
})

function handleSubmit() {
  isSubmitting.value = true

  const data = {
    prestador_servico: {
      nome: form.value.nome,
      nome_fantasia: form.value.nomeFantasia,
      cnpj: form.value.cnpj,
      tipo: form.value.tipo,
      email: form.value.email,
      telefone: form.value.telefone,
      website: form.value.website,
      pais: form.value.pais,
      estado: form.value.estado,
      cidade: form.value.cidade,
      endereco: form.value.endereco,
      cep: form.value.cep,
      contato_nome: form.value.contatoNome,
      contato_email: form.value.contatoEmail,
      contato_telefone: form.value.contatoTelefone,
      servicos_oferecidos: form.value.servicosOferecidos,
      ativo: form.value.ativo
    }
  }

  if (isEditing.value) {
    router.put(`/prestadores_servico/${props.prestador!.id}`, data, {
      onFinish: () => { isSubmitting.value = false }
    })
  } else {
    router.post('/prestadores_servico', data, {
      onFinish: () => { isSubmitting.value = false }
    })
  }
}
</script>
