# frozen_string_literal: true

class CreateAprovacoes < ActiveRecord::Migration[8.1]
  def change
    create_table :aprovacoes do |t|
      t.references :processo_importacao, null: false, foreign_key: true
      t.references :solicitado_por, null: false, foreign_key: { to_table: :usuarios }
      t.references :aprovador, foreign_key: { to_table: :usuarios }

      t.string :tipo, null: false, default: 'aprovacao_processo' # aprovacao_processo, aprovacao_custo, aprovacao_pagamento
      t.string :status, null: false, default: 'pendente' # pendente, aprovado, rejeitado, cancelado
      t.datetime :data_solicitacao, null: false
      t.datetime :data_resposta
      t.text :justificativa_solicitacao
      t.text :justificativa_resposta
      t.decimal :valor_referencia, precision: 15, scale: 2

      # Para aprovação de custos específicos
      t.references :custo_previsto, foreign_key: true
      t.references :custo_real, foreign_key: true

      t.timestamps
    end

    add_index :aprovacoes, [:processo_importacao_id, :status]
    add_index :aprovacoes, :tipo
    add_index :aprovacoes, :status
    add_index :aprovacoes, [:aprovador_id, :status]
  end
end
