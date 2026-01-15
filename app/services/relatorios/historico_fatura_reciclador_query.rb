# frozen_string_literal: true

module Relatorios
  class HistoricoFaturaRecicladorQuery < BaseQuery
    def execute
      case modelo
      when 'RC'
        repasse_concessionaria
      else
        total_por_residuo
      end
    end

    private

    # TR - Total por Residuo (agrupa por Reciclador + Residuo)
    def total_por_residuo
      sql = <<-SQL.squish
        SELECT
          recicladors.nome as reciclador,
          recursos.nome as residuo,
          SUM(reciclagem_recursos.quantidade) as total_peso,
          SUM(reciclagem_recursos.bonus_valor) as total_valor
        FROM reciclagem_recursos
        INNER JOIN recursos ON recursos.id = reciclagem_recursos.recurso_id
        INNER JOIN reciclagems ON reciclagems.id = reciclagem_recursos.reciclagem_id
        INNER JOIN recicladors ON recicladors.id = reciclagem_recursos.reciclador_id
        WHERE reciclagems.status <> 'X'
          #{recicladores_condition}
          #{recursos_condition}
          #{date_condition}
        GROUP BY recicladors.nome, recursos.nome
        ORDER BY recicladors.nome, recursos.nome
      SQL

      results = ActiveRecord::Base.connection.execute(sql)
      results.map do |row|
        {
          reciclador: row['reciclador'],
          residuo: row['residuo'],
          total_peso: format_currency(row['total_peso']),
          total_valor: format_currency(row['total_valor'])
        }
      end
    end

    # RC - Repasse a Concessionaria (agrupa por Acao + Local)
    def repasse_concessionaria
      sql = <<-SQL.squish
        SELECT
          acaos.nome as acao_nome,
          comunidades.nome as local_acao,
          SUM(reciclagem_recursos.quantidade) as total_peso,
          SUM(reciclagem_recursos.bonus_valor) as total_valor
        FROM reciclagem_recursos
        INNER JOIN recursos ON recursos.id = reciclagem_recursos.recurso_id
        INNER JOIN reciclagems ON reciclagems.id = reciclagem_recursos.reciclagem_id
        INNER JOIN clientes_eventos_contratos ON clientes_eventos_contratos.id = reciclagems.cliente_evento_contrato_id
        INNER JOIN eventos ON eventos.id = clientes_eventos_contratos.evento_id
        INNER JOIN acaos ON acaos.id = eventos.acao_id
        INNER JOIN comunidades ON comunidades.id = eventos.local_acao
        INNER JOIN recicladors ON recicladors.id = reciclagem_recursos.reciclador_id
        WHERE reciclagems.status <> 'X'
          #{recicladores_condition}
          #{recursos_condition}
          #{date_condition}
        GROUP BY acaos.nome, comunidades.nome
        ORDER BY acaos.nome, comunidades.nome
      SQL

      results = ActiveRecord::Base.connection.execute(sql)
      results.map do |row|
        {
          acao_nome: row['acao_nome'],
          local_acao: row['local_acao'],
          total_peso: format_currency(row['total_peso']),
          total_valor: format_currency(row['total_valor'])
        }
      end
    end

    # Filtro de recicladores
    def recicladores_ids
      @recicladores_ids ||= Array(params[:recicladores]).reject(&:blank?).map(&:to_i)
    end

    def recicladores_condition
      return '' if recicladores_ids.empty?
      "AND reciclagem_recursos.reciclador_id IN (#{recicladores_ids.join(',')})"
    end

    # Filtro de recursos
    def recursos_ids
      @recursos_ids ||= Array(params[:recursos]).reject(&:blank?).map(&:to_i)
    end

    def recursos_condition
      return '' if recursos_ids.empty?
      "AND recursos.id IN (#{recursos_ids.join(',')})"
    end

    # Filtro de datas
    def date_condition
      conditions = []
      conditions << "AND reciclagems.data_cadastro >= '#{data_inicial.strftime('%Y-%m-%d')} 00:00:00'" if data_inicial.present?
      conditions << "AND reciclagems.data_cadastro <= '#{data_final.strftime('%Y-%m-%d')} 23:59:59'" if data_final.present?
      conditions.join(' ')
    end
  end
end
