# frozen_string_literal: true

class CreateProcessosImportacao < ActiveRecord::Migration[8.1]
  def change
    create_table :processos_importacao do |t|
      t.string :numero, null: false
      t.references :fornecedor, null: false, foreign_key: { to_table: :fornecedores }
      t.references :criado_por, null: false, foreign_key: { to_table: :usuarios }
      t.references :responsavel, foreign_key: { to_table: :usuarios }

      # Origem e Destino
      t.string :pais_origem, null: false
      t.string :porto_origem
      t.string :aeroporto_origem
      t.string :porto_destino
      t.string :aeroporto_destino

      # Logística
      t.string :modal, null: false, default: 'maritimo' # maritimo, aereo, rodoviario, multimodal
      t.string :incoterm, limit: 10 # FOB, CIF, EXW, DDP, etc.
      t.string :numero_container
      t.string :numero_bl # Bill of Lading
      t.string :numero_awb # Air Waybill
      t.string :numero_di # Declaração de Importação
      t.string :numero_duimp # DUIMP

      # Valores e Câmbio
      t.string :moeda, limit: 3, null: false, default: 'USD'
      t.decimal :taxa_cambio, precision: 10, scale: 4
      t.date :data_taxa_cambio
      t.decimal :valor_fob, precision: 15, scale: 2, default: 0
      t.decimal :peso_bruto_kg, precision: 12, scale: 3
      t.decimal :peso_liquido_kg, precision: 12, scale: 3
      t.decimal :volume_m3, precision: 10, scale: 3
      t.integer :quantidade_volumes

      # Datas
      t.date :data_criacao
      t.date :data_pedido
      t.date :data_embarque_prevista
      t.date :data_embarque_real
      t.date :data_chegada_prevista # ETA
      t.date :data_chegada_real
      t.date :data_desembaraco
      t.date :data_entrega_prevista
      t.date :data_entrega_real
      t.date :data_finalizacao

      # Status e Controle
      t.string :status, null: false, default: 'planejado' # planejado, aprovado, em_transito, desembaracado, finalizado, cancelado
      t.text :observacoes
      t.text :descricao_mercadoria

      # Custos Consolidados (calculados)
      t.decimal :custo_previsto_total, precision: 15, scale: 2, default: 0
      t.decimal :custo_real_total, precision: 15, scale: 2, default: 0
      t.decimal :desvio_absoluto, precision: 15, scale: 2, default: 0
      t.decimal :desvio_percentual, precision: 8, scale: 2, default: 0

      # Lead Time (calculado)
      t.integer :lead_time_dias

      # Auditoria
      t.references :atualizado_por, foreign_key: { to_table: :usuarios }
      t.datetime :bloqueado_em

      t.timestamps
    end

    add_index :processos_importacao, :numero, unique: true
    add_index :processos_importacao, :status
    add_index :processos_importacao, :modal
    add_index :processos_importacao, :pais_origem
    add_index :processos_importacao, :data_criacao
    add_index :processos_importacao, :data_embarque_prevista
    add_index :processos_importacao, :data_chegada_prevista
    add_index :processos_importacao, [:status, :data_criacao]
  end
end
