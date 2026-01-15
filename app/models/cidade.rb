# frozen_string_literal: true

class Cidade < ApplicationRecord
  self.table_name = 'cidades'

  belongs_to :uf, foreign_key: 'uf_id'
  has_many :bairros, foreign_key: 'cidade_id'

  validates :nome, presence: true
end
