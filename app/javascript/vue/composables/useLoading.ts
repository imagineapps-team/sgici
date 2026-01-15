import { ref } from 'vue'

const isLoading = ref(false)
const loadingMessage = ref('')

export const useLoading = () => {
  const show = (message = '') => {
    loadingMessage.value = message
    isLoading.value = true
  }

  const hide = () => {
    isLoading.value = false
    loadingMessage.value = ''
  }

  const withLoading = async <T>(
    fn: () => Promise<T>,
    message = ''
  ): Promise<T> => {
    show(message)
    try {
      return await fn()
    } finally {
      hide()
    }
  }

  return {
    isLoading,
    loadingMessage,
    show,
    hide,
    withLoading
  }
}
