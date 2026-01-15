# frozen_string_literal: true

class CreateConfiguracoesUsuario < ActiveRecord::Migration[8.1]
  def change
    create_table :configuracoes_usuario do |t|
      t.references :usuario, null: false, foreign_key: { to_table: :usuarios }

      # Preferências de notificação
      t.boolean :notificar_email, default: true
      t.boolean :notificar_sms, default: false
      t.boolean :notificar_push, default: true

      # Tipos de notificação
      t.boolean :notificar_eta_alterado, default: true
      t.boolean :notificar_custo_excedido, default: true
      t.boolean :notificar_aprovacao_pendente, default: true
      t.boolean :notificar_processo_atrasado, default: true
      t.boolean :notificar_ocorrencia, default: true

      # Preferências de interface
      t.string :idioma, default: 'pt-BR'
      t.string :timezone, default: 'America/Sao_Paulo'
      t.string :formato_data, default: 'DD/MM/YYYY'
      t.string :formato_moeda, default: 'BRL'
      t.integer :itens_por_pagina, default: 25

      # Dashboard
      t.json :dashboard_widgets

      t.timestamps
    end

    add_index :configuracoes_usuario, :usuario_id, unique: true
  end
end
