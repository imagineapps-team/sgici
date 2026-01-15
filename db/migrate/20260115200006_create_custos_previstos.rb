# frozen_string_literal: true

class CreateCustosPrevistos < ActiveRecord::Migration[8.1]
  def change
    create_table :custos_previstos do |t|
      t.references :processo_importacao, null: false, foreign_key: true
      t.references :categoria_custo, null: false, foreign_key: true
      t.references :criado_por, null: false, foreign_key: { to_table: :usuarios }

      t.string :descricao
      t.decimal :valor, precision: 15, scale: 2, null: false
      t.string :moeda, limit: 3, null: false, default: 'BRL'
      t.decimal :taxa_cambio, precision: 10, scale: 4
      t.decimal :valor_brl, precision: 15, scale: 2 # Valor convertido para BRL
      t.date :data_previsao
      t.text :observacoes
      t.string :base_calculo # percentual_fob, valor_fixo, por_kg, por_m3, por_container

      # Para cálculos percentuais
      t.decimal :percentual, precision: 8, scale: 4
      t.decimal :valor_referencia, precision: 15, scale: 2

      t.timestamps
    end

    add_index :custos_previstos, [:processo_importacao_id, :categoria_custo_id],
              name: 'idx_custos_previstos_processo_categoria'
  end
end
