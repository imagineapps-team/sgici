# frozen_string_literal: true

require "flipper"
require "flipper/adapters/active_record"

# Configuração do Flipper para Feature Flags
#
# Uso:
#   Flipper.enabled?(:nova_feature)
#   Flipper.enable(:nova_feature)
#   Flipper.disable(:nova_feature)
#
# UI disponível em /flipper (apenas admins)
#

Flipper.configure do |config|
  config.default do
    adapter = Flipper::Adapters::ActiveRecord.new
    Flipper.new(adapter)
  end
end

# Adiciona Flipper::Identifier ao AppProfile após o autoloader carregar
Rails.application.config.to_prepare do
  AppProfile.include(Flipper::Identifier) unless AppProfile.included_modules.include?(Flipper::Identifier)

  # Define flipper_id para usar AppProfile como actor
  AppProfile.class_eval do
    def self.flipper_id
      "AppProfile:#{current}"
    end
  end
end
