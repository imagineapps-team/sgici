<template>
  <Head :title="isEditing ? 'Editar Fornecedor' : 'Novo Fornecedor'" />

  <AppLayout :usuario="usuario">
    <div class="max-w-4xl mx-auto">
      <div class="mb-6">
        <Link href="/fornecedores" class="text-brand-primary hover:underline">
          &larr; Voltar para Fornecedores
        </Link>
      </div>

      <div class="bg-white shadow rounded-lg">
        <div class="px-6 py-4 border-b border-gray-200">
          <h1 class="text-xl font-semibold text-gray-900">
            {{ isEditing ? 'Editar Fornecedor' : 'Novo Fornecedor' }}
          </h1>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
          <!-- Dados Basicos -->
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
              v-model="form.pais"
              label="Pais"
              :options="paisOptions"
              searchable
            />
          </div>

          <!-- Contato -->
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

          <!-- Endereco -->
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
              v-model="form.cep"
              label="CEP"
            />
          </div>

          <IInput
            v-model="form.endereco"
            label="Endereco"
          />

          <!-- Comercial -->
          <div>
            <h3 class="text-sm font-medium text-gray-700 mb-3">Contato Comercial</h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <IInput
                v-model="form.contatoComercialNome"
                label="Nome"
              />
              <IInput
                v-model="form.contatoComercialEmail"
                label="Email"
                type="email"
              />
              <IInput
                v-model="form.contatoComercialTelefone"
                label="Telefone"
                type="tel"
              />
            </div>
          </div>

          <!-- Operacional -->
          <div>
            <h3 class="text-sm font-medium text-gray-700 mb-3">Contato Operacional</h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <IInput
                v-model="form.contatoOperacionalNome"
                label="Nome"
              />
              <IInput
                v-model="form.contatoOperacionalEmail"
                label="Email"
                type="email"
              />
              <IInput
                v-model="form.contatoOperacionalTelefone"
                label="Telefone"
                type="tel"
              />
            </div>
          </div>

          <!-- Outros -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <ISelect
              v-model="form.moedaPadrao"
              label="Moeda Padrao"
              :options="moedaOptions"
            />
            <IInput
              v-model="form.prazoPagamentoDias"
              label="Prazo Pagamento (dias)"
              type="number"
            />
          </div>

          <div>
            <label class="flex items-center gap-2">
              <input
                v-model="form.ativo"
                type="checkbox"
                class="rounded border-gray-300 text-brand-primary focus:ring-brand-primary"
              />
              <span class="text-sm text-gray-700">Fornecedor ativo</span>
            </label>
          </div>

          <div class="flex justify-end gap-3 pt-4 border-t">
            <Link
              href="/fornecedores"
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

interface FornecedorForm {
  id?: number
  nome: string
  nomeFantasia: string
  cnpj: string
  email: string
  telefone: string
  website: string
  pais: string
  estado: string
  cidade: string
  endereco: string
  cep: string
  contatoComercialNome: string
  contatoComercialEmail: string
  contatoComercialTelefone: string
  contatoOperacionalNome: string
  contatoOperacionalEmail: string
  contatoOperacionalTelefone: string
  moedaPadrao: string
  prazoPagamentoDias: number | null
  ativo: boolean
}

interface Props {
  usuario: UserInfo
  fornecedor: FornecedorForm | null
  paisOptions: SelectOption[]
  moedaOptions: SelectOption[]
}

const props = defineProps<Props>()

const page = usePage()
const errors = computed(() => page.props.errors as Record<string, string[]>)

const isEditing = computed(() => !!props.fornecedor?.id)
const isSubmitting = ref(false)

const form = ref<FornecedorForm>({
  nome: props.fornecedor?.nome || '',
  nomeFantasia: props.fornecedor?.nomeFantasia || '',
  cnpj: props.fornecedor?.cnpj || '',
  email: props.fornecedor?.email || '',
  telefone: props.fornecedor?.telefone || '',
  website: props.fornecedor?.website || '',
  pais: props.fornecedor?.pais || '',
  estado: props.fornecedor?.estado || '',
  cidade: props.fornecedor?.cidade || '',
  endereco: props.fornecedor?.endereco || '',
  cep: props.fornecedor?.cep || '',
  contatoComercialNome: props.fornecedor?.contatoComercialNome || '',
  contatoComercialEmail: props.fornecedor?.contatoComercialEmail || '',
  contatoComercialTelefone: props.fornecedor?.contatoComercialTelefone || '',
  contatoOperacionalNome: props.fornecedor?.contatoOperacionalNome || '',
  contatoOperacionalEmail: props.fornecedor?.contatoOperacionalEmail || '',
  contatoOperacionalTelefone: props.fornecedor?.contatoOperacionalTelefone || '',
  moedaPadrao: props.fornecedor?.moedaPadrao || 'USD',
  prazoPagamentoDias: props.fornecedor?.prazoPagamentoDias || null,
  ativo: props.fornecedor?.ativo ?? true
})

function handleSubmit() {
  isSubmitting.value = true

  const data = {
    fornecedor: {
      nome: form.value.nome,
      nome_fantasia: form.value.nomeFantasia,
      cnpj: form.value.cnpj,
      email: form.value.email,
      telefone: form.value.telefone,
      website: form.value.website,
      pais: form.value.pais,
      estado: form.value.estado,
      cidade: form.value.cidade,
      endereco: form.value.endereco,
      cep: form.value.cep,
      contato_comercial_nome: form.value.contatoComercialNome,
      contato_comercial_email: form.value.contatoComercialEmail,
      contato_comercial_telefone: form.value.contatoComercialTelefone,
      contato_operacional_nome: form.value.contatoOperacionalNome,
      contato_operacional_email: form.value.contatoOperacionalEmail,
      contato_operacional_telefone: form.value.contatoOperacionalTelefone,
      moeda_padrao: form.value.moedaPadrao,
      prazo_pagamento_dias: form.value.prazoPagamentoDias,
      ativo: form.value.ativo
    }
  }

  if (isEditing.value) {
    router.put(`/fornecedores/${props.fornecedor!.id}`, data, {
      onFinish: () => { isSubmitting.value = false }
    })
  } else {
    router.post('/fornecedores', data, {
      onFinish: () => { isSubmitting.value = false }
    })
  }
}
</script>
