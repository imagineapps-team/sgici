class Usuario < ApplicationRecord
  # Mapeia o campo 'senha' da tabela legada para o Devise
  alias_attribute :encrypted_password, :senha

  STATUSES = { 'A' => 'Ativo', 'I' => 'Inativo' }.freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable

  belongs_to :perfil, foreign_key: 'perfil_id', optional: true

  # Validações customizadas (removido :validatable pois email pode ser nulo)
  validates :login, presence: { message: 'Login deve ser preenchido' },
                    uniqueness: { message: 'Login já cadastrado' }
  validates :nome, presence: { message: 'Nome deve ser preenchido' }
  validates :perfil_id, presence: { message: 'Perfil deve ser selecionado' }
  validates :status, presence: { message: 'Status deve ser preenchido' },
                     inclusion: { in: STATUSES.keys, message: 'Valor inválido para o campo STATUS' }

  scope :ordered, -> { order(id: :desc) }
  scope :ativos, -> { where(status: 'A') }

  before_save :upcase_fields

  def status_label
    STATUSES[status] || status
  end

  # Sobrescreve validação de senha para usar SHA256 (formato CakePHP legado)
  def valid_password?(password)
    return false if senha.blank?

    password_hash = Digest::SHA256.hexdigest(password)
    ActiveSupport::SecurityUtils.secure_compare(password_hash, senha)
  end

  # Sobrescreve encriptação para usar SHA256 ao invés de bcrypt
  def password=(new_password)
    @password = new_password
    self.senha = Digest::SHA256.hexdigest(new_password) if new_password.present?
  end

  private

  def upcase_fields
    self.nome = nome&.upcase
  end
end
