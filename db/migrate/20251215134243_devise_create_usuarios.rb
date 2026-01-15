# frozen_string_literal: true

class DeviseCreateUsuarios < ActiveRecord::Migration[8.1]
  def change
    # Tabela usuarios já existe (migrada do CakePHP legado)
    # Estrutura existente:
    #   - id, login, senha (já é a senha encriptada), perfil_id, nome,
    #   - status, email, push_token, contexto, evento_id
    #
    # Adicionando apenas os campos extras necessários para o Devise

    change_table :usuarios do |t|
      ## Recoverable (reset de senha)
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable (lembrar login)
      t.datetime :remember_created_at

      ## Trackable (opcional - descomente se quiser rastrear logins)
      # t.integer  :sign_in_count, default: 0, null: false
      # t.datetime :current_sign_in_at
      # t.datetime :last_sign_in_at
      # t.string   :current_sign_in_ip
      # t.string   :last_sign_in_ip

      ## Confirmable (opcional - descomente se quiser confirmação por email)
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email

      ## Lockable (opcional - descomente se quiser bloqueio por tentativas)
      # t.integer  :failed_attempts, default: 0, null: false
      # t.string   :unlock_token
      # t.datetime :locked_at
    end

    # Índice para reset de senha
    add_index :usuarios, :reset_password_token, unique: true
  end
end
