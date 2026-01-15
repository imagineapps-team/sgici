# frozen_string_literal: true

module Relatorios
  class CampanhasQuery < BaseQuery
    def execute
      case modelo
      when 'PD'
        participantes_data
      when 'TP'
        totais_participante
      else
        resumo_totais
      end
    end

    private

    # RT - Resumo de Totais (contagem de participantes por campanha)
    def resumo_totais
      sql = <<-SQL.squish
        SELECT
          campanha.id as campanha_id,
          campanha.nome as campanha,
          campanha.data_inicial as dt_ini,
          campanha.data_final as dt_fim,
          COUNT(DISTINCT cc.contrato_id) as total
        FROM contrato_campanhas cc
        INNER JOIN campanhas campanha ON cc.campanha_id = campanha.id
        WHERE 1 = 1
          #{campanhas_condition}
        GROUP BY campanha.id, campanha.nome, campanha.data_inicial, campanha.data_final
        ORDER BY campanha.nome
      SQL

      results = ActiveRecord::Base.connection.execute(sql)
      results.map do |row|
        {
          campanha: row['campanha'],
          dt_ini: format_date(row['dt_ini']&.to_date),
          dt_fim: format_date(row['dt_fim']&.to_date),
          total: row['total'].to_i
        }
      end
    end

    # PD - Participantes x Data de Inscricao (lista detalhada)
    def participantes_data
      sql = <<-SQL.squish
        SELECT
          campanha.nome as campanha,
          contrato.numero as nuc,
          contrato."nomeTitular" as titular,
          cliente.celular as celular,
          COALESCE(cliente.email, '--') as email,
          comunidade.nome as local,
          cc.data_cadastro as data
        FROM contrato_campanhas cc
        INNER JOIN campanhas campanha ON cc.campanha_id = campanha.id
        INNER JOIN contratos contrato ON cc.contrato_id = contrato.id
        LEFT JOIN clientes cliente ON contrato.cliente_id = cliente.id
        LEFT JOIN reciclagems rec ON (cc.model_id = 1 AND cc.registro_id = rec.id)
        LEFT JOIN clientes_eventos_contratos cec ON rec.cliente_evento_contrato_id = cec.id
        LEFT JOIN eventos evento ON cec.evento_id = evento.id
        LEFT JOIN comunidades comunidade ON evento.local_acao = comunidade.id
        WHERE (rec.status IS NULL OR rec.status <> 'X')
          #{campanhas_condition}
          #{date_condition('cc.data_cadastro')}
        ORDER BY campanha.nome, cc.data_cadastro DESC
      SQL

      results = ActiveRecord::Base.connection.execute(sql)
      results.map do |row|
        {
          campanha: row['campanha'],
          nuc: row['nuc'],
          titular: mask_name_lgpd(row['titular']),
          celular: row['celular'],
          email: row['email'],
          local: row['local'],
          data: format_datetime(row['data']&.to_datetime)
        }
      end
    end

    # TP - Totais por Participante (peso/bonus por participante)
    def totais_participante
      sql = <<-SQL.squish
        SELECT
          campanha.nome as campanha,
          comunidade.nome as local,
          contrato.numero as nuc,
          contrato."nomeTitular" as titular,
          cliente.celular as telefone,
          recurso.nome as nome_recurso,
          SUM(rr.quantidade) as total_peso,
          SUM(rr.bonus_valor) as total_bonus
        FROM contrato_campanhas cc
        INNER JOIN campanhas campanha ON cc.campanha_id = campanha.id
        INNER JOIN contratos contrato ON cc.contrato_id = contrato.id
        INNER JOIN clientes_eventos_contratos cec ON cec.contrato_id = cc.contrato_id
        INNER JOIN reciclagems rec ON rec.cliente_evento_contrato_id = cec.id
        LEFT JOIN reciclagem_recursos rr ON rr.reciclagem_id = rec.id
        LEFT JOIN clientes cliente ON cec.cliente_id = cliente.id
        INNER JOIN eventos evento ON cec.evento_id = evento.id
        INNER JOIN comunidades comunidade ON evento.local_acao = comunidade.id
        LEFT JOIN recursos recurso ON rr.recurso_id = recurso.id
        WHERE rec.status <> 'X'
          #{campanhas_condition}
          #{date_condition('rec.data_cadastro')}
        GROUP BY campanha.id, comunidade.id, contrato.id, cliente.id, recurso.id
        ORDER BY campanha.nome, comunidade.nome, contrato.numero
      SQL

      results = ActiveRecord::Base.connection.execute(sql)
      results.map do |row|
        {
          campanha: row['campanha'],
          local: row['local'],
          nuc: row['nuc'],
          titular: mask_name_lgpd(row['titular']),
          telefone: row['telefone'],
          nome_recurso: row['nome_recurso'],
          total_peso: format_currency(row['total_peso']),
          total_bonus: format_currency(row['total_bonus'])
        }
      end
    end

    # Filtro de campanhas
    def campanhas_ids
      @campanhas_ids ||= Array(params[:campanhas]).reject(&:blank?).map(&:to_i)
    end

    def campanhas_condition
      return '' if campanhas_ids.empty?
      "AND campanha.id IN (#{campanhas_ids.join(',')})"
    end

    def date_condition(field)
      conditions = []
      conditions << "AND #{field} >= '#{data_inicial.strftime('%Y-%m-%d')} 00:00:00'" if data_inicial.present?
      conditions << "AND #{field} <= '#{data_final.strftime('%Y-%m-%d')} 23:59:59'" if data_final.present?
      conditions.join(' ')
    end

    # Mascara nome para LGPD (mostra apenas primeiro e ultimo nome)
    def mask_name_lgpd(name)
      return nil if name.blank?
      parts = name.strip.split(/\s+/)
      return parts.first if parts.length == 1
      "#{parts.first} #{parts.last}"
    end
  end
end
