# frozen_string_literal: true

# Helper para estilos compartilhados de relatorios Excel SGICI
module ExcelStylesHelper
  def create_excel_styles(wb)
    # Header da tabela (azul com texto branco)
    header_style = wb.styles.add_style(
      bg_color: '2563EB',
      fg_color: 'FFFFFF',
      b: true,
      alignment: { horizontal: :center, vertical: :center, wrap_text: true },
      border: { style: :thin, color: '000000' }
    )

    # Celula de texto padrao
    cell_style = wb.styles.add_style(
      alignment: { vertical: :center },
      border: { style: :thin, color: 'E5E7EB' }
    )

    # Celula centralizada
    center_style = wb.styles.add_style(
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: 'E5E7EB' }
    )

    # Celula numerica com 2 decimais
    number_style = wb.styles.add_style(
      alignment: { horizontal: :right, vertical: :center },
      border: { style: :thin, color: 'E5E7EB' },
      format_code: '#,##0.00'
    )

    # Celula numerica inteira
    integer_style = wb.styles.add_style(
      alignment: { horizontal: :right, vertical: :center },
      border: { style: :thin, color: 'E5E7EB' },
      format_code: '#,##0'
    )

    # Celula de moeda BRL
    currency_brl_style = wb.styles.add_style(
      alignment: { horizontal: :right, vertical: :center },
      border: { style: :thin, color: 'E5E7EB' },
      format_code: 'R$ #,##0.00'
    )

    # Celula de moeda USD
    currency_usd_style = wb.styles.add_style(
      alignment: { horizontal: :right, vertical: :center },
      border: { style: :thin, color: 'E5E7EB' },
      format_code: '$ #,##0.00'
    )

    # Celula de percentual
    percent_style = wb.styles.add_style(
      alignment: { horizontal: :right, vertical: :center },
      border: { style: :thin, color: 'E5E7EB' },
      format_code: '0.0%'
    )

    # Linha de total (fundo cinza claro)
    total_style = wb.styles.add_style(
      bg_color: 'F3F4F6',
      b: true,
      alignment: { horizontal: :right, vertical: :center },
      border: { style: :thin, color: '000000' },
      format_code: '#,##0.00'
    )

    # Linha de total - inteiro
    total_integer_style = wb.styles.add_style(
      bg_color: 'F3F4F6',
      b: true,
      alignment: { horizontal: :right, vertical: :center },
      border: { style: :thin, color: '000000' },
      format_code: '#,##0'
    )

    # Linha de total - texto
    total_text_style = wb.styles.add_style(
      bg_color: 'F3F4F6',
      b: true,
      alignment: { vertical: :center },
      border: { style: :thin, color: '000000' }
    )

    # Linha de total - moeda
    total_currency_style = wb.styles.add_style(
      bg_color: 'F3F4F6',
      b: true,
      alignment: { horizontal: :right, vertical: :center },
      border: { style: :thin, color: '000000' },
      format_code: 'R$ #,##0.00'
    )

    # Titulo do relatorio
    title_style = wb.styles.add_style(
      b: true,
      sz: 16,
      alignment: { horizontal: :left }
    )

    # Subtitulo / info
    subtitle_style = wb.styles.add_style(
      sz: 10,
      fg_color: '6B7280',
      alignment: { horizontal: :left }
    )

    # Data/hora
    date_style = wb.styles.add_style(
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: 'E5E7EB' },
      format_code: 'dd/mm/yyyy'
    )

    datetime_style = wb.styles.add_style(
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: 'E5E7EB' },
      format_code: 'dd/mm/yyyy hh:mm'
    )

    # Variacao positiva (verde)
    variacao_positiva_style = wb.styles.add_style(
      fg_color: '059669',
      alignment: { horizontal: :right, vertical: :center },
      border: { style: :thin, color: 'E5E7EB' },
      format_code: '0.0%'
    )

    # Variacao negativa (vermelho)
    variacao_negativa_style = wb.styles.add_style(
      fg_color: 'DC2626',
      alignment: { horizontal: :right, vertical: :center },
      border: { style: :thin, color: 'E5E7EB' },
      format_code: '0.0%'
    )

    # Retorna hash com todos os estilos
    {
      header: header_style,
      cell: cell_style,
      center: center_style,
      number: number_style,
      integer: integer_style,
      currency_brl: currency_brl_style,
      currency_usd: currency_usd_style,
      percent: percent_style,
      total: total_style,
      total_integer: total_integer_style,
      total_text: total_text_style,
      total_currency: total_currency_style,
      title: title_style,
      subtitle: subtitle_style,
      date: date_style,
      datetime: datetime_style,
      variacao_positiva: variacao_positiva_style,
      variacao_negativa: variacao_negativa_style
    }
  end
end
