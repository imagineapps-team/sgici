import { computed } from 'vue'
import { usePage } from '@inertiajs/vue3'

/**
 * Composable para verificar Feature Flags
 *
 * As features são gerenciadas pelo Flipper no backend e compartilhadas
 * via Inertia props.
 *
 * @example
 * ```vue
 * <script setup>
 * import { useFeature } from '@/composables/useFeature'
 *
 * const { isEnabled, features } = useFeature()
 *
 * // Verificar feature específica
 * if (isEnabled('novo_modulo')) {
 *   // ...
 * }
 * </script>
 *
 * <template>
 *   <button v-if="isEnabled('exportar_pdf')">
 *     Exportar PDF
 *   </button>
 * </template>
 * ```
 */
export const useFeature = () => {
  const page = usePage()

  // Hash de features habilitadas { feature_name: true }
  const features = computed(() => {
    return (page.props.features as Record<string, boolean>) || {}
  })

  /**
   * Verifica se uma feature está habilitada
   * @param featureName Nome da feature (snake_case)
   * @returns true se habilitada
   */
  const isEnabled = (featureName: string): boolean => {
    return features.value[featureName] === true
  }

  /**
   * Verifica se uma feature está desabilitada
   * @param featureName Nome da feature (snake_case)
   * @returns true se desabilitada ou não existe
   */
  const isDisabled = (featureName: string): boolean => {
    return !isEnabled(featureName)
  }

  /**
   * Lista de nomes de features habilitadas
   */
  const enabledFeatures = computed(() => {
    return Object.keys(features.value).filter(key => features.value[key])
  })

  return {
    features,
    isEnabled,
    isDisabled,
    enabledFeatures
  }
}
