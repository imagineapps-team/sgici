# frozen_string_literal: true

module Api
  module V1
    # Controller de Eventos para API mobile
    # Endpoints: listar, detalhar, gerenciar participantes
    #
    class EventosController < Api::V1::BaseController
      before_action :set_evento, only: [:show, :participantes, :adicionar_participante, :remover_participante, :alterar_status]

      # GET /api/v1/eventos
      # Parâmetros: page, per_page, status
      def index
        eventos = Evento.includes(:acao, :comunidade)
                        .order(data_inicial: :desc)

        # Filtro por status
        eventos = eventos.where(status: params[:status]) if params[:status].present?

        # Paginação simples
        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 20).to_i.clamp(1, 100)
        total = eventos.count
        eventos = eventos.offset((page - 1) * per_page).limit(per_page)

        json_success(
          eventos.map { |e| Serializers::EventoSerializer.for_list(e) },
          meta: { total: total, page: page, per_page: per_page }
        )
      end

      # GET /api/v1/eventos/:id
      def show
        json_success(Serializers::EventoSerializer.for_detail(@evento))
      end

      # GET /api/v1/eventos/:id/participantes
      # Parâmetros: page, per_page
      def participantes
        service = ReciclagemService.new(current_api_user)
        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 10).to_i.clamp(1, 100)

        result = service.listar_participantes(@evento.id, page: page, per_page: per_page)

        if result.success?
          json_success(
            result[:records].map { |p| Serializers::ParticipanteSerializer.call(p) },
            meta: {
              total: result[:total],
              page: result[:page],
              per_page: result[:per_page]
            }
          )
        else
          json_error(result.errors.join(', '))
        end
      end

      # POST /api/v1/eventos/:id/adicionar_participante
      # Body: { cliente_id: 1, contrato_id: 2 }
      def adicionar_participante
        service = ReciclagemService.new(current_api_user)
        result = service.adicionar_participante(
          evento_id: @evento.id,
          cliente_id: params[:cliente_id],
          contrato_id: params[:contrato_id]
        )

        if result.success?
          json_success(Serializers::ParticipanteSerializer.call(result.data), status: :created)
        else
          json_error(result.errors.join(', '))
        end
      end

      # DELETE /api/v1/eventos/:id/remover_participante
      # Parâmetros: participante_id
      def remover_participante
        service = ReciclagemService.new(current_api_user)
        result = service.remover_participante(params[:participante_id])

        if result.success?
          json_success(nil, meta: { message: 'Participante removido com sucesso' })
        else
          json_error(result.errors.join(', '))
        end
      end

      # PUT /api/v1/eventos/:id/alterar_status
      # Body: { status: "F" } (F=aberto, C=fechado)
      def alterar_status
        service = ReciclagemService.new(current_api_user)
        result = service.alterar_status_evento(@evento.id, params[:status])

        if result.success?
          json_success(Serializers::EventoSerializer.for_detail(result.data))
        else
          json_error(result.errors.join(', '))
        end
      end

      private

      def set_evento
        @evento = Evento.find(params[:id])
      end
    end
  end
end
