<template>
  <Head :title="`Login - ${appName}`" />

  <BrandingProvider>
    <div class="min-h-screen flex items-center justify-center bg-brand-primary/10">
      <div class="bg-white p-8 rounded-lg shadow-lg w-full max-w-md">
        <!-- Header com branding -->
        <div class="text-center mb-8">
          <div class="w-16 h-16 mx-auto rounded-full flex items-center justify-center mb-4 bg-brand-primary">
            <BoltIcon class="w-8 h-8 text-white" />
          </div>
          <h1 class="text-2xl font-bold text-brand-primary">{{ appName }}</h1>
          <p class="text-gray-500 text-sm mt-1">Acesse sua conta</p>
        </div>

        <form @submit.prevent="submit">
          <!-- Seleção de Regional (apenas para apps multi-tenant) -->
          <div v-if="hasMultipleTenants" class="mb-4">
            <label for="tenant" class="block text-sm font-medium text-gray-700 mb-1">
              Regional
            </label>
            <select
              id="tenant"
              v-model="form.tenant"
              class="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary transition-colors bg-white"
              :class="form.errors.tenant ? 'border-red-500' : 'border-gray-300'"
            >
              <option v-for="tenant in tenants" :key="tenant.value" :value="tenant.value">
                {{ tenant.label }}
              </option>
            </select>
            <span v-if="form.errors.tenant" class="text-red-500 text-sm mt-1">
              {{ form.errors.tenant }}
            </span>
          </div>

          <div class="mb-4">
            <label for="login" class="block text-sm font-medium text-gray-700 mb-1">
              Login
            </label>
            <input
              id="login"
              v-model="form.usuario.login"
              type="text"
              class="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary transition-colors"
              :class="form.errors.login ? 'border-red-500' : 'border-gray-300'"
              autofocus
            />
            <span v-if="form.errors.login" class="text-red-500 text-sm mt-1">
              {{ form.errors.login }}
            </span>
          </div>

          <div class="mb-4">
            <label for="password" class="block text-sm font-medium text-gray-700 mb-1">
              Senha
            </label>
            <input
              id="password"
              v-model="form.usuario.password"
              type="password"
              class="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary transition-colors"
              :class="form.errors.password ? 'border-red-500' : 'border-gray-300'"
            />
            <span v-if="form.errors.password" class="text-red-500 text-sm mt-1">
              {{ form.errors.password }}
            </span>
          </div>

          <div class="mb-6 flex items-center">
            <input
              id="remember"
              v-model="form.usuario.remember_me"
              type="checkbox"
              class="h-4 w-4 border-gray-300 rounded accent-brand-primary"
            />
            <label for="remember" class="ml-2 text-sm text-gray-700 cursor-pointer">
              Lembrar-me
            </label>
          </div>

          <button
            type="submit"
            :disabled="form.processing"
            class="w-full py-2.5 px-4 text-white rounded-md font-medium focus:outline-none focus:ring-2 focus:ring-brand-primary focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors bg-brand-primary hover:bg-brand-primary-dark"
          >
            {{ form.processing ? 'Entrando...' : 'Entrar' }}
          </button>
        </form>

        <!-- Footer -->
        <div class="mt-8 pt-6 border-t border-gray-200 text-center">
          <p class="text-xs text-gray-400">{{ footerText }}</p>
        </div>
      </div>
    </div>
  </BrandingProvider>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Head, useForm } from '@inertiajs/vue3'
import { BoltIcon } from '@heroicons/vue/24/outline'
import BrandingProvider from '../../components/BrandingProvider.vue'
import { useBranding } from '../../composables/useBranding'

interface TenantOption {
  value: string
  label: string
}

interface Props {
  tenants?: TenantOption[] | null
}

const props = withDefaults(defineProps<Props>(), {
  tenants: null
})

const { appName, footerText } = useBranding()

// Verifica se há múltiplos tenants disponíveis (multi-tenant app)
const hasMultipleTenants = computed(() => {
  return props.tenants && props.tenants.length > 0
})

const form = useForm({
  tenant: props.tenants?.[0]?.value || null,
  usuario: {
    login: '',
    password: '',
    remember_me: false
  }
})

function submit() {
  form.post('/login')
}
</script>
