# frozen_string_literal: true

module Relatorios
  class HistoricoResiduosQuery < BaseQuery
    MESES = {
      1 => 'Janeiro',
      2 => 'Fevereiro',
      3 => 'Março',
      4 => 'Abril',
      5 => 'Maio',
      6 => 'Junho',
      7 => 'Julho',
      8 => 'Agosto',
      9 => 'Setembro',
      10 => 'Outubro',
      11 => 'Novembro',
      12 => 'Dezembro'
    }.freeze

    def execute
      case modelo
      when 'RT'
        residuos_tipologia
      else
        residuos_reciclagem
      end
    end

    private

    # RR - Resíduos da Reciclagem (detalhado por reciclagem individual)
    def residuos_reciclagem
      query = base_query
        .select(
          'comunidades.nome as local',
          'bairros.nome as bairro',
          'cidades.nome as cidade',
          'contratos.numero as nuc',
          'contratos."nomeTitular" as titular',
          'reciclagems.codigo as rec_codigo',
          'tipo_recursos.nome as recurso_tipo',
          'recursos.nome as recurso_nome',
          'reciclagem_recursos.quantidade as rr_total_peso',
          'reciclagem_recursos.bonus_valor as rr_total_bonus',
          '(tipo_recursos.indice * reciclagem_recursos.quantidade) as kwh_eco',
          'tipo_recursos.indice as recurso_tipo_indice',
          'reciclagems.data_cadastro as rec_data_cadastro',
          'recicladors.nome as reciclador',
          'veiculo.placa as placa',
          'reciclagems.contrato_origem_id',
          'clientes_eventos_contratos.contrato_id',
          'contrato_doador."nomeTitular" as doador_nome'
        )
        .joins(rr_joins)
        .order('reciclagems.data_cadastro DESC')

      query.map do |row|
        {
          local: row.local,
          bairro: row.bairro,
          cidade: row.cidade,
          nuc: row.nuc,
          titular: mask_name_lgpd(row.titular),
          rec_codigo: row.rec_codigo,
          recurso_tipo: row.recurso_tipo,
          recurso_nome: row.recurso_nome,
          rr_total_peso: format_currency(row.rr_total_peso),
          rr_total_bonus: format_currency(row.rr_total_bonus),
          kwh_eco: format_currency(row.kwh_eco),
          recurso_tipo_indice: format_currency(row.recurso_tipo_indice),
          rec_data_cadastro: format_datetime(row.rec_data_cadastro),
          reciclador: row.reciclador,
          placa: row.placa,
          rec_doada: calcula_doacao(row.contrato_origem_id, row.contrato_id),
          doador: mask_name_lgpd(row.doador_nome)
        }
      end
    end

    # RT - Resíduos por Tipologia (agrupado por mês/tipologia/local)
    def residuos_tipologia
      query = base_query
        .select(
          'tipo_recursos.nome as categoria',
          'EXTRACT(YEAR FROM reciclagems.data_cadastro)::integer as ano',
          'EXTRACT(MONTH FROM reciclagems.data_cadastro)::integer as mes',
          'comunidades.nome as local',
          'bairros.nome as bairro',
          'cidades.nome as cidade',
          'SUM(reciclagem_recursos.quantidade) / 1000 as rr_total_peso',
          'SUM(reciclagem_recursos.bonus_valor) as rr_total_bonus',
          'SUM(tipo_recursos.indice * reciclagem_recursos.quantidade) as kwh_eco'
        )
        .joins(rt_joins)
        .group(
          'tipo_recursos.id', 'tipo_recursos.nome',
          'EXTRACT(YEAR FROM reciclagems.data_cadastro)',
          'EXTRACT(MONTH FROM reciclagems.data_cadastro)',
          'comunidades.nome', 'bairros.nome', 'cidades.nome'
        )
        .order('ano DESC, mes DESC')

      query.map do |row|
        {
          categoria: row.categoria,
          mes_nome: "#{MESES[row.mes]} #{row.ano}",
          ano: row.ano,
          mes: row.mes,
          local: row.local,
          bairro: row.bairro,
          cidade: row.cidade,
          rr_total_peso: format_currency(row.rr_total_peso),
          rr_total_bonus: format_currency(row.rr_total_bonus),
          kwh_eco: format_currency(row.kwh_eco)
        }
      end
    end

    # Query base com joins comuns e filtros aplicados
    def base_query
      query = Reciclagem
        .joins(cliente_evento_contrato: [:evento, :contrato])
        .joins('INNER JOIN comunidades ON comunidades.id = eventos.local_acao')
        .joins('INNER JOIN bairros ON bairros.id = comunidades.bairro_id')
        .joins('INNER JOIN cidades ON cidades.id = bairros.cidade_id')
        .joins('INNER JOIN acaos ON acaos.id = eventos.acao_id')
        .joins(reciclagem_recursos_join)
        .joins(tipo_recurso_join)

      # Aplicar filtros
      query = apply_date_filter(query)
      query = apply_acoes_filter(query)
      query = apply_locais_filter(query)
      query = apply_recursos_filter(query)
      query = apply_status_filter(query)

      query
    end

    # Joins específicos para modelo RR (detalhado)
    def rr_joins
      <<-SQL.squish
        LEFT JOIN veiculo ON veiculo.id = reciclagems.veiculo_id
        LEFT JOIN recicladors ON recicladors.id = reciclagem_recursos.reciclador_id
        LEFT JOIN contratos contrato_doador ON contrato_doador.id = reciclagems.contrato_origem_id
      SQL
    end

    # Joins específicos para modelo RT (não precisa de veículo, reciclador, doador)
    def rt_joins
      '' # Apenas os joins da base_query
    end

    # Calcula se a reciclagem foi doada
    def calcula_doacao(contrato_origem_id, contrato_id)
      return 'NÃO' if contrato_origem_id.nil?
      return 'NÃO' if contrato_origem_id == contrato_id
      'SIM'
    end

    # Mascara nome para LGPD (mostra apenas primeiro e último nome)
    def mask_name_lgpd(name)
      return nil if name.blank?
      parts = name.strip.split(/\s+/)
      return parts.first if parts.length == 1
      "#{parts.first} #{parts.last}"
    end

    # Filtro de recursos
    def recursos_ids
      @recursos_ids ||= Array(params[:recursos]).reject(&:blank?).map(&:to_i)
    end

    def apply_recursos_filter(query)
      return query if recursos_ids.empty?
      query.where('recursos.id' => recursos_ids)
    end
  end
end
