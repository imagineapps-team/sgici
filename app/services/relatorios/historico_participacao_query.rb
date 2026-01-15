# frozen_string_literal: true

module Relatorios
  class HistoricoParticipacaoQuery < BaseQuery
    def execute
      case modelo
      when 'AR'
        agrupado_residuo
      when 'DG'
        dados_gerais
      else
        dados_gerais
      end
    end

    private

    # AR - Agrupado por Resíduo
    def agrupado_residuo
      query = base_query
        .select(
          'contratos.numero as nuc',
          'contratos."nomeTitular" as nome',
          'comunidades.nome as comunidade',
          'contratos_tipos.nome as tipo',
          'recursos.nome as residuo',
          'SUM(reciclagem_recursos.bonus_valor) as reciclagens_total_valor',
          'SUM(reciclagem_recursos.quantidade) as reciclagens_total_peso'
        )
        .joins(reciclagem_recursos_join)
        .joins(recurso_join)
        .joins(contrato_tipo_join)
        .group(
          'recursos.id', 'contratos.id', 'comunidades.id', 'contratos_tipos.id',
          'contratos.numero', 'contratos."nomeTitular"', 'comunidades.nome',
          'contratos_tipos.nome', 'recursos.nome'
        )
        .order('contratos."nomeTitular"', 'recursos.nome')

      query.map do |row|
        {
          nuc: row.nuc,
          nome: mask_name_lgpd(row.nome),
          comunidade: row.comunidade,
          tipo: row.tipo,
          residuo: row.residuo,
          reciclagens_total_valor: format_currency(row.reciclagens_total_valor),
          reciclagens_total_peso: format_currency(row.reciclagens_total_peso)
        }
      end
    end

    # DG - Dados Gerais (detalhado por reciclagem)
    def dados_gerais
      query = base_query
        .select(
          'reciclagems.codigo as rec_codigo',
          'reciclagems.data_cadastro',
          'reciclagems.status',
          'contratos.numero as nuc',
          'contratos."nomeTitular" as nome',
          'comunidades.nome as comunidade',
          'contratos_tipos.nome as tipo',
          'acaos.nome as acao_nome',
          'SUM(reciclagem_recursos.bonus_valor) as reciclagens_total_valor',
          'SUM(reciclagem_recursos.quantidade) as reciclagens_total_peso',
          'SUM(reciclagem_recursos.quantidade * COALESCE(tipo_recursos.indice, 0)) as kwheco'
        )
        .joins(reciclagem_recursos_join)
        .joins(tipo_recurso_join)
        .joins(contrato_tipo_join)
        .joins(acao_join)
        .group(
          'reciclagems.id', 'reciclagems.codigo', 'reciclagems.data_cadastro', 'reciclagems.status',
          'contratos.id', 'contratos.numero', 'contratos."nomeTitular"',
          'comunidades.id', 'comunidades.nome',
          'contratos_tipos.id', 'contratos_tipos.nome',
          'eventos.id', 'acaos.id', 'acaos.nome'
        )
        .order('reciclagems.data_cadastro DESC')

      query.map do |row|
        {
          rec_codigo: row.rec_codigo,
          data_cadastro: format_datetime(row.data_cadastro),
          status: row.status,
          status_label: status_label(row.status),
          nuc: row.nuc,
          nome: mask_name_lgpd(row.nome),
          comunidade: row.comunidade,
          tipo: row.tipo,
          evento: row.acao_nome,
          reciclagens_total_valor: format_currency(row.reciclagens_total_valor),
          reciclagens_total_peso: format_currency(row.reciclagens_total_peso),
          kwheco: format_currency(row.kwheco)
        }
      end
    end

    # Query base com joins comuns
    def base_query
      query = Reciclagem
        .joins(cliente_evento_contrato: [:evento, :contrato])
        .joins('INNER JOIN comunidades ON comunidades.id = eventos.local_acao')

      # Aplicar filtros
      query = apply_date_filter(query)
      query = apply_eventos_filter(query)
      query = apply_contratos_filter(query)
      query = apply_codigo_filter(query)
      query = apply_contrato_numero_filter(query)
      query = apply_status_filter(query)

      query
    end

    def apply_contrato_numero_filter(query)
      return query if contrato_numero.blank?
      query.where('contratos.numero ILIKE ?', "%#{contrato_numero}%")
    end

    def contrato_numero
      @contrato_numero ||= params[:contrato_numero].presence
    end

    # Joins auxiliares
    def recurso_join
      'LEFT JOIN recursos ON recursos.id = reciclagem_recursos.recurso_id'
    end

    def acao_join
      'LEFT JOIN acaos ON acaos.id = eventos.acao_id'
    end

    # Mascara nome para LGPD (mostra apenas primeiro e último nome)
    def mask_name_lgpd(name)
      return nil if name.blank?
      parts = name.strip.split(/\s+/)
      return parts.first if parts.length == 1
      "#{parts.first} #{parts.last}"
    end
  end
end
