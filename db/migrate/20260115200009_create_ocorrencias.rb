# frozen_string_literal: true

class CreateOcorrencias < ActiveRecord::Migration[8.1]
  def change
    create_table :ocorrencias do |t|
      t.references :processo_importacao, null: false, foreign_key: true
      t.references :criado_por, null: false, foreign_key: { to_table: :usuarios }
      t.references :responsavel, foreign_key: { to_table: :usuarios }

      t.string :tipo, null: false # atraso, avaria, extravio, documentacao, aduaneira, financeira, outro
      t.string :gravidade, null: false, default: 'media' # baixa, media, alta, critica
      t.string :titulo, null: false
      t.text :descricao, null: false
      t.date :data_ocorrencia, null: false
      t.date :data_resolucao
      t.string :status, null: false, default: 'aberta' # aberta, em_analise, resolvida, cancelada
      t.text :resolucao
      t.decimal :impacto_financeiro, precision: 15, scale: 2
      t.integer :impacto_dias_atraso

      t.timestamps
    end

    add_index :ocorrencias, [:processo_importacao_id, :status]
    add_index :ocorrencias, :tipo
    add_index :ocorrencias, :gravidade
    add_index :ocorrencias, :status
    add_index :ocorrencias, :data_ocorrencia
  end
end
