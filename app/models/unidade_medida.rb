# frozen_string_literal: true

class UnidadeMedida < ApplicationRecord
  self.table_name = 'unidade_medidas'

  has_many :recursos, foreign_key: 'unidade_medida_id'

  validates :nome, presence: { message: 'Nome deve ser preenchido' }
  validates :sigla, presence: { message: 'Sigla deve ser preenchida' }
  validates :nome, uniqueness: { message: 'Este nome já foi utilizado' }
  validates :sigla, uniqueness: { message: 'Esta sigla já foi utilizada' }

  scope :ordered, -> { order(:nome) }
end
