# frozen_string_literal: true

class CreateNotificacoes < ActiveRecord::Migration[8.1]
  def change
    create_table :notificacoes do |t|
      t.references :usuario, null: false, foreign_key: { to_table: :usuarios }
      t.references :notificavel, polymorphic: true

      t.string :tipo, null: false # alerta_eta, alerta_custo, aprovacao_pendente, processo_atrasado, ocorrencia, sistema
      t.string :titulo, null: false
      t.text :mensagem
      t.string :prioridade, default: 'normal' # baixa, normal, alta, urgente
      t.string :canal, default: 'in_app' # in_app, email, sms, push
      t.datetime :lida_em
      t.datetime :enviada_em
      t.string :status, default: 'pendente' # pendente, enviada, lida, arquivada

      t.timestamps
    end

    add_index :notificacoes, [:usuario_id, :status]
    add_index :notificacoes, [:usuario_id, :lida_em]
    add_index :notificacoes, :tipo
    add_index :notificacoes, :prioridade
  end
end
