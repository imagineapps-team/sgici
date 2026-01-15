# frozen_string_literal: true

class CreateCustosReais < ActiveRecord::Migration[8.1]
  def change
    create_table :custos_reais do |t|
      t.references :processo_importacao, null: false, foreign_key: true
      t.references :categoria_custo, null: false, foreign_key: true
      t.references :prestador_servico, foreign_key: true
      t.references :criado_por, null: false, foreign_key: { to_table: :usuarios }

      t.string :descricao
      t.decimal :valor, precision: 15, scale: 2, null: false
      t.string :moeda, limit: 3, null: false, default: 'BRL'
      t.decimal :taxa_cambio, precision: 10, scale: 4
      t.decimal :valor_brl, precision: 15, scale: 2 # Valor convertido para BRL
      t.date :data_lancamento, null: false
      t.date :data_vencimento
      t.date :data_pagamento
      t.string :status_pagamento, default: 'pendente' # pendente, pago, cancelado
      t.string :numero_documento
      t.string :tipo_documento # nota_fiscal, fatura, boleto, recibo
      t.text :observacoes

      # Comparativo com previsto
      t.references :custo_previsto, foreign_key: true
      t.decimal :desvio_valor, precision: 15, scale: 2
      t.decimal :desvio_percentual, precision: 8, scale: 2

      t.timestamps
    end

    add_index :custos_reais, [:processo_importacao_id, :categoria_custo_id],
              name: 'idx_custos_reais_processo_categoria'
    add_index :custos_reais, :data_lancamento
    add_index :custos_reais, :status_pagamento
    add_index :custos_reais, :numero_documento
  end
end
