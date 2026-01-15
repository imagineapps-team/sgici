# frozen_string_literal: true

module Serializers
  # Serializa Evento para API
  #
  class EventoSerializer
    class << self
      # Serializa um evento para listagem
      # @param evento [Evento]
      # @return [Hash]
      def for_list(evento)
        {
          id: evento.id,
          status: evento.status,
          statusLabel: status_label(evento.status),
          dataInicial: evento.data_inicial&.iso8601,
          dataFinal: evento.data_final&.iso8601,
          acaoId: evento.acao_id,
          acaoNome: evento.acao&.nome,
          comunidadeId: evento.comunidade&.id,
          comunidadeNome: evento.comunidade&.nome,
          descricao: descricao_completa(evento),
          participantesCount: evento.cliente_evento_contratos.count,
          totalReciclagens: count_reciclagens(evento)
        }
      end

      # Serializa um evento com detalhes completos
      # @param evento [Evento]
      # @return [Hash]
      def for_detail(evento)
        for_list(evento).merge(
          itinerante: evento.itinerante,
          moduloId: evento.modulo_id,
          participantesCount: evento.cliente_evento_contratos.count,
          totalReciclagens: count_reciclagens(evento),
          recicladorId: evento.recicladores.first&.id,
          recicladorNome: evento.recicladores.first&.nome,
          dataCadastro: evento.data_cadastro&.iso8601
        )
      end

      # Serializa para dropdown/select
      # @param evento [Evento]
      # @return [Hash]
      def for_select(evento)
        {
          value: evento.id,
          label: descricao_completa(evento),
          status: evento.status,
          dataInicial: evento.data_inicial&.strftime('%Y-%m-%d'),
          dataFinal: evento.data_final&.strftime('%Y-%m-%d')
        }
      end

      private

      def status_label(status)
        case status
        when 'F' then 'Aberto'
        when 'C' then 'Fechado'
        else 'Desconhecido'
        end
      end

      def descricao_completa(evento)
        data_str = evento.data_inicial&.strftime('%d/%m/%Y')
        "#{evento.acao&.nome} - #{evento.comunidade&.nome} (#{data_str})"
      end

      def count_reciclagens(evento)
        Reciclagem.joins(:cliente_evento_contrato)
                  .where(clientes_eventos_contratos: { evento_id: evento.id })
                  .count
      end
    end
  end
end
