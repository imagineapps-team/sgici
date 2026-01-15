/**
 * Formata um numero grande com sufixo K (mil) ou M (milhao)
 * Ex: 1500 -> "1.5K", 2500000 -> "2.5M"
 */
export function formatNumberCompact(
  value: number | string | null | undefined
): string {
  if (value === null || value === undefined || value === '') return '0'

  const numValue = typeof value === 'string' ? parseFloat(value) : value

  if (isNaN(numValue)) return '0'

  if (numValue >= 1000000) {
    return (numValue / 1000000).toLocaleString('pt-BR', {
      minimumFractionDigits: 1,
      maximumFractionDigits: 1
    }) + 'M'
  }

  if (numValue >= 1000) {
    return (numValue / 1000).toLocaleString('pt-BR', {
      minimumFractionDigits: 1,
      maximumFractionDigits: 1
    }) + 'K'
  }

  return numValue.toLocaleString('pt-BR')
}

/**
 * Formata numero com separador de milhar brasileiro
 * Ex: 1234567 -> "1.234.567"
 */
export function formatNumber(
  value: number | string | null | undefined,
  decimals = 0
): string {
  if (value === null || value === undefined || value === '') return '0'

  const numValue = typeof value === 'string' ? parseFloat(value) : value

  if (isNaN(numValue)) return '0'

  return numValue.toLocaleString('pt-BR', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals
  })
}
