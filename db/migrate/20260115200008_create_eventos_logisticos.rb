# frozen_string_literal: true

class CreateEventosLogisticos < ActiveRecord::Migration[8.1]
  def change
    create_table :eventos_logisticos do |t|
      t.references :processo_importacao, null: false, foreign_key: true
      t.references :criado_por, null: false, foreign_key: { to_table: :usuarios }

      t.string :tipo, null: false # embarque, transbordo, chegada_porto, desembaraco, liberacao, entrega, outro
      t.datetime :data_evento, null: false
      t.string :local
      t.string :codigo_local # código do porto/aeroporto
      t.text :descricao
      t.text :observacoes

      # Rastreamento
      t.string :fonte # manual, api_armador, api_cia_aerea
      t.string :numero_tracking
      t.json :dados_rastreamento # dados brutos da API

      # ETA Updates
      t.date :eta_anterior
      t.date :eta_atualizado
      t.integer :dias_atraso

      t.timestamps
    end

    add_index :eventos_logisticos, [:processo_importacao_id, :tipo]
    add_index :eventos_logisticos, :data_evento
    add_index :eventos_logisticos, :tipo
  end
end
