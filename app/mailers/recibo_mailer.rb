# frozen_string_literal: true

class ReciboMailer < ApplicationMailer
  # Email de recibo individual
  # Aceita reciclagem_id para permitir serialização em background jobs
  def recibo_individual(reciclagem_id:, destinatario:)
    @reciclagem = Reciclagem.find(reciclagem_id)
    @cliente = @reciclagem.cliente
    @evento = @reciclagem.evento
    @recursos = @reciclagem.reciclagem_recursos.includes(:recurso)

    mail(
      to: destinatario,
      subject: "Recibo de Reciclagem Nº #{@reciclagem.codigo}"
    )
  end

  # Email de recibo em lote (para parceiro)
  # Aceita reciclagem_ids para permitir serialização em background jobs
  def recibo_lote(reciclagem_ids:, destinatario:)
    @reciclagens = Reciclagem.where(id: reciclagem_ids)
    @total_registros = @reciclagens.size
    @total_bonus = @reciclagens.sum(:bonus_total)

    # Agrupa informações
    @resumo = @reciclagens.includes(:cliente, reciclagem_recursos: :recurso).map do |r|
      {
        codigo: r.codigo,
        cliente: r.cliente&.nome,
        data: r.data_cadastro&.strftime('%d/%m/%Y %H:%M'),
        bonus: r.bonus_total || 0,
        recursos: r.reciclagem_recursos.map do |rr|
          "#{rr.recurso&.nome}: #{rr.quantidade}"
        end
      }
    end

    mail(
      to: destinatario,
      subject: "Recibos de Reciclagem - #{@total_registros} registro(s)"
    )
  end
end
