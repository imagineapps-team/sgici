import { computed } from 'vue'
import { usePage } from '@inertiajs/vue3'

/**
 * Interface para configuração de branding
 */
export interface BrandingConfig {
  app_name: string
  logo_url: string
  logo_white_url: string
  favicon_url: string
  primary_color: string
  secondary_color: string
  accent_color: string
  footer_text: string
  support_email: string
  support_phone: string
  assets_base_url: string
}

/**
 * Composable para acessar configurações de branding da aplicação
 *
 * O branding é configurado via ENV no backend e compartilhado via Inertia props.
 * Permite customização visual por aplicação (cores, logos, textos).
 *
 * @example
 * ```vue
 * <script setup>
 * import { useBranding } from '@/composables/useBranding'
 *
 * const { branding, appName, logoUrl, primaryColor } = useBranding()
 * </script>
 *
 * <template>
 *   <header :style="{ backgroundColor: primaryColor }">
 *     <img :src="logoUrl" :alt="appName" />
 *   </header>
 *   <footer>{{ branding.footer_text }}</footer>
 * </template>
 * ```
 */
export const useBranding = () => {
  const page = usePage()

  // Configuração completa de branding
  const branding = computed<BrandingConfig>(() => {
    return (page.props.branding as BrandingConfig) || {
      app_name: 'AVSI EcoEnel',
      logo_url: '/images/logo.png',
      logo_white_url: '/images/logo-white.png',
      favicon_url: '/favicon.ico',
      primary_color: '#3B82F6',
      secondary_color: '#10B981',
      accent_color: '#F59E0B',
      footer_text: '© AVSI Brasil',
      support_email: 'suporte@avsi.org.br',
      support_phone: '',
      assets_base_url: ''
    }
  })

  // Atalhos para propriedades comuns
  const appName = computed(() => branding.value.app_name)
  const logoUrl = computed(() => branding.value.logo_url)
  const logoWhiteUrl = computed(() => branding.value.logo_white_url)
  const primaryColor = computed(() => branding.value.primary_color)
  const secondaryColor = computed(() => branding.value.secondary_color)
  const accentColor = computed(() => branding.value.accent_color)
  const footerText = computed(() => branding.value.footer_text)
  const supportEmail = computed(() => branding.value.support_email)

  /**
   * Gera CSS variables para usar no template
   * @returns objeto com CSS custom properties
   */
  const cssVars = computed(() => ({
    '--color-primary': branding.value.primary_color,
    '--color-secondary': branding.value.secondary_color,
    '--color-accent': branding.value.accent_color
  }))

  return {
    branding,
    appName,
    logoUrl,
    logoWhiteUrl,
    primaryColor,
    secondaryColor,
    accentColor,
    footerText,
    supportEmail,
    cssVars
  }
}
