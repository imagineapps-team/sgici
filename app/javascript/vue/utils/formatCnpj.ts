/**
 * Formata um CNPJ (14 dígitos) para o padrão XX.XXX.XXX/XXXX-XX
 */
export function formatCnpj(cnpj: string | null | undefined): string {
  if (!cnpj) return ''

  const cleaned = cnpj.replace(/\D/g, '')

  if (cleaned.length !== 14) return cnpj

  return cleaned.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5')
}
