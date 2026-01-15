import { router } from '@inertiajs/vue3'
import { useNotifications } from '../composables/useNotification'

let isSetup = false

export function setupInertiaErrorHandler() {
  // Evita configurar múltiplas vezes
  if (isSetup) return
  isSetup = true

  const { error } = useNotifications()

  // Handler para erros de exceção (500, etc)
  router.on('exception', (event) => {
    console.error('Inertia exception:', event.detail.exception)
    error('Ocorreu um erro inesperado. Tente novamente.')
  })

  // Handler para erros de validação retornados pelo Inertia
  router.on('error', (event) => {
    const errors = event.detail.errors
    if (typeof errors === 'object' && errors !== null) {
      const errorMessages = Object.values(errors).flat() as string[]
      if (errorMessages.length > 0) {
        // Mostra apenas o primeiro erro como toast
        error(errorMessages[0])
      }
    }
  })

  // Handler para respostas inválidas (não-Inertia)
  router.on('invalid', (event) => {
    console.error('Inertia invalid response:', event.detail.response)
    error('Erro de comunicação com o servidor.')
    event.preventDefault()
  })
}
