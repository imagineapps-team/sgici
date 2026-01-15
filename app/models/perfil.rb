# frozen_string_literal: true

class Perfil < ApplicationRecord
  self.table_name = 'perfils'

  STATUSES = { 'A' => 'Ativo', 'I' => 'Inativo' }.freeze
  ADMIN_PERFIS = %w[ADMINISTRADOR DIRETORIA GERENTE].freeze

  has_many :usuarios, foreign_key: 'perfil_id'
  has_and_belongs_to_many :menus, join_table: 'menus_perfils'

  validates :nome, presence: { message: 'Nome deve ser preenchido' }

  scope :ordered, -> { order(:nome) }
  scope :ativos, -> { where(status: 'A') }

  def status_label
    STATUSES[status] || status
  end

  def acesso_total?
    ADMIN_PERFIS.include?(nome&.upcase)
  end
end
