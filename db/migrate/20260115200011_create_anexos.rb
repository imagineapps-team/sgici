# frozen_string_literal: true

class CreateAnexos < ActiveRecord::Migration[8.1]
  def change
    create_table :anexos do |t|
      t.references :anexavel, polymorphic: true, null: false
      t.references :enviado_por, null: false, foreign_key: { to_table: :usuarios }

      t.string :nome, null: false
      t.string :tipo_documento # invoice, packing_list, bl, awb, di, certificado_origem, laudo, nota_fiscal, outro
      t.string :numero_documento
      t.date :data_documento
      t.text :descricao
      t.string :content_type
      t.integer :tamanho_bytes
      t.string :checksum

      # Active Storage será usado, mas mantemos metadados aqui
      t.string :arquivo_key # referência ao Active Storage

      t.timestamps
    end

    add_index :anexos, [:anexavel_type, :anexavel_id]
    add_index :anexos, :tipo_documento
    add_index :anexos, :numero_documento
  end
end
