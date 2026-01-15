<template>
  <Head :title="isEditing ? 'Editar Usuário' : 'Novo Usuário'" />

  <AppLayout :usuario="usuario">
    <div class="max-w-2xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <Link
          href="/usuarios"
          class="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-2"
        >
          <ArrowLeftIcon class="h-4 w-4" />
          Voltar para lista
        </Link>
        <h1 class="text-2xl font-bold text-gray-900">
          {{ isEditing ? 'Editar Usuário' : 'Novo Usuário' }}
        </h1>
      </div>

      <!-- Form -->
      <form @submit.prevent="handleSubmit" class="bg-white rounded-lg shadow p-6 space-y-6">
        <!-- Status (somente na edicao) e Nome -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <ISelect
            v-if="isEditing"
            v-model="form.status"
            label="Status"
            :options="statusSelectOptions"
            placeholder="Selecione o status"
            required
            :error="errors.status"
          />

          <div :class="isEditing ? 'md:col-span-2' : 'md:col-span-3'">
            <IInput
              v-model="form.nome"
              label="Nome"
              placeholder="Nome do usuário"
              required
              :error="errors.nome"
            />
          </div>
        </div>

        <!-- Login e Perfil -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <IInput
            v-model="form.login"
            label="Login"
            placeholder="Login de acesso"
            required
            :error="errors.login"
          />

          <ISelect
            v-model="form.perfil_id"
            label="Perfil"
            :options="perfilOptions"
            placeholder="Selecione o perfil"
            required
            searchable
            :error="errors.perfil_id"
          />
        </div>

        <!-- Senha e Confirmar Senha -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <IInput
            v-model="form.password"
            type="password"
            label="Senha"
            :placeholder="isEditing ? 'Deixe em branco para manter' : 'Digite a senha'"
            :required="!isEditing"
            :error="errors.password"
          />

          <IInput
            v-model="form.password_confirm"
            type="password"
            label="Confirmar Senha"
            :placeholder="isEditing ? 'Deixe em branco para manter' : 'Confirme a senha'"
            :required="!isEditing"
            :error="errors.password_confirm"
          />
        </div>

        <!-- Actions -->
        <div class="border-t pt-6 flex justify-end gap-3">
          <Link
            href="/usuarios"
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

interface UsuarioData {
  id?: number
  nome: string | null
  login: string | null
  perfil_id: number | null
  status: string | null
}

interface PerfilItem {
  id: number
  nome: string
}

interface StatusOption {
  value: string
  label: string
}

interface Props {
  usuario: UserInfo
  usuarioData: UsuarioData | null
  perfis: PerfilItem[]
  statusOptions: StatusOption[]
}

const props = defineProps<Props>()

const isEditing = computed(() => !!props.usuarioData?.id)

const form = ref({
  nome: props.usuarioData?.nome || '',
  login: props.usuarioData?.login || '',
  perfil_id: props.usuarioData?.perfil_id || null,
  status: props.usuarioData?.status || 'A',
  password: '',
  password_confirm: ''
})

const errors = ref<Record<string, string>>({})
const processing = ref(false)

const perfilOptions = computed<SelectOption[]>(() =>
  props.perfis.map(p => ({ value: p.id, label: p.nome }))
)

const statusSelectOptions = computed<SelectOption[]>(() =>
  props.statusOptions.map(s => ({ value: s.value, label: s.label }))
)

function validate(): boolean {
  errors.value = {}

  if (!form.value.nome?.trim()) {
    errors.value.nome = 'O nome é obrigatório'
  }

  if (!form.value.login?.trim()) {
    errors.value.login = 'O login é obrigatório'
  }

  if (!form.value.perfil_id) {
    errors.value.perfil_id = 'O perfil é obrigatório'
  }

  if (isEditing.value && !form.value.status) {
    errors.value.status = 'O status é obrigatório'
  }

  // Senha obrigatoria apenas no cadastro
  if (!isEditing.value) {
    if (!form.value.password) {
      errors.value.password = 'A senha é obrigatória'
    }
    if (!form.value.password_confirm) {
      errors.value.password_confirm = 'A confirmação de senha é obrigatória'
    }
  }

  // Validar confirmacao de senha se digitou senha
  if (form.value.password || form.value.password_confirm) {
    if (form.value.password !== form.value.password_confirm) {
      errors.value.password_confirm = 'As senhas não conferem'
    }
  }

  return Object.keys(errors.value).length === 0
}

function handleSubmit() {
  if (!validate()) return

  processing.value = true

  const url = isEditing.value
    ? `/usuarios/${props.usuarioData?.id}`
    : '/usuarios'

  const method = isEditing.value ? 'put' : 'post'

  const payload: Record<string, unknown> = {
    nome: form.value.nome.trim(),
    login: form.value.login.trim(),
    perfil_id: form.value.perfil_id,
    status: form.value.status
  }

  // Adiciona senha apenas se preenchida
  if (form.value.password) {
    payload.password = form.value.password
  }

  router[method](url, { usuario: payload }, {
    onFinish: () => { processing.value = false }
  })
}
</script>
