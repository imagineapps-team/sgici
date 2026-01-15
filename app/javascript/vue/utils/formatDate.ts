import { format, parseISO, isValid } from 'date-fns'
import { ptBR } from 'date-fns/locale'

/**
 * Formata uma data para o padrão brasileiro DD/MM/YYYY
 */
export function formatDate(
  date: string | Date | null | undefined,
  pattern = 'dd/MM/yyyy'
): string {
  if (!date) return ''

  try {
    const dateObj = typeof date === 'string' ? parseISO(date) : date

    if (!isValid(dateObj)) return ''

    return format(dateObj, pattern, { locale: ptBR })
  } catch {
    return ''
  }
}

/**
 * Formata uma data com hora para o padrão brasileiro DD/MM/YYYY HH:mm
 */
export function formatDateTime(
  date: string | Date | null | undefined,
  pattern = 'dd/MM/yyyy HH:mm'
): string {
  return formatDate(date, pattern)
}

/**
 * Formata uma data por extenso: 15 de dezembro de 2025
 */
export function formatDateLong(date: string | Date | null | undefined): string {
  return formatDate(date, "d 'de' MMMM 'de' yyyy")
}
