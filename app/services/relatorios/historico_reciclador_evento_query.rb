# frozen_string_literal: true

module Relatorios
  class HistoricoRecicladorEventoQuery < BaseQuery
    def execute
      query = base_query
        .select(
          'recicladors.nome as reciclador',
          "eventos.id || ' - ' || acaos.nome || ' / ' || comunidades.nome as evento",
          'recursos.nome as residuo',
          'SUM(reciclagem_recursos.quantidade) as qtd_coletado',
          'SUM(reciclagem_recursos.bonus_valor) as valor'
        )
        .group(
          'eventos.id',
          'recicladors.id', 'recicladors.nome',
          'recursos.id', 'recursos.nome',
          'acaos.id', 'acaos.nome',
          'comunidades.id', 'comunidades.nome'
        )
        .order('recicladors.nome', 'eventos.id', 'recursos.nome')

      data = query.map do |row|
        {
          reciclador: row.reciclador,
          evento: row.evento,
          residuo: row.residuo,
          qtd_coletado: format_currency(row.qtd_coletado),
          valor: format_currency(row.valor),
          qtd_coletado_raw: row.qtd_coletado.to_f,
          valor_raw: row.valor.to_f
        }
      end

      totais = calculate_totals(data)

      {
        data: data,
        totais: totais
      }
    end

    private

    def base_query
      query = Reciclador
        .joins(reciclagem_recursos_base_join)
        .joins('INNER JOIN reciclagems ON reciclagems.id = reciclagem_recursos.reciclagem_id')
        .joins('INNER JOIN clientes_eventos_contratos ON clientes_eventos_contratos.id = reciclagems.cliente_evento_contrato_id')
        .joins('INNER JOIN eventos ON eventos.id = clientes_eventos_contratos.evento_id')
        .joins('INNER JOIN acaos ON acaos.id = eventos.acao_id')
        .joins('INNER JOIN comunidades ON comunidades.id = eventos.local_acao')
        .joins('INNER JOIN recursos ON recursos.id = reciclagem_recursos.recurso_id')

      query = apply_date_filter(query, 'reciclagems.data_cadastro')
      query = apply_eventos_filter(query)
      query = apply_reciclador_filter(query)
      query = apply_status_filter(query, 'reciclagems.status')

      query
    end

    def reciclagem_recursos_base_join
      'INNER JOIN reciclagem_recursos ON reciclagem_recursos.reciclador_id = recicladors.id'
    end

    def reciclador_id
      @reciclador_id ||= params[:reciclador].presence&.to_i
    end

    def apply_reciclador_filter(query)
      return query if reciclador_id.blank?
      query.where('recicladors.id = ?', reciclador_id)
    end

    def calculate_totals(data)
      qtd_total = data.sum { |item| item[:qtd_coletado_raw] }
      valor_total = data.sum { |item| item[:valor_raw] }

      {
        qtd_coletado: format_currency(qtd_total),
        valor: format_currency(valor_total)
      }
    end
  end
end
