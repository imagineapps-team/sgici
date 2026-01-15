# frozen_string_literal: true

require "ostruct"

# Sistema de branding configurável via ENV
#
# Configurado via ENV:
#   BRANDING_APP_NAME="EcoEnel Bahia"
#   BRANDING_LOGO_URL=https://cdn.example.com/logo.png
#   BRANDING_PRIMARY_COLOR=#2563EB
#
# Uso:
#   Branding.app_name       # => "EcoEnel Bahia"
#   Branding.logo_url       # => "https://..."
#   Branding.primary_color  # => "#2563EB"
#   Branding.to_h           # => Hash para frontend
#
class Branding
  class << self
    # Configuração completa de branding
    # @return [OpenStruct]
    def config
      @config ||= OpenStruct.new(
        # Identidade
        app_name: ENV.fetch("BRANDING_APP_NAME", AppProfile.name),
        logo_url: ENV.fetch("BRANDING_LOGO_URL", "/images/logo.png"),
        logo_white_url: ENV.fetch("BRANDING_LOGO_WHITE_URL", "/images/logo-white.png"),
        favicon_url: ENV.fetch("BRANDING_FAVICON_URL", "/favicon.ico"),

        # Cores (Tailwind compatible)
        primary_color: ENV.fetch("BRANDING_PRIMARY_COLOR", "#3B82F6"),
        secondary_color: ENV.fetch("BRANDING_SECONDARY_COLOR", "#10B981"),
        accent_color: ENV.fetch("BRANDING_ACCENT_COLOR", "#F59E0B"),

        # Textos
        footer_text: ENV.fetch("BRANDING_FOOTER_TEXT", "© AVSI Brasil"),
        support_email: ENV.fetch("BRANDING_SUPPORT_EMAIL", "suporte@avsi.org.br"),
        support_phone: ENV.fetch("BRANDING_SUPPORT_PHONE", ""),

        # Assets externos (S3/CloudFront)
        assets_base_url: ENV.fetch("BRANDING_ASSETS_URL", "")
      )
    end

    # Limpa cache (útil para testes)
    def reset!
      @config = nil
    end

    # Atalhos para propriedades comuns
    def app_name = config.app_name
    def logo_url = config.logo_url
    def logo_white_url = config.logo_white_url
    def favicon_url = config.favicon_url
    def primary_color = config.primary_color
    def secondary_color = config.secondary_color
    def accent_color = config.accent_color
    def footer_text = config.footer_text
    def support_email = config.support_email

    # Para passar ao frontend via Inertia
    # @return [Hash]
    def to_h
      config.to_h
    end
  end
end
