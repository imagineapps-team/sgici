# frozen_string_literal: true

class CreateFornecedores < ActiveRecord::Migration[8.1]
  def change
    create_table :fornecedores do |t|
      t.string :nome, null: false
      t.string :nome_fantasia
      t.string :cnpj, limit: 18
      t.string :email
      t.string :telefone, limit: 20
      t.string :website
      t.string :pais, null: false, default: 'China'
      t.string :estado
      t.string :cidade
      t.string :endereco
      t.string :cep, limit: 20
      t.string :contato_comercial_nome
      t.string :contato_comercial_email
      t.string :contato_comercial_telefone, limit: 20
      t.string :contato_operacional_nome
      t.string :contato_operacional_email
      t.string :contato_operacional_telefone, limit: 20
      t.text :observacoes
      t.string :moeda_padrao, limit: 3, default: 'USD'
      t.integer :prazo_pagamento_dias, default: 30
      t.decimal :score, precision: 3, scale: 2, default: 0.0
      t.integer :total_processos, default: 0
      t.boolean :ativo, default: true, null: false

      t.timestamps
    end

    add_index :fornecedores, :nome
    add_index :fornecedores, :cnpj, unique: true, where: "cnpj IS NOT NULL AND cnpj != ''"
    add_index :fornecedores, :pais
    add_index :fornecedores, :ativo
  end
end
