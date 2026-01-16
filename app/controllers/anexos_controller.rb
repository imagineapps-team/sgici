# frozen_string_literal: true

# Controller para Anexos (upload de documentos)
# Funciona de forma polimórfica com ProcessoImportacao, Ocorrencia e CustoReal
class AnexosController < ApplicationController
  before_action :set_anexavel
  before_action :set_anexo, only: [:show, :destroy]

  # GET /processos_importacao/:processo_importacao_id/anexos
  def index
    @anexos = @anexavel.anexos.includes(:enviado_por).order(created_at: :desc)

    render json: {
      anexos: @anexos.map { |a| anexo_json(a) },
      tiposDocumento: Anexo::TIPOS_DOCUMENTO.map { |k, v| { value: k, label: v } }
    }
  end

  # GET /processos_importacao/:processo_importacao_id/anexos/:id
  def show
    if @anexo.arquivo.attached?
      redirect_to rails_blob_path(@anexo.arquivo, disposition: params[:download] ? 'attachment' : 'inline')
    else
      render json: { error: 'Arquivo nao encontrado' }, status: :not_found
    end
  end

  # POST /processos_importacao/:processo_importacao_id/anexos
  def create
    @anexo = @anexavel.anexos.build(anexo_params)
    @anexo.enviado_por = current_usuario
    @anexo.nome = anexo_params[:arquivo]&.original_filename if anexo_params[:arquivo].present?

    if @anexo.save
      render json: {
        success: true,
        message: 'Documento anexado com sucesso.',
        anexo: anexo_json(@anexo)
      }
    else
      render json: {
        success: false,
        message: 'Erro ao anexar documento.',
        errors: @anexo.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /processos_importacao/:processo_importacao_id/anexos/:id
  def destroy
    @anexo.destroy!
    render json: {
      success: true,
      message: 'Documento removido com sucesso.'
    }
  rescue StandardError => e
    render json: {
      success: false,
      message: e.message
    }, status: :unprocessable_entity
  end

  private

  def set_anexavel
    if params[:processo_importacao_id]
      @anexavel = ProcessoImportacao.find(params[:processo_importacao_id])
    elsif params[:ocorrencia_id]
      @anexavel = Ocorrencia.find(params[:ocorrencia_id])
    elsif params[:custo_real_id]
      @anexavel = CustoReal.find(params[:custo_real_id])
    else
      render json: { error: 'Recurso pai nao especificado' }, status: :bad_request
    end
  end

  def set_anexo
    @anexo = @anexavel.anexos.find(params[:id])
  end

  def anexo_params
    params.require(:anexo).permit(:arquivo, :tipo_documento, :numero_documento, :observacoes)
  end

  def anexo_json(anexo)
    {
      id: anexo.id,
      nome: anexo.nome,
      tipoDocumento: anexo.tipo_documento,
      tipoDocumentoLabel: anexo.tipo_documento_nome,
      numeroDocumento: anexo.numero_documento,
      contentType: anexo.content_type,
      tamanho: anexo.tamanho_formatado,
      tamanhoBytes: anexo.tamanho_bytes,
      enviadoPor: {
        id: anexo.enviado_por.id,
        nome: anexo.enviado_por.nome
      },
      createdAt: anexo.created_at.iso8601,
      urlDownload: anexo.arquivo.attached? ? rails_blob_path(anexo.arquivo, disposition: 'attachment') : nil,
      urlPreview: anexo.arquivo.attached? ? rails_blob_path(anexo.arquivo, disposition: 'inline') : nil,
      imagem: anexo.imagem?,
      pdf: anexo.pdf?,
      extensao: anexo.extensao
    }
  end
end
