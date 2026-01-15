# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('AWS_SES_EMAIL_FROM', 'suporte@imagineapps.com.br')
  layout 'mailer'
end
