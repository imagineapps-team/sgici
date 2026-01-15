/**
 * Formata um valor para moeda brasileira (R$)
 */
export function formatMoney(
  value: number | string | null | undefined,
  showSymbol = true
): string {
  if (value === null || value === undefined || value === '') return ''

  const numValue = typeof value === 'string' ? parseFloat(value) : value

  if (isNaN(numValue)) return ''

  const formatted = numValue.toLocaleString('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })

  return showSymbol ? `R$ ${formatted}` : formatted
}

/**
 * Converte string formatada para número
 * Ex: "1.234,56" -> 1234.56
 */
export function parseMoney(value: string | null | undefined): number | null {
  if (!value) return null

  const cleaned = value
    .replace(/[R$\s]/g, '')
    .replace(/\./g, '')
    .replace(',', '.')

  const num = parseFloat(cleaned)

  return isNaN(num) ? null : num
}
