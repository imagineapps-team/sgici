/**
 * Formata um CPF (11 dígitos) para o padrão XXX.XXX.XXX-XX
 */
export function formatCpf(cpf: string | null | undefined): string {
  if (!cpf) return ''

  const cleaned = cpf.replace(/\D/g, '')

  if (cleaned.length !== 11) return cpf

  return cleaned.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4')
}
