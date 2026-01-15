# frozen_string_literal: true

class Historico < ApplicationRecord
  self.table_name = 'historicos'

  belongs_to :cliente
  belongs_to :contrato
  belongs_to :evento, optional: true
  belongs_to :projeto, optional: true
  belongs_to :modulo, optional: true
end
