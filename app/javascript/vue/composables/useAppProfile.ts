import { computed } from 'vue'
import { usePage } from '@inertiajs/vue3'

/**
 * Interface para configuração do perfil da aplicação
 */
export interface AppProfileConfig {
  profile: string
  name: string
  environment: string
}

/**
 * Composable para acessar informações do perfil da aplicação
 *
 * O perfil é configurado via ENV (APP_PROFILE, APP_NAME) e identifica
 * qual aplicação está rodando (útil para multi-tenant com código compartilhado).
 *
 * @example
 * ```vue
 * <script setup>
 * import { useAppProfile } from '@/composables/useAppProfile'
 *
 * const { profile, name, isProfile, isDevelopment } = useAppProfile()
 *
 * // Verificar perfil específico (use com moderação!)
 * if (isProfile('ecoenel_bahia')) {
 *   // regra específica
 * }
 * </script>
 * ```
 *
 * @note Evite usar isProfile() para regras de negócio.
 * Prefira Feature Flags (Flipper) ou Business Policies (Strategy Pattern).
 */
export const useAppProfile = () => {
  const page = usePage()

  // Configuração do perfil da aplicação
  const appProfile = computed<AppProfileConfig>(() => {
    return (page.props.appProfile as AppProfileConfig) || {
      profile: 'default',
      name: 'AVSI EcoEnel',
      environment: 'development'
    }
  })

  // Identificador do perfil (ex: 'ecoenel_bahia', 'ecoenel_sp')
  const profile = computed(() => appProfile.value.profile)

  // Nome amigável da aplicação
  const name = computed(() => appProfile.value.name)

  // Ambiente Rails (development, test, production)
  const environment = computed(() => appProfile.value.environment)

  /**
   * Verifica se é um perfil específico
   * @note Use com moderação! Prefira Feature Flags ou Business Policies.
   * @param profileName Nome do perfil para comparar
   * @returns true se for o perfil especificado
   */
  const isProfile = (profileName: string): boolean => {
    return profile.value === profileName
  }

  /**
   * Verifica se está em ambiente de desenvolvimento
   */
  const isDevelopment = computed(() => environment.value === 'development')

  /**
   * Verifica se está em ambiente de produção
   */
  const isProduction = computed(() => environment.value === 'production')

  return {
    appProfile,
    profile,
    name,
    environment,
    isProfile,
    isDevelopment,
    isProduction
  }
}
