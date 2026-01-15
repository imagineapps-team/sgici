# frozen_string_literal: true

# Configuração do AWS SES para envio de emails
# Credenciais são carregadas das variáveis de ambiente:
# - AWS_SES_KEY
# - AWS_SES_SECRET
# - AWS_SES_REGION (padrão: us-east-1)
# - AWS_SES_EMAIL_FROM (email remetente)

require 'aws-sdk-ses'

if ENV['AWS_SES_KEY'].present? && ENV['AWS_SES_SECRET'].present?
  Aws.config.update(
    region: ENV.fetch('AWS_SES_REGION', 'us-east-1'),
    credentials: Aws::Credentials.new(
      ENV.fetch('AWS_SES_KEY'),
      ENV.fetch('AWS_SES_SECRET')
    )
  )

  Rails.logger.info "AWS SES configurado para região #{ENV.fetch('AWS_SES_REGION', 'us-east-1')}"
else
  Rails.logger.warn 'AWS SES: Credenciais não configuradas. Emails não serão enviados via SES.'
end
