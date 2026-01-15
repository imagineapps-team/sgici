# frozen_string_literal: true

class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :auditavel, polymorphic: true, null: false
      t.references :usuario, null: false, foreign_key: { to_table: :usuarios }

      t.string :acao, null: false # criar, atualizar, excluir, visualizar, exportar, aprovar, rejeitar
      t.string :ip_address
      t.string :user_agent
      t.json :dados_anteriores
      t.json :dados_novos
      t.json :campos_alterados
      t.text :observacao

      t.datetime :created_at, null: false
    end

    add_index :audit_logs, [:auditavel_type, :auditavel_id]
    add_index :audit_logs, :acao
    add_index :audit_logs, :created_at
    add_index :audit_logs, [:usuario_id, :created_at]
  end
end
