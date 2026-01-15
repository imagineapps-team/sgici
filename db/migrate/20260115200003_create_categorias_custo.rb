# frozen_string_literal: true

class CreateCategoriasCusto < ActiveRecord::Migration[8.1]
  def change
    create_table :categorias_custo do |t|
      t.string :nome, null: false
      t.string :codigo, limit: 20
      t.string :tipo, null: false, default: 'ambos' # previsto, real, ambos
      t.string :grupo # fob, frete, seguro, impostos, armazenagem, outros
      t.text :descricao
      t.integer :ordem, default: 0
      t.boolean :obrigatorio, default: false
      t.boolean :ativo, default: true, null: false

      t.timestamps
    end

    add_index :categorias_custo, :nome, unique: true
    add_index :categorias_custo, :codigo, unique: true, where: "codigo IS NOT NULL AND codigo != ''"
    add_index :categorias_custo, :grupo
    add_index :categorias_custo, :ativo
  end
end
