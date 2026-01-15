# frozen_string_literal: true

class CreateProcessoPrestadores < ActiveRecord::Migration[8.1]
  def change
    create_table :processo_prestadores do |t|
      t.references :processo_importacao, null: false, foreign_key: true
      t.references :prestador_servico, null: false, foreign_key: true
      t.string :funcao # freight_forwarder, despachante, transportadora, etc.
      t.text :observacoes
      t.boolean :principal, default: false

      t.timestamps
    end

    add_index :processo_prestadores, [:processo_importacao_id, :prestador_servico_id, :funcao],
              unique: true, name: 'idx_processo_prestador_funcao'
  end
end
