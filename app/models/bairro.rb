# frozen_string_literal: true

class Bairro < ApplicationRecord
  self.table_name = 'bairros'

  belongs_to :cidade, foreign_key: 'cidade_id'
  has_many :contratos, foreign_key: 'bairro_id'
  has_many :comunidades, foreign_key: 'bairro_id'
  has_many :instituicaos, foreign_key: 'bairro_id'
  has_many :parceiros, foreign_key: 'bairro_id'
  has_many :recicladors, foreign_key: 'bairro_id'

  validates :nome, presence: { message: 'Nome deve ser preenchido' }
  validates :cidade_id, presence: { message: 'Cidade deve ser selecionada' }

  scope :ordered, -> { order(:nome) }

  before_save :upcase_nome

  private

  def upcase_nome
    self.nome = nome.upcase if nome.present?
  end
end
