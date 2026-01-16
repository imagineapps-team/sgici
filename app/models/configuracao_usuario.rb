# frozen_string_literal: true

# ConfiguracaoUsuario - Preferências e configurações do usuário
#
# @attr [Boolean] notificar_email Receber notificações por email
# @attr [Boolean] notificar_sms Receber notificações por SMS
# @attr [String] idioma Idioma preferido
# @attr [String] timezone Fuso horário
#
class ConfiguracaoUsuario < ApplicationRecord
  # Associations
  belongs_to :usuario

  # Validations
  validates :usuario, presence: true, uniqueness: true
  validates :idioma, inclusion: { in: %w[pt-BR en-US es-ES] }, allow_blank: true
  validates :formato_data, inclusion: { in: %w[DD/MM/YYYY MM/DD/YYYY YYYY-MM-DD] }, allow_blank: true
  validates :formato_moeda, inclusion: { in: %w[BRL USD EUR] }, allow_blank: true
  validates :itens_por_pagina, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }, allow_nil: true

  # Callbacks
  after_initialize :definir_padroes

  # Idiomas suportados
  IDIOMAS = {
    'pt-BR' => 'Português (Brasil)',
    'en-US' => 'English (US)',
    'es-ES' => 'Español'
  }.freeze

  # Formatos de data
  FORMATOS_DATA = {
    'DD/MM/YYYY' => '31/12/2026',
    'MM/DD/YYYY' => '12/31/2026',
    'YYYY-MM-DD' => '2026-12-31'
  }.freeze

  # Formatos de moeda
  FORMATOS_MOEDA = {
    'BRL' => 'R$ 1.234,56',
    'USD' => '$1,234.56',
    'EUR' => '€1.234,56'
  }.freeze

  # Timezones brasileiros
  TIMEZONES = {
    'America/Sao_Paulo' => 'Brasília (GMT-3)',
    'America/Manaus' => 'Manaus (GMT-4)',
    'America/Belem' => 'Belém (GMT-3)',
    'America/Fortaleza' => 'Fortaleza (GMT-3)',
    'America/Recife' => 'Recife (GMT-3)',
    'America/Rio_Branco' => 'Rio Branco (GMT-5)'
  }.freeze

  # @return [String] Idioma formatado
  def idioma_nome
    IDIOMAS[idioma] || idioma
  end

  # @return [String] Timezone formatado
  def timezone_nome
    TIMEZONES[timezone] || timezone
  end

  # @return [Boolean] Deve notificar sobre alterações de ETA?
  def notificar_eta?
    notificar_eta_alterado && (notificar_email || notificar_push)
  end

  # @return [Boolean] Deve notificar sobre custos excedidos?
  def notificar_custos?
    notificar_custo_excedido && (notificar_email || notificar_push)
  end

  # @return [Array<String>] Canais de notificação ativos
  def canais_ativos
    canais = []
    canais << 'email' if notificar_email
    canais << 'sms' if notificar_sms
    canais << 'push' if notificar_push
    canais << 'in_app' # Sempre ativo
    canais
  end

  # @return [Hash] Widgets do dashboard
  def widgets
    dashboard_widgets || default_widgets
  end

  # Atualiza widgets do dashboard
  def atualizar_widgets!(novos_widgets)
    update!(dashboard_widgets: novos_widgets)
  end

  # Cria ou retorna configurações para um usuário
  def self.para_usuario(usuario)
    find_or_create_by!(usuario: usuario)
  end

  private

  def definir_padroes
    return unless new_record?

    self.idioma ||= 'pt-BR'
    self.timezone ||= 'America/Sao_Paulo'
    self.formato_data ||= 'DD/MM/YYYY'
    self.formato_moeda ||= 'BRL'
    self.itens_por_pagina ||= 25
    self.notificar_email = true if notificar_email.nil?
    self.notificar_push = true if notificar_push.nil?
    self.notificar_eta_alterado = true if notificar_eta_alterado.nil?
    self.notificar_custo_excedido = true if notificar_custo_excedido.nil?
    self.notificar_aprovacao_pendente = true if notificar_aprovacao_pendente.nil?
    self.notificar_processo_atrasado = true if notificar_processo_atrasado.nil?
    self.notificar_ocorrencia = true if notificar_ocorrencia.nil?
  end

  def default_widgets
    {
      'processos_ativos' => { enabled: true, position: 1 },
      'custos_mes' => { enabled: true, position: 2 },
      'alertas' => { enabled: true, position: 3 },
      'grafico_evolucao' => { enabled: true, position: 4 }
    }
  end
end
