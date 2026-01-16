# frozen_string_literal: true

# AuditLog - Registro de auditoria para todas as entidades
#
# @attr [String] acao Ação realizada
# @attr [JSON] dados_anteriores Estado anterior
# @attr [JSON] dados_novos Estado novo
# @attr [JSON] campos_alterados Lista de campos alterados
#
class AuditLog < ApplicationRecord
  # Associations
  belongs_to :auditavel, polymorphic: true
  belongs_to :usuario

  # Validations
  validates :auditavel, presence: true
  validates :usuario, presence: true
  validates :acao, presence: true, inclusion: { in: %w[criar atualizar excluir visualizar exportar aprovar rejeitar login logout] }

  # Scopes
  scope :por_acao, ->(acao) { where(acao: acao) }
  scope :por_entidade, ->(tipo) { where(auditavel_type: tipo) }
  scope :por_usuario, ->(usuario_id) { where(usuario_id: usuario_id) }
  scope :por_periodo, ->(inicio, fim) { where(created_at: inicio..fim) }
  scope :recentes, -> { order(created_at: :desc) }
  scope :hoje, -> { where(created_at: Date.current.all_day) }
  scope :ultima_semana, -> { where(created_at: 1.week.ago..) }

  # Ações
  ACOES = {
    'criar' => 'Criação',
    'atualizar' => 'Atualização',
    'excluir' => 'Exclusão',
    'visualizar' => 'Visualização',
    'exportar' => 'Exportação',
    'aprovar' => 'Aprovação',
    'rejeitar' => 'Rejeição',
    'login' => 'Login',
    'logout' => 'Logout'
  }.freeze

  # @return [String] Ação formatada
  def acao_nome
    ACOES[acao] || acao&.humanize
  end

  # @return [Array<String>] Lista de campos que foram alterados
  def campos_modificados
    campos_alterados || []
  end

  # @return [Hash] Diferenças entre estado anterior e novo
  def diferencas
    return {} unless dados_anteriores.present? && dados_novos.present?

    campos_modificados.each_with_object({}) do |campo, diff|
      diff[campo] = {
        antes: dados_anteriores[campo],
        depois: dados_novos[campo]
      }
    end
  end

  # @return [String] Descrição resumida da alteração
  def descricao_resumida
    case acao
    when 'criar'
      "#{usuario.nome} criou #{auditavel_type.underscore.humanize}"
    when 'atualizar'
      campos = campos_modificados.first(3).join(', ')
      "#{usuario.nome} alterou #{campos}"
    when 'excluir'
      "#{usuario.nome} excluiu #{auditavel_type.underscore.humanize}"
    else
      "#{usuario.nome} realizou #{acao_nome.downcase}"
    end
  end

  # Cria log de auditoria para uma entidade
  #
  # @param entidade [ApplicationRecord] Entidade auditada
  # @param acao [String] Ação realizada
  # @param usuario [Usuario] Usuário que realizou
  # @param dados_anteriores [Hash] Estado anterior (opcional)
  # @param request [ActionDispatch::Request] Request HTTP (opcional)
  def self.registrar!(entidade, acao:, usuario:, dados_anteriores: nil, request: nil)
    create!(
      auditavel: entidade,
      acao: acao,
      usuario: usuario,
      dados_anteriores: dados_anteriores,
      dados_novos: entidade.as_json,
      campos_alterados: entidade.saved_changes.keys - %w[updated_at],
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent
    )
  end
end
