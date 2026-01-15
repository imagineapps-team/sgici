# frozen_string_literal: true

class Uf < ApplicationRecord
  self.table_name = 'ufs'

  has_many :cidades, foreign_key: 'uf_id'
  has_many :contratos, foreign_key: 'uf_id'

  validates :sigla, presence: true
  validates :nome, presence: true
end
