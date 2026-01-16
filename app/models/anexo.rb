# frozen_string_literal: true

# Anexo - Documentos anexados (polimórfico)
#
# Pode ser anexado a:
# - ProcessoImportacao
# - CustoReal
# - Ocorrencia
#
# @attr [String] nome Nome do arquivo
# @attr [String] tipo_documento Tipo do documento
# @attr [String] numero_documento Número do documento
#
class Anexo < ApplicationRecord
  # Associations
  belongs_to :anexavel, polymorphic: true
  belongs_to :enviado_por, class_name: 'Usuario'

  # Active Storage
  has_one_attached :arquivo

  # Validations
  validates :anexavel, presence: true
  validates :enviado_por, presence: true
  validates :nome, presence: true, length: { maximum: 255 }
  validates :tipo_documento, inclusion: { in: %w[invoice packing_list bl awb di duimp certificado_origem laudo nota_fiscal outro] }, allow_blank: true
  validates :arquivo, presence: true, on: :create

  # Validação de tamanho e tipo do arquivo
  validate :arquivo_valido

  # Scopes
  scope :por_tipo, ->(tipo) { where(tipo_documento: tipo) }
  scope :invoices, -> { where(tipo_documento: 'invoice') }
  scope :bls, -> { where(tipo_documento: 'bl') }
  scope :notas_fiscais, -> { where(tipo_documento: 'nota_fiscal') }
  scope :recentes, -> { order(created_at: :desc) }

  # Callbacks
  before_save :atualizar_metadados

  # Tipos de documento
  TIPOS_DOCUMENTO = {
    'invoice' => 'Invoice/Fatura Comercial',
    'packing_list' => 'Packing List',
    'bl' => 'Bill of Lading (BL)',
    'awb' => 'Air Waybill (AWB)',
    'di' => 'Declaração de Importação (DI)',
    'duimp' => 'DUIMP',
    'certificado_origem' => 'Certificado de Origem',
    'laudo' => 'Laudo/Certificado',
    'nota_fiscal' => 'Nota Fiscal',
    'outro' => 'Outro'
  }.freeze

  # Tipos de arquivo permitidos
  TIPOS_PERMITIDOS = %w[
    application/pdf
    image/jpeg
    image/png
    image/gif
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    text/xml
    application/xml
  ].freeze

  # Tamanho máximo em bytes (10MB)
  TAMANHO_MAXIMO = 10.megabytes

  # @return [String] Tipo formatado
  def tipo_documento_nome
    TIPOS_DOCUMENTO[tipo_documento] || tipo_documento&.humanize || 'Documento'
  end

  # @return [String] Tamanho formatado
  def tamanho_formatado
    return nil unless tamanho_bytes.present?

    if tamanho_bytes < 1.kilobyte
      "#{tamanho_bytes} bytes"
    elsif tamanho_bytes < 1.megabyte
      "#{(tamanho_bytes / 1.kilobyte.to_f).round(1)} KB"
    else
      "#{(tamanho_bytes / 1.megabyte.to_f).round(2)} MB"
    end
  end

  # @return [String] Extensão do arquivo
  def extensao
    File.extname(nome).delete('.').downcase
  end

  # @return [Boolean] É uma imagem?
  def imagem?
    content_type&.start_with?('image/')
  end

  # @return [Boolean] É um PDF?
  def pdf?
    content_type == 'application/pdf'
  end

  # @return [String] URL para download
  def url_download
    return nil unless arquivo.attached?

    Rails.application.routes.url_helpers.rails_blob_path(arquivo, disposition: 'attachment')
  end

  # @return [String] URL para visualização
  def url_preview
    return nil unless arquivo.attached?

    Rails.application.routes.url_helpers.rails_blob_path(arquivo, disposition: 'inline')
  end

  private

  def arquivo_valido
    return unless arquivo.attached?

    unless arquivo.blob.byte_size <= TAMANHO_MAXIMO
      errors.add(:arquivo, "deve ter no máximo #{TAMANHO_MAXIMO / 1.megabyte}MB")
    end

    unless TIPOS_PERMITIDOS.include?(arquivo.blob.content_type)
      errors.add(:arquivo, 'tipo de arquivo não permitido')
    end
  end

  def atualizar_metadados
    return unless arquivo.attached?

    self.content_type = arquivo.blob.content_type
    self.tamanho_bytes = arquivo.blob.byte_size
    self.checksum = arquivo.blob.checksum
    self.arquivo_key = arquivo.blob.key
  end
end
