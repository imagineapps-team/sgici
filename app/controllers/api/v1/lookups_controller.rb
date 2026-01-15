# frozen_string_literal: true

module Api
  module V1
    # Controller para dados de lookup (dropdowns/selects)
    # Fornece listas para popular formulários no mobile
    #
    class LookupsController < Api::V1::BaseController
      # GET /api/v1/lookups/eventos
      # Retorna eventos para dropdown (com filtro opcional por status)
      def eventos
        eventos = Evento.includes(:acao, :comunidade)
                        .order(data_inicial: :desc)
                        .limit(params[:limit] || 100)

        eventos = eventos.where(status: params[:status]) if params[:status].present?

        json_success(
          eventos.map { |e| Serializers::EventoSerializer.for_select(e) }
        )
      end

      # GET /api/v1/lookups/acoes
      # Retorna lista de ações
      def acoes
        acoes = Acao.order(:nome)

        json_success(
          acoes.map { |a| { value: a.id, label: a.nome } }
        )
      end

      # GET /api/v1/lookups/comunidades
      # Retorna lista de comunidades
      def comunidades
        comunidades = Comunidade.order(:nome)

        json_success(
          comunidades.map { |c| { value: c.id, label: c.nome } }
        )
      end

      # GET /api/v1/lookups/veiculos
      # Retorna lista de veículos
      def veiculos
        veiculos = Veiculo.includes(:tipo_veiculo).ordered

        json_success(
          veiculos.map { |v| { value: v.id, label: v.descricao_completa } }
        )
      end

      # GET /api/v1/lookups/recicladores
      # Retorna lista de recicladores ativos
      def recicladores
        recicladores = Reciclador.ativos.order(:nome)

        json_success(
          recicladores.map { |r| { value: r.id, label: r.nome } }
        )
      end

      # GET /api/v1/lookups/recursos
      # Retorna lista de recursos (resíduos) com vigências
      def recursos
        recursos = Recurso.ativos
                          .includes(:vigencias, :unidade_medida)
                          .order(:nome)

        json_success(
          recursos.map do |r|
            vigencias_ativas = r.vigencias.respond_to?(:ativos) ? r.vigencias.ativos : r.vigencias
            {
              value: r.id,
              label: r.nome_com_unidade,
              unidadeSigla: r.unidade_medida&.sigla,
              vigencias: vigencias_ativas.map { |v| { id: v.id, valor: v.valor } }
            }
          end
        )
      end

      # GET /api/v1/lookups/status_reciclagem
      # Retorna lista de status de reciclagem
      def status_reciclagem
        statuses = Reciclagem::STATUSES.map { |k, v| { value: k, label: v } }
        json_success(statuses)
      end

      # GET /api/v1/lookups/vigencias_evento_reciclador
      # Retorna vigências (recursos com valores) para um evento + reciclador
      # Parâmetros: evento_id, reciclador_id
      def vigencias_evento_reciclador
        evento_id = params[:evento_id]
        reciclador_id = params[:reciclador_id]

        return json_error('evento_id é obrigatório', status: :bad_request) unless evento_id.present?
        return json_error('reciclador_id é obrigatório', status: :bad_request) unless reciclador_id.present?

        vigencias = EventoRecicladorVigencia
          .ativos
          .where(evento_id: evento_id, reciclador_id: reciclador_id)
          .includes(vigencia: { recurso: :unidade_medida })

        json_success(
          vigencias.map do |erv|
            v = erv.vigencia
            r = v.recurso
            {
              vigenciaId: v.id,
              recursoId: r&.id,
              recursoNome: r&.nome_com_unidade || r&.nome,
              unidadeSigla: r&.unidade_medida&.sigla,
              valor: v.valor
            }
          end
        )
      end
    end
  end
end
