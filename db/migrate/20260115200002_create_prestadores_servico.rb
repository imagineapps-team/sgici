# frozen_string_literal: true

class CreatePrestadoresServico < ActiveRecord::Migration[8.1]
  def change
    create_table :prestadores_servico do |t|
      t.string :nome, null: false
      t.string :nome_fantasia
      t.string :cnpj, limit: 18
      t.string :tipo, null: false # freight_forwarder, despachante, seguradora, transportadora, armazem, outro
      t.string :email
      t.string :telefone, limit: 20
      t.string :website
      t.string :pais, default: 'Brasil'
      t.string :estado
      t.string :cidade
      t.string :endereco
      t.string :cep, limit: 10
      t.string :contato_nome
      t.string :contato_email
      t.string :contato_telefone, limit: 20
      t.text :observacoes
      t.text :servicos_oferecidos
      t.decimal :score, precision: 3, scale: 2, default: 0.0
      t.integer :total_servicos, default: 0
      t.boolean :ativo, default: true, null: false

      t.timestamps
    end

    add_index :prestadores_servico, :nome
    add_index :prestadores_servico, :cnpj, unique: true, where: "cnpj IS NOT NULL AND cnpj != ''"
    add_index :prestadores_servico, :tipo
    add_index :prestadores_servico, :ativo
  end
end
