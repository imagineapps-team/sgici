<template>
  <slot />
</template>

<script setup lang="ts">
import { onMounted, watch } from 'vue'
import { useBranding } from '../composables/useBranding'

const { branding } = useBranding()

/**
 * Converte cor hex para RGB
 */
function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  return result
    ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
      }
    : null
}

/**
 * Escurece uma cor hex
 */
function darkenColor(hex: string, percent: number): string {
  const rgb = hexToRgb(hex)
  if (!rgb) return hex

  const factor = 1 - percent / 100
  const r = Math.round(rgb.r * factor)
  const g = Math.round(rgb.g * factor)
  const b = Math.round(rgb.b * factor)

  return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`
}

/**
 * Clareia uma cor hex
 */
function lightenColor(hex: string, percent: number): string {
  const rgb = hexToRgb(hex)
  if (!rgb) return hex

  const factor = percent / 100
  const r = Math.round(rgb.r + (255 - rgb.r) * factor)
  const g = Math.round(rgb.g + (255 - rgb.g) * factor)
  const b = Math.round(rgb.b + (255 - rgb.b) * factor)

  return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`
}

/**
 * Injeta as CSS variables no documento
 */
function injectCssVariables() {
  const root = document.documentElement
  const primary = branding.value.primary_color
  const secondary = branding.value.secondary_color
  const accent = branding.value.accent_color

  // Cores principais
  root.style.setProperty('--brand-primary', primary)
  root.style.setProperty('--brand-primary-dark', darkenColor(primary, 15))
  root.style.setProperty('--brand-primary-light', lightenColor(primary, 20))
  root.style.setProperty('--brand-secondary', secondary)
  root.style.setProperty('--brand-accent', accent)

  // Variantes com opacidade (usando RGB para compatibilidade)
  const rgb = hexToRgb(primary)
  if (rgb) {
    root.style.setProperty('--brand-primary-rgb', `${rgb.r}, ${rgb.g}, ${rgb.b}`)
    root.style.setProperty('--brand-primary-10', `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, 0.1)`)
    root.style.setProperty('--brand-primary-20', `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, 0.2)`)
    root.style.setProperty('--brand-primary-50', `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, 0.5)`)
  }
}

// Injeta na montagem e quando branding muda
onMounted(injectCssVariables)
watch(branding, injectCssVariables, { deep: true })
</script>
