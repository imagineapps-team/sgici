# frozen_string_literal: true

module Serializers
  # Serializa Reciclagem para API
  #
  class ReciclagemSerializer
    STATUSES = {
      'R' => 'Recebido',
      'T' => 'Triado',
      'P' => 'Processado',
      'E' => 'Entregue',
      'C' => 'Cancelado'
    }.freeze

    class << self
      # Serializa uma reciclagem para listagem
      # @param reciclagem [Reciclagem]
      # @return [Hash]
      def for_list(reciclagem)
        cec = reciclagem.cliente_evento_contrato

        {
          id: reciclagem.id,
          codigo: reciclagem.codigo,
          status: reciclagem.status,
          statusLabel: STATUSES[reciclagem.status] || reciclagem.status,
          dataCadastro: reciclagem.data_cadastro&.iso8601,
          bonusTotal: reciclagem.bonus_total || 0,
          clienteNome: cec&.cliente&.nome,
          contratoNumero: cec&.contrato&.numero,
          eventoId: cec&.evento_id
        }
      end

      # Serializa uma reciclagem com detalhes completos
      # @param reciclagem [Reciclagem]
      # @return [Hash]
      def for_detail(reciclagem)
        cec = reciclagem.cliente_evento_contrato

        for_list(reciclagem).merge(
          clienteEventoContratoId: reciclagem.cliente_evento_contrato_id,
          veiculoId: reciclagem.veiculo_id,
          veiculoNome: reciclagem.veiculo&.descricao_completa,
          clienteId: cec&.cliente_id,
          contratoId: cec&.contrato_id,
          eventoNome: evento_nome(cec&.evento),
          contratoOrigemId: reciclagem.contrato_origem_id,
          contratoOrigemNumero: reciclagem.contrato_origem&.numero,
          contratoOrigemNome: reciclagem.contrato_origem&.nomeTitular,
          eDoacao: reciclagem.respond_to?(:doacao?) ? reciclagem.doacao? : false,
          itens: itens_json(reciclagem)
        )
      end

      # Serializa um item de reciclagem
      # @param rr [ReciclagemRecurso]
      # @return [Hash]
      def item_json(rr)
        {
          id: rr.id,
          recursoId: rr.recurso_id,
          recursoNome: rr.recurso&.nome_com_unidade,
          unidadeSigla: rr.recurso&.unidade_medida&.sigla,
          recicladorId: rr.reciclador_id,
          recicladorNome: rr.reciclador&.nome,
          quantidade: rr.quantidade,
          bonusValor: rr.bonus_valor,
          vigenciaId: rr.vigencia_id
        }
      end

      private

      def itens_json(reciclagem)
        reciclagem.reciclagem_recursos
                  .includes(recurso: :unidade_medida, reciclador: nil)
                  .map { |rr| item_json(rr) }
      end

      def evento_nome(evento)
        return nil unless evento

        "#{evento.acao&.nome} - #{evento.comunidade&.nome}"
      end
    end
  end
end
