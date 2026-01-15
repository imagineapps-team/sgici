# frozen_string_literal: true

module RelatoriosHelper
  # Formata valor monetario no padrao brasileiro
  def format_currency_br(value)
    return '0,00' if value.nil?
    number_with_precision(value, precision: 2, separator: ',', delimiter: '.')
  end

  # Formata data no padrao brasileiro
  def format_date_br(date, format = '%d/%m/%Y')
    return '-' if date.nil?
    date.strftime(format)
  end

  # Formata data/hora no padrao brasileiro
  def format_datetime_br(datetime)
    return '-' if datetime.nil?
    datetime.strftime('%d/%m/%Y as %H:%M')
  end

  # Retorna label do status de reciclagem
  def status_label(status)
    {
      'R' => 'Recebido',
      'T' => 'Transmitido',
      'P' => 'Processado',
      'X' => 'Cancelado',
      'N' => 'Nao Transmitido'
    }[status] || status
  end

  # Retorna classe CSS do badge de status
  def status_badge_class(status)
    base = 'badge'
    variant = case status
              when 'R' then 'badge-recebido'
              when 'T' then 'badge-transmitido'
              when 'P' then 'badge-processado'
              when 'X' then 'badge-cancelado'
              else ''
              end
    "#{base} #{variant}"
  end

  # Calcula totais de um array de dados
  # campos: array de simbolos com os campos a somar
  # Retorna hash com os totais
  def calcular_totais(dados, campos)
    return {} if dados.blank?

    campos.each_with_object({}) do |campo, totais|
      totais[campo] = dados.sum do |item|
        valor = item[campo]
        if valor.is_a?(String)
          valor.gsub('.', '').gsub(',', '.').to_f
        else
          valor.to_f
        end
      end
    end
  end

  # Gera nome do arquivo de relatorio
  def report_filename(base_name, extension)
    "#{base_name}_#{Date.current.strftime('%Y%m%d')}.#{extension}"
  end
end
