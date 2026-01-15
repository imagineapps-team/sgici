# frozen_string_literal: true

class CreateMessageDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :message_deliveries do |t|
      # Identificação
      t.string :channel, null: false        # email, sms, push
      t.string :provider, null: false       # aws_ses, zenvia, firebase
      t.string :recipient, null: false      # email ou telefone

      # Contexto (polimórfico)
      t.references :deliverable, polymorphic: true, index: true
      # Ex: deliverable_type: 'Reciclagem', deliverable_id: 123

      # Payload
      t.string :subject                     # assunto (email)
      t.text :body                          # corpo da mensagem
      t.jsonb :metadata, default: {}        # dados extras (mailer_class, mailer_method, etc)

      # Status e Tracking
      t.string :status, default: 'pending', null: false  # pending, processing, delivered, failed
      t.integer :attempts, default: 0       # tentativas de envio
      t.string :external_id                 # ID do provider (SES Message ID, etc)
      t.text :error_message                 # mensagem de erro se falhou
      t.datetime :delivered_at              # quando foi entregue
      t.datetime :failed_at                 # quando falhou definitivamente

      t.timestamps
    end

    add_index :message_deliveries, :status
    add_index :message_deliveries, :channel
    add_index :message_deliveries, [:status, :channel]
    add_index :message_deliveries, :created_at
  end
end
