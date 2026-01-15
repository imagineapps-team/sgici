# frozen_string_literal: true

module Relatorios
  class BaseQuery
    attr_reader :params

    # Labels de status de reciclagem
    STATUS_LABELS = {
      'R' => 'Recebido',
      'T' => 'Transmitido',
      'P' => 'Processado',
      'X' => 'Cancelado',
      'N' => 'Nao Transmitido'
    }.freeze

    def initialize(params = {})
      @params = params.symbolize_keys
    end

    def execute
      raise NotImplementedError, 'Subclasses devem implementar o metodo execute'
    end

    protected

    # ========== Formatacao ==========

    def format_currency(value)
      return '0,00' if value.nil?
      ActionController::Base.helpers.number_with_precision(value, precision: 2, separator: ',', delimiter: '.')
    end

    def format_integer(value)
      return 0 if value.nil?
      value.to_i
    end

    def format_date(date, format = '%d/%m/%Y')
      return nil if date.nil?
      date.strftime(format)
    end

    def format_datetime(datetime)
      return nil if datetime.nil?
      datetime.strftime('%d/%m/%Y as %H:%M')
    end

    def status_label(status)
      STATUS_LABELS[status] || status
    end

    # ========== Parsing ==========

    def parse_date(date_string)
      return nil if date_string.blank?
      Date.parse(date_string)
    rescue ArgumentError
      nil
    end

    def parse_currency(value)
      return 0.0 if value.blank?
      value.to_s.gsub('.', '').gsub(',', '.').to_f
    end

    # ========== Filtros Comuns ==========

    def data_inicial
      @data_inicial ||= parse_date(params[:data_inicial])
    end

    def data_final
      @data_final ||= parse_date(params[:data_final])
    end

    def acoes_ids
      @acoes_ids ||= Array(params[:acoes]).reject(&:blank?).map(&:to_i)
    end

    def locais_ids
      @locais_ids ||= Array(params[:locais]).reject(&:blank?).map(&:to_i)
    end

    def eventos_ids
      @eventos_ids ||= Array(params[:eventos]).reject(&:blank?).map(&:to_i)
    end

    def contratos_ids
      @contratos_ids ||= Array(params[:contratos]).reject(&:blank?).map(&:to_i)
    end

    def codigo_reciclagem
      @codigo_reciclagem ||= params[:codigo].presence
    end

    def status_filter
      @status_filter ||= Array(params[:status]).reject(&:blank?)
    end

    def modelo
      @modelo ||= params[:modelo] || 'RT'
    end

    # ========== Aplicacao de Filtros ==========

    def apply_date_filter(query, field = 'reciclagems.data_cadastro')
      query = query.where("#{field} >= ?", data_inicial.beginning_of_day) if data_inicial.present?
      query = query.where("#{field} <= ?", data_final.end_of_day) if data_final.present?
      query
    end

    def apply_status_filter(query, field = 'reciclagems.status')
      return query if status_filter.empty?

      if status_filter.include?('-X')
        query.where.not(field => 'X')
      else
        query.where(field => status_filter)
      end
    end

    def apply_acoes_filter(query, field = 'acaos.id')
      return query if acoes_ids.empty?
      query.where(field => acoes_ids)
    end

    def apply_locais_filter(query, field = 'comunidades.id')
      return query if locais_ids.empty?
      query.where(field => locais_ids)
    end

    def apply_eventos_filter(query, field = 'eventos.id')
      return query if eventos_ids.empty?
      query.where(field => eventos_ids)
    end

    def apply_contratos_filter(query, field = 'contratos.id')
      return query if contratos_ids.empty?
      query.where(field => contratos_ids)
    end

    def apply_codigo_filter(query, field = 'reciclagems.codigo')
      return query if codigo_reciclagem.blank?
      query.where(field => codigo_reciclagem)
    end

    # ========== Joins Comuns ==========

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

    def usuario_join
      'LEFT JOIN n_log ON n_log.registro_id = reciclagems.id AND n_log.tabela = \'reciclagems\' AND n_log.acao = \'insert\'
       LEFT JOIN usuarios ON usuarios.id = n_log.usuario_id'
    end

    def local_acao_joins
      'INNER JOIN comunidades ON comunidades.id = eventos.local_acao
       LEFT JOIN bairros ON bairros.id = comunidades.bairro_id
       LEFT JOIN cidades ON cidades.id = bairros.cidade_id'
    end
  end
end
