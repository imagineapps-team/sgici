# frozen_string_literal: true

module Messaging
  # Factory para resolver e instanciar adapters de mensageria
  # Centraliza o mapeamento de canais/providers para classes de adapter
  #
  # @example Resolver adapter padrão para email
  #   adapter = AdapterResolver.resolve(:email)
  #   # => Messaging::Email::AwsSesAdapter
  #
  # @example Resolver adapter específico
  #   adapter = AdapterResolver.resolve(:sms, :zenvia)
  #   # => Messaging::Sms::ZenviaAdapter
  class AdapterResolver
    # Mapeamento de canais -> providers -> classes de adapter
    ADAPTERS = {
      email: {
        aws_ses: 'Messaging::Email::AwsSesAdapter'
        # smtp: 'Messaging::Email::SmtpAdapter',     # futuro
        # sendgrid: 'Messaging::Email::SendgridAdapter'  # futuro
      },
      sms: {
        zenvia: 'Messaging::Sms::ZenviaAdapter'
        # twilio: 'Messaging::Sms::TwilioAdapter',   # futuro
        # aws_sns: 'Messaging::Sms::AwsSnsAdapter'   # futuro
      },
      push: {
        # firebase: 'Messaging::Push::FirebaseAdapter'  # futuro
      }
    }.freeze

    # Providers padrão por canal
    DEFAULT_PROVIDERS = {
      email: :aws_ses,
      sms: :zenvia
      # push: :firebase
    }.freeze

    class << self
      # Resolve e instancia um adapter
      #
      # @param channel [Symbol, String] canal (:email, :sms, :push)
      # @param provider [Symbol, String, nil] provider específico (opcional)
      # @return [Messaging::BaseAdapter] instância do adapter
      # @raise [ArgumentError] se canal ou provider inválido
      def resolve(channel, provider = nil)
        channel = channel.to_sym
        provider = (provider || default_provider_for(channel)).to_sym

        adapter_class_name = find_adapter_class(channel, provider)
        adapter_class = adapter_class_name.constantize

        adapter_class.new
      end

      # Retorna o provider padrão para um canal
      #
      # @param channel [Symbol, String] canal
      # @return [Symbol] provider padrão
      # @raise [ArgumentError] se canal não tem provider padrão
      def default_provider_for(channel)
        channel = channel.to_sym
        provider = DEFAULT_PROVIDERS[channel]

        raise ArgumentError, "No default provider for channel: #{channel}" unless provider

        provider
      end

      # Lista todos os canais disponíveis
      #
      # @return [Array<Symbol>] canais disponíveis
      def available_channels
        ADAPTERS.keys
      end

      # Lista providers disponíveis para um canal
      #
      # @param channel [Symbol, String] canal
      # @return [Array<Symbol>] providers disponíveis
      def available_providers_for(channel)
        channel = channel.to_sym
        ADAPTERS[channel]&.keys || []
      end

      # Verifica se um adapter está configurado
      #
      # @param channel [Symbol, String] canal
      # @param provider [Symbol, String, nil] provider (usa default se nil)
      # @return [Boolean] true se configurado
      def configured?(channel, provider = nil)
        adapter = resolve(channel, provider)
        adapter.configured?
      rescue ArgumentError
        false
      end

      private

      def find_adapter_class(channel, provider)
        channel_adapters = ADAPTERS[channel]
        raise ArgumentError, "Unknown channel: #{channel}" unless channel_adapters

        adapter_class_name = channel_adapters[provider]
        raise ArgumentError, "Unknown provider '#{provider}' for channel '#{channel}'" unless adapter_class_name

        adapter_class_name
      end
    end
  end
end
