# frozen_string_literal: true

module Relatorios
  class VeiculosQuery < BaseQuery
    def execute
      case modelo
      when 'RR'
        por_tipo_residuo
      when 'RV'
        por_veiculo
      when 'RL'
        por_local
      else
        geral
      end
    end

    private

    # RG - Geral (todas as colunas)
    def geral
      sql = <<-SQL.squish
        SELECT
          tv.descricao as veiculo_tipo,
          veiculo.placa as placa,
          categoria.nome as recurso_tipo,
          local.nome as local_acao,
          SUM(rr.quantidade) as quantidade_total,
          SUM(rr.bonus_valor) as bonus_total,
          rec.data_cadastro as data_cadastro
        FROM reciclagems rec
        INNER JOIN veiculo ON rec.veiculo_id = veiculo.id
        INNER JOIN tipo_veiculo tv ON veiculo.tipo_veiculo_id = tv.id
        INNER JOIN reciclagem_recursos rr ON rr.reciclagem_id = rec.id
        INNER JOIN recursos recurso ON rr.recurso_id = recurso.id
        INNER JOIN tipo_recursos categoria ON recurso.tipo_recurso_id = categoria.id
        INNER JOIN clientes_eventos_contratos cec ON rec.cliente_evento_contrato_id = cec.id
        INNER JOIN eventos evento ON cec.evento_id = evento.id
        INNER JOIN comunidades local ON evento.local_acao = local.id
        WHERE 1=1
          #{status_condition}
          #{tipo_veiculo_condition}
          #{placa_condition}
          #{recurso_condition}
          #{local_condition}
          #{date_condition}
        GROUP BY local.id, tv.id, categoria.id, veiculo.id, rec.id
        ORDER BY rec.id DESC
      SQL

      execute_query(sql, :geral)
    end

    # RR - Por Tipo de Residuo
    def por_tipo_residuo
      sql = <<-SQL.squish
        SELECT
          tv.descricao as veiculo_tipo,
          veiculo.placa as placa,
          categoria.nome as recurso_tipo,
          SUM(rr.quantidade) as quantidade_total,
          SUM(rr.bonus_valor) as bonus_total,
          rec.data_cadastro as data_cadastro
        FROM reciclagems rec
        INNER JOIN veiculo ON rec.veiculo_id = veiculo.id
        INNER JOIN tipo_veiculo tv ON veiculo.tipo_veiculo_id = tv.id
        INNER JOIN reciclagem_recursos rr ON rr.reciclagem_id = rec.id
        INNER JOIN recursos recurso ON rr.recurso_id = recurso.id
        INNER JOIN tipo_recursos categoria ON recurso.tipo_recurso_id = categoria.id
        INNER JOIN clientes_eventos_contratos cec ON rec.cliente_evento_contrato_id = cec.id
        INNER JOIN eventos evento ON cec.evento_id = evento.id
        INNER JOIN comunidades local ON evento.local_acao = local.id
        WHERE 1=1
          #{status_condition}
          #{tipo_veiculo_condition}
          #{placa_condition}
          #{recurso_condition}
          #{local_condition}
          #{date_condition}
        GROUP BY tv.id, categoria.id, veiculo.id, rec.id
        ORDER BY rec.id DESC
      SQL

      execute_query(sql, :residuo)
    end

    # RV - Por Veiculo (sem colunas extras)
    def por_veiculo
      sql = <<-SQL.squish
        SELECT
          tv.descricao as veiculo_tipo,
          veiculo.placa as placa,
          SUM(rr.quantidade) as quantidade_total,
          SUM(rr.bonus_valor) as bonus_total,
          rec.data_cadastro as data_cadastro
        FROM reciclagems rec
        INNER JOIN veiculo ON rec.veiculo_id = veiculo.id
        INNER JOIN tipo_veiculo tv ON veiculo.tipo_veiculo_id = tv.id
        INNER JOIN reciclagem_recursos rr ON rr.reciclagem_id = rec.id
        INNER JOIN recursos recurso ON rr.recurso_id = recurso.id
        INNER JOIN tipo_recursos categoria ON recurso.tipo_recurso_id = categoria.id
        INNER JOIN clientes_eventos_contratos cec ON rec.cliente_evento_contrato_id = cec.id
        INNER JOIN eventos evento ON cec.evento_id = evento.id
        INNER JOIN comunidades local ON evento.local_acao = local.id
        WHERE 1=1
          #{status_condition}
          #{tipo_veiculo_condition}
          #{placa_condition}
          #{recurso_condition}
          #{local_condition}
          #{date_condition}
        GROUP BY tv.id, veiculo.id, rec.id
        ORDER BY rec.id DESC
      SQL

      execute_query(sql, :veiculo)
    end

    # RL - Por Local
    def por_local
      sql = <<-SQL.squish
        SELECT
          tv.descricao as veiculo_tipo,
          veiculo.placa as placa,
          local.nome as local_acao,
          SUM(rr.quantidade) as quantidade_total,
          SUM(rr.bonus_valor) as bonus_total,
          rec.data_cadastro as data_cadastro
        FROM reciclagems rec
        INNER JOIN veiculo ON rec.veiculo_id = veiculo.id
        INNER JOIN tipo_veiculo tv ON veiculo.tipo_veiculo_id = tv.id
        INNER JOIN reciclagem_recursos rr ON rr.reciclagem_id = rec.id
        INNER JOIN recursos recurso ON rr.recurso_id = recurso.id
        INNER JOIN tipo_recursos categoria ON recurso.tipo_recurso_id = categoria.id
        INNER JOIN clientes_eventos_contratos cec ON rec.cliente_evento_contrato_id = cec.id
        INNER JOIN eventos evento ON cec.evento_id = evento.id
        INNER JOIN comunidades local ON evento.local_acao = local.id
        WHERE 1=1
          #{status_condition}
          #{tipo_veiculo_condition}
          #{placa_condition}
          #{recurso_condition}
          #{local_condition}
          #{date_condition}
        GROUP BY local.id, tv.id, veiculo.id, rec.id
        ORDER BY rec.id DESC
      SQL

      execute_query(sql, :local)
    end

    def execute_query(sql, tipo)
      results = ActiveRecord::Base.connection.execute(sql)
      results.map do |row|
        base = {
          veiculo_tipo: row['veiculo_tipo'],
          placa: row['placa'],
          quantidade_total: format_currency(row['quantidade_total']),
          bonus_total: format_currency(row['bonus_total']),
          data_cadastro: format_date(row['data_cadastro']&.to_date)
        }

        case tipo
        when :geral
          base[:recurso_tipo] = row['recurso_tipo']
          base[:local_acao] = row['local_acao']
        when :residuo
          base[:recurso_tipo] = row['recurso_tipo']
        when :local
          base[:local_acao] = row['local_acao']
        end

        base
      end
    end

    # ========== Filtros ==========

    def tipo_veiculo_ids
      @tipo_veiculo_ids ||= Array(params[:tipo_veiculo]).reject(&:blank?).map(&:to_i)
    end

    def tipo_veiculo_condition
      return '' if tipo_veiculo_ids.empty?
      "AND tv.id IN (#{tipo_veiculo_ids.join(',')})"
    end

    def placa_ids
      @placa_ids ||= Array(params[:placa]).reject(&:blank?).map(&:to_i)
    end

    def placa_condition
      return '' if placa_ids.empty?
      "AND veiculo.id IN (#{placa_ids.join(',')})"
    end

    def recurso_ids
      @recurso_ids ||= Array(params[:recurso]).reject(&:blank?).map(&:to_i)
    end

    def recurso_condition
      return '' if recurso_ids.empty?
      "AND categoria.id IN (#{recurso_ids.join(',')})"
    end

    def local_ids
      @local_ids ||= Array(params[:local]).reject(&:blank?).map(&:to_i)
    end

    def local_condition
      return '' if local_ids.empty?
      "AND local.id IN (#{local_ids.join(',')})"
    end

    def status_condition
      return "AND rec.status <> 'X'" if status_filter.empty? || status_filter.include?('-X')

      statuses = status_filter.map { |s| "'#{s}'" }.join(',')
      "AND rec.status IN (#{statuses})"
    end

    def date_condition
      conditions = []
      conditions << "AND rec.data_cadastro >= '#{data_inicial.strftime('%Y-%m-%d')} 00:00:00'" if data_inicial.present?
      conditions << "AND rec.data_cadastro <= '#{data_final.strftime('%Y-%m-%d')} 23:59:59'" if data_final.present?
      conditions.join(' ')
    end
  end
end
