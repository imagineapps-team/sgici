# frozen_string_literal: true

module Relatorios
  class HistoricoEventosQuery < BaseQuery
    def execute
      case modelo
      when 'RT'
        resumo_totais
      when 'RD'
        reciclagens_detalhadas
      when 'RML'
        resumo_mensal_local
      when 'RMLT'
        resumo_mensal_local_tipologia
      else
        resumo_totais
      end
    end

    private

    # RT - Resumo de Totais por Ação/Local
    def resumo_totais
      query = base_query
        .select(
          'acaos.nome as acao',
          'comunidades.nome as local_acao',
          'bairros.nome as bairro',
          'cidades.nome as cidade',
          'COUNT(DISTINCT reciclagems.id) as participantes_total',
          'COUNT(DISTINCT clientes_eventos_contratos.contrato_id) as participantes_unicos_total',
          'STRING_AGG(DISTINCT recicladors.nome, \', \') as recicladores',
          'SUM(reciclagem_recursos.quantidade) as reciclagens_total_peso',
          'SUM(reciclagem_recursos.bonus_valor) as reciclagens_total_valor',
          'SUM(reciclagem_recursos.quantidade * COALESCE(tipo_recursos.indice, 0)) as kwheco'
        )
        .joins(reciclagem_recursos_join)
        .joins(reciclador_join)
        .joins(tipo_recurso_join)
        .group('acaos.nome', 'comunidades.nome', 'bairros.nome', 'cidades.nome')
        .order('acaos.nome', 'comunidades.nome')

      query.map do |row|
        participantes = row.participantes_total.to_i
        clientes = row.participantes_unicos_total.to_i
        mpc = clientes > 0 ? (participantes.to_f / clientes).round(2) : 0

        {
          acao: row.acao,
          local_acao: row.local_acao,
          bairro: row.bairro,
          cidade: row.cidade,
          participantes_total: participantes,
          participantes_unicos_total: clientes,
          recicladores: row.recicladores,
          mpc: mpc,
          reciclagens_total_peso: format_currency(row.reciclagens_total_peso),
          reciclagens_total_valor: format_currency(row.reciclagens_total_valor),
          kwheco: format_currency(row.kwheco)
        }
      end
    end

    # RD - Reciclagens Detalhadas
    def reciclagens_detalhadas
      query = base_query
        .select(
          'comunidades.nome as local_acao',
          'bairros.nome as bairro',
          'cidades.nome as cidade',
          'reciclagems.codigo as rec_codigo',
          'contratos."nomeTitular" as contrato_nome',
          'contratos_tipos.nome as contrato_tipo',
          'contratos.numero as nuc',
          'reciclagems.bonus_percentual as percentual',
          'SUM(reciclagem_recursos.quantidade) as reciclagens_total_peso',
          'SUM(reciclagem_recursos.bonus_valor) as reciclagens_total_valor',
          'STRING_AGG(DISTINCT recicladors.nome, \', \') as recicladores',
          'reciclagems.data_cadastro',
          'reciclagems.status',
          'reciclagem_integracao.arquivo as integracao_arquivo'
        )
        .joins(reciclagem_recursos_join)
        .joins(reciclador_join)
        .joins(contrato_tipo_join)
        .joins(integracao_join)
        .group(
          'comunidades.nome', 'bairros.nome', 'cidades.nome',
          'reciclagems.codigo', 'contratos."nomeTitular"', 'contratos_tipos.nome',
          'contratos.numero', 'reciclagems.bonus_percentual',
          'reciclagems.data_cadastro', 'reciclagems.status', 'reciclagem_integracao.arquivo'
        )
        .order('reciclagems.data_cadastro DESC')

      query.map do |row|
        {
          local_acao: row.local_acao,
          bairro: row.bairro,
          cidade: row.cidade,
          rec_codigo: row.rec_codigo,
          contrato_nome: row.contrato_nome,
          contrato_tipo: row.contrato_tipo,
          nuc: row.nuc,
          percentual: row.percentual,
          reciclagens_total_peso: format_currency(row.reciclagens_total_peso),
          reciclagens_total_valor: format_currency(row.reciclagens_total_valor),
          recicladores: row.recicladores,
          data_cadastro: format_datetime(row.data_cadastro),
          status: row.status,
          status_label: Reciclagem::STATUSES[row.status],
          integracao_arquivo: row.integracao_arquivo
        }
      end
    end

    # RML - Resumo Mensal por Local
    def resumo_mensal_local
      query = base_query
        .select(
          'EXTRACT(YEAR FROM reciclagems.data_cadastro) as ano',
          'EXTRACT(MONTH FROM reciclagems.data_cadastro) as mes',
          'comunidades.nome as local_acao',
          'bairros.nome as bairro',
          'cidades.nome as cidade',
          'COUNT(DISTINCT reciclagems.id) as participacoes',
          'COUNT(DISTINCT clientes_eventos_contratos.contrato_id) as atendidos',
          'SUM(reciclagem_recursos.quantidade * COALESCE(tipo_recursos.indice, 0)) as kwheco',
          'SUM(reciclagem_recursos.quantidade) as reciclagens_total_peso',
          'SUM(reciclagem_recursos.bonus_valor) as reciclagens_total_valor'
        )
        .joins(reciclagem_recursos_join)
        .joins(tipo_recurso_join)
        .group(
          'EXTRACT(YEAR FROM reciclagems.data_cadastro)',
          'EXTRACT(MONTH FROM reciclagems.data_cadastro)',
          'comunidades.nome', 'bairros.nome', 'cidades.nome'
        )
        .order('ano DESC', 'mes DESC', 'comunidades.nome')

      query.map do |row|
        {
          ano: row.ano.to_i,
          mes: row.mes.to_i,
          mes_nome: I18n.t('date.month_names')[row.mes.to_i],
          local_acao: row.local_acao,
          bairro: row.bairro,
          cidade: row.cidade,
          participacoes: row.participacoes.to_i,
          atendidos: row.atendidos.to_i,
          kwheco: format_currency(row.kwheco),
          reciclagens_total_peso: format_currency(row.reciclagens_total_peso),
          reciclagens_total_valor: format_currency(row.reciclagens_total_valor)
        }
      end
    end

    # RMLT - Resumo Mensal por Local e Tipologia
    def resumo_mensal_local_tipologia
      query = base_query
        .select(
          'EXTRACT(YEAR FROM reciclagems.data_cadastro) as ano',
          'EXTRACT(MONTH FROM reciclagems.data_cadastro) as mes',
          'comunidades.nome as local_acao',
          'bairros.nome as bairro',
          'cidades.nome as cidade',
          'tipo_recursos.nome as tipologia',
          'SUM(reciclagem_recursos.quantidade * COALESCE(tipo_recursos.indice, 0)) as kwheco',
          'SUM(reciclagem_recursos.quantidade) as reciclagens_total_peso',
          'SUM(reciclagem_recursos.bonus_valor) as reciclagens_total_valor'
        )
        .joins(reciclagem_recursos_join)
        .joins(tipo_recurso_join)
        .group(
          'EXTRACT(YEAR FROM reciclagems.data_cadastro)',
          'EXTRACT(MONTH FROM reciclagems.data_cadastro)',
          'comunidades.nome', 'bairros.nome', 'cidades.nome', 'tipo_recursos.nome'
        )
        .order('ano DESC', 'mes DESC', 'comunidades.nome', 'tipo_recursos.nome')

      query.map do |row|
        {
          ano: row.ano.to_i,
          mes: row.mes.to_i,
          mes_nome: I18n.t('date.month_names')[row.mes.to_i],
          local_acao: row.local_acao,
          bairro: row.bairro,
          cidade: row.cidade,
          tipologia: row.tipologia,
          kwheco: format_currency(row.kwheco),
          reciclagens_total_peso: format_currency(row.reciclagens_total_peso),
          reciclagens_total_valor: format_currency(row.reciclagens_total_valor)
        }
      end
    end

    # Query base com joins comuns
    def base_query
      query = Reciclagem
        .joins(cliente_evento_contrato: [:evento, :contrato])
        .joins('INNER JOIN acaos ON acaos.id = eventos.acao_id')
        .joins('INNER JOIN comunidades ON comunidades.id = eventos.local_acao')
        .joins('LEFT JOIN bairros ON bairros.id = comunidades.bairro_id')
        .joins('LEFT JOIN cidades ON cidades.id = bairros.cidade_id')

      # Aplicar filtros
      query = apply_date_filter(query)
      query = apply_acao_filter(query)
      query = apply_local_filter(query)
      query = apply_status_filter(query)

      query
    end

    def apply_date_filter(query)
      if data_inicial.present?
        query = query.where('reciclagems.data_cadastro >= ?', data_inicial.beginning_of_day)
      end
      if data_final.present?
        query = query.where('reciclagems.data_cadastro <= ?', data_final.end_of_day)
      end
      query
    end

    def apply_acao_filter(query)
      return query if acoes_ids.empty?
      query.where('acaos.id IN (?)', acoes_ids)
    end

    def apply_local_filter(query)
      return query if locais_ids.empty?
      query.where('comunidades.id IN (?)', locais_ids)
    end

    def apply_status_filter(query)
      return query.where.not('reciclagems.status' => 'X') if status_filter.empty? || status_filter.include?('-X')

      if status_filter.include?('-X')
        query.where.not('reciclagems.status' => 'X')
      else
        query.where('reciclagems.status IN (?)', status_filter)
      end
    end

    # Joins auxiliares
    def reciclagem_recursos_join
      'LEFT JOIN reciclagem_recursos ON reciclagem_recursos.reciclagem_id = reciclagems.id'
    end

    def reciclador_join
      'LEFT JOIN recicladors ON recicladors.id = reciclagem_recursos.reciclador_id'
    end

    def contrato_tipo_join
      'LEFT JOIN contratos_tipos ON contratos_tipos.id = contratos.contrato_tipo_id'
    end

    def tipo_recurso_join
      'LEFT JOIN recursos ON recursos.id = reciclagem_recursos.recurso_id
       LEFT JOIN tipo_recursos ON tipo_recursos.id = recursos.tipo_recurso_id'
    end

    def integracao_join
      'LEFT JOIN reciclagem_integracao ON reciclagem_integracao.id = reciclagems.integracao_id'
    end
  end
end
