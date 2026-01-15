# frozen_string_literal: true

module Serializers
  # Serializa ClienteEventoContrato (participante de evento)
  #
  class ParticipanteSerializer
    class << self
      # Serializa um participante para listagem
      # @param cec [ClienteEventoContrato]
      # @return [Hash]
      def call(cec)
        {
          id: cec.id,
          clienteId: cec.cliente_id,
          clienteNome: cec.cliente&.nome,
          clienteCpf: cec.cliente&.cpf,
          contratoId: cec.contrato_id,
          contratoNumero: cec.contrato&.numero,
          contratoStatus: cec.contrato&.status,
          temReciclagem: cec.reciclagens.exists?,
          dataCadastro: cec.data_cadastro&.iso8601
        }
      end

      # Alias para compatibilidade
      def for_list(cec)
        call(cec)
      end
    end
  end
end
