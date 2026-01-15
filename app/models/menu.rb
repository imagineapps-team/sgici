# frozen_string_literal: true

class Menu < ApplicationRecord
  self.table_name = 'menus'

  belongs_to :menu_pai, class_name: 'Menu', optional: true
  has_many :submenus, class_name: 'Menu', foreign_key: 'menu_pai_id'
  has_and_belongs_to_many :perfils, join_table: 'menus_perfils'

  scope :ativos, -> { where(ativo: true) }
  scope :raiz, -> { where(menu_pai_id: nil) }
  scope :ordered, -> { order(:ordem) }
end
