# frozen_string_literal: true

module Api
  module V1
    # Controller de Reciclagens para API mobile
    # Endpoints: CRUD reciclagens, busca de clientes/contratos
    #
    class ReciclagensController < Api::V1::BaseController
      before_action :set_reciclagem, only: [:show, :update, :destroy]

      # GET /api/v1/reciclagens
      # Parâmetros: evento_id (obrigatório), page, per_page
      def index
        evento_id = params[:evento_id]
        return json_error('evento_id é obrigatório', status: :bad_request) unless evento_id.present?

        reciclagens = Reciclagem
          .joins(:cliente_evento_contrato)
          .where(clientes_eventos_contratos: { evento_id: evento_id })
          .includes(cliente_evento_contrato: [:cliente, :contrato])
          .order(data_cadastro: :desc)

        # Paginação
        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 20).to_i.clamp(1, 100)
        total = reciclagens.count
        reciclagens = reciclagens.offset((page - 1) * per_page).limit(per_page)

        json_success(
          reciclagens.map { |r| Serializers::ReciclagemSerializer.for_list(r) },
          meta: { total: total, page: page, per_page: per_page }
        )
      end

      # GET /api/v1/reciclagens/:id
      def show
        json_success(Serializers::ReciclagemSerializer.for_detail(@reciclagem))
      end

      # POST /api/v1/reciclagens
      # Body: { reciclagem: { cliente_evento_contrato_id, veiculo_id }, itens: [...] }
      def create
        service = ReciclagemService.new(current_api_user)
        result = service.criar_reciclagem(reciclagem_params, params[:itens])

        if result.success?
          json_success(Serializers::ReciclagemSerializer.for_detail(result.data), status: :created)
        else
          json_error('Falha ao criar reciclagem', errors: result.errors)
        end
      end

      # PUT /api/v1/reciclagens/:id
      # Body: { reciclagem: { veiculo_id, status }, itens: [...] }
      def update
        service = ReciclagemService.new(current_api_user)
        result = service.atualizar_reciclagem(@reciclagem, reciclagem_params, params[:itens])

        if result.success?
          json_success(Serializers::ReciclagemSerializer.for_detail(result.data))
        else
          json_error('Falha ao atualizar reciclagem', errors: result.errors)
        end
      end

      # DELETE /api/v1/reciclagens/:id
      def destroy
        service = ReciclagemService.new(current_api_user)
        result = service.remover_reciclagem(@reciclagem)

        if result.success?
          json_success(nil, meta: { message: 'Reciclagem removida com sucesso' })
        else
          json_error(result.errors.join(', '))
        end
      end

      # GET /api/v1/reciclagens/buscar_clientes
      # Parâmetros: q (query, mínimo 3 caracteres)
      def buscar_clientes
        service = ReciclagemService.new(current_api_user)
        clientes = service.buscar_clientes(params[:q].to_s)

        json_success(
          clientes.map { |c| { id: c.id, nome: c.nome, cpf: c.cpf } }
        )
      end

      # GET /api/v1/reciclagens/buscar_contratos
      # Parâmetros: q (query), cliente_id (opcional)
      # Retorna contratos com dados do cliente para facilitar adicao de participante
      def buscar_contratos
        service = ReciclagemService.new(current_api_user)
        contratos = service.buscar_contratos(
          params[:q].to_s,
          cliente_id: params[:cliente_id]
        )

        json_success(
          contratos.map do |c|
            {
              id: c.id,
              numero: c.numero,
              status: c.status,
              clienteId: c.cliente_id,
              clienteNome: c.cliente&.nome,
              clienteCpf: c.cliente&.cpf
            }
          end
        )
      end

      private

      def set_reciclagem
        @reciclagem = Reciclagem.find(params[:id])
      end

      def reciclagem_params
        params.require(:reciclagem).permit(
          :cliente_evento_contrato_id,
          :veiculo_id,
          :status,
          :contrato_origem_id
        )
      end
    end
  end
end
