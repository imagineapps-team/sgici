# frozen_string_literal: true

# Controller para Processos de Importacao
# CRUD completo com transicoes de status e gestao de custos
#
# @see ProcessoImportacao
class ProcessosImportacaoController < ApplicationController
  before_action :set_processo, only: [:show, :edit, :update, :destroy, :aprovar, :transitar, :desembaracar, :finalizar, :cancelar]

  # Status do processo
  STATUSES = ProcessoImportacao::STATUSES

  # Modais de transporte
  MODAIS = ProcessoImportacao::MODAIS

  # Incoterms disponiveis
  INCOTERMS = ProcessoImportacao::INCOTERMS

  # Moedas suportadas
  MOEDAS = {
    'USD' => 'Dólar (USD)',
    'EUR' => 'Euro (EUR)',
    'CNY' => 'Yuan (CNY)',
    'BRL' => 'Real (BRL)',
    'GBP' => 'Libra (GBP)',
    'JPY' => 'Yen (JPY)'
  }.freeze

  # GET /processos_importacao
  def index
    @processos = ProcessoImportacao
                   .includes(:fornecedor, :responsavel, :criado_por)
                   .order(created_at: :desc)

    # Filtros
    @processos = @processos.where(status: params[:status]) if params[:status].present?
    @processos = @processos.where(modal: params[:modal]) if params[:modal].present?
    @processos = @processos.where(fornecedor_id: params[:fornecedor_id]) if params[:fornecedor_id].present?

    if params[:search].present?
      search = "%#{params[:search]}%"
      @processos = @processos.where('numero ILIKE ? OR observacoes ILIKE ?', search, search)
    end

    # Paginacao
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i
    total = @processos.count
    @processos = @processos.offset((page - 1) * per_page).limit(per_page)

    render inertia: 'processos_importacao/ProcessosImportacaoIndex', props: {
      usuario: usuario_json,
      processos: @processos.map { |p| processo_list_json(p) },
      statusOptions: status_options,
      modalOptions: modal_options,
      fornecedoresOptions: fornecedores_options,
      pagination: {
        currentPage: page,
        perPage: per_page,
        total: total,
        totalPages: (total.to_f / per_page).ceil
      },
      filters: {
        status: params[:status],
        modal: params[:modal],
        fornecedorId: params[:fornecedor_id]&.to_i,
        search: params[:search]
      }
    }
  end

  # GET /processos_importacao/:id
  def show
    render inertia: 'processos_importacao/ProcessosImportacaoShow', props: {
      usuario: usuario_json,
      processo: processo_detail_json(@processo),
      comparativoCustos: comparativo_custos(@processo),
      categorias: categorias_para_previstos,
      categoriasReais: categorias_para_reais,
      prestadores: prestadores_para_select,
      custosPrevistosPendentes: custos_previstos_pendentes(@processo),
      podeEditar: @processo.editavel?,
      podeAprovar: @processo.status == 'planejado',
      podeTransitar: @processo.status == 'aprovado',
      podeDesembaracar: @processo.status == 'em_transito',
      podeFinalizar: @processo.status == 'desembaracado',
      podeCancelar: !@processo.status.in?(%w[finalizado cancelado])
    }
  end

  # GET /processos_importacao/new
  def new
    render inertia: 'processos_importacao/ProcessosImportacaoForm', props: form_props(nil)
  end

  # GET /processos_importacao/:id/edit
  def edit
    unless @processo.editavel?
      flash[:alert] = 'Este processo não pode mais ser editado.'
      return redirect_to processos_importacao_path
    end

    render inertia: 'processos_importacao/ProcessosImportacaoForm', props: form_props(@processo)
  end

  # POST /processos_importacao
  def create
    @processo = ProcessoImportacao.new(processo_params)
    @processo.criado_por = current_usuario
    @processo.status = 'planejado'

    ActiveRecord::Base.transaction do
      @processo.save!

      # Salvar custos previstos se enviados
      salvar_custos_previstos(@processo, params[:custos_previstos]) if params[:custos_previstos].present?
    end

    flash[:notice] = "Processo #{@processo.numero} criado com sucesso."
    redirect_to processo_importacao_path(@processo)
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Erro ao criar processo: #{e.record.errors.full_messages.join(', ')}"
    redirect_to new_processo_importacao_path
  end

  # PATCH/PUT /processos_importacao/:id
  def update
    unless @processo.editavel?
      flash[:alert] = 'Este processo não pode mais ser editado.'
      return redirect_to processos_importacao_path
    end

    ActiveRecord::Base.transaction do
      @processo.update!(processo_params)
      @processo.atualizado_por = current_usuario
      @processo.save!

      # Atualizar custos previstos se enviados
      salvar_custos_previstos(@processo, params[:custos_previstos]) if params[:custos_previstos].present?
    end

    flash[:notice] = "Processo #{@processo.numero} atualizado com sucesso."
    redirect_to processo_importacao_path(@processo)
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = "Erro ao atualizar processo: #{e.record.errors.full_messages.join(', ')}"
    redirect_to edit_processo_importacao_path(@processo)
  end

  # DELETE /processos_importacao/:id
  def destroy
    if @processo.status == 'finalizado'
      flash[:alert] = 'Não é possível excluir um processo finalizado.'
      return redirect_to processos_importacao_path
    end

    if @processo.custos_reais.exists?
      flash[:alert] = 'Não é possível excluir: existem custos reais vinculados.'
      return redirect_to processos_importacao_path
    end

    @processo.destroy!
    flash[:notice] = "Processo #{@processo.numero} excluído com sucesso."
    redirect_to processos_importacao_path
  end

  # =====================================================
  # Transicoes de Status
  # =====================================================

  # POST /processos_importacao/:id/aprovar
  def aprovar
    if @processo.aprovar!(current_usuario)
      render json: { success: true, message: 'Processo aprovado com sucesso.', processo: processo_list_json(@processo.reload) }
    else
      render json: { success: false, message: 'Não foi possível aprovar o processo.' }, status: :unprocessable_entity
    end
  end

  # POST /processos_importacao/:id/transitar
  def transitar
    if @processo.iniciar_transito!(current_usuario)
      render json: { success: true, message: 'Processo em trânsito.', processo: processo_list_json(@processo.reload) }
    else
      render json: { success: false, message: 'Não foi possível iniciar o trânsito.' }, status: :unprocessable_entity
    end
  end

  # POST /processos_importacao/:id/desembaracar
  def desembaracar
    data = params[:data].present? ? Date.parse(params[:data]) : Date.current

    if @processo.registrar_desembaraco!(current_usuario, data: data)
      render json: { success: true, message: 'Desembaraço registrado com sucesso.', processo: processo_list_json(@processo.reload) }
    else
      render json: { success: false, message: 'Não foi possível registrar o desembaraço.' }, status: :unprocessable_entity
    end
  end

  # POST /processos_importacao/:id/finalizar
  def finalizar
    if @processo.finalizar!(current_usuario)
      render json: { success: true, message: 'Processo finalizado com sucesso.', processo: processo_list_json(@processo.reload) }
    else
      render json: { success: false, message: 'Não foi possível finalizar o processo.' }, status: :unprocessable_entity
    end
  end

  # POST /processos_importacao/:id/cancelar
  def cancelar
    motivo = params[:motivo].presence || 'Cancelado pelo usuário'

    if @processo.cancelar!(current_usuario, motivo: motivo)
      render json: { success: true, message: 'Processo cancelado.', processo: processo_list_json(@processo.reload) }
    else
      render json: { success: false, message: 'Não foi possível cancelar o processo.' }, status: :unprocessable_entity
    end
  end

  # =====================================================
  # Autocompletes
  # =====================================================

  # GET /processos_importacao/autocomplete_fornecedores
  def autocomplete_fornecedores
    query = params[:q].to_s.strip
    return render json: [] if query.length < 2

    fornecedores = Fornecedor
                     .where('nome ILIKE :q OR cnpj ILIKE :q', q: "%#{query}%")
                     .where(ativo: true)
                     .limit(20)
                     .map { |f| { id: f.id, nome: f.nome, pais: f.pais, cnpj: f.cnpj } }

    render json: fornecedores
  end

  # GET /processos_importacao/autocomplete_responsaveis
  def autocomplete_responsaveis
    query = params[:q].to_s.strip
    return render json: [] if query.length < 2

    usuarios = Usuario
                 .where('nome ILIKE :q OR login ILIKE :q', q: "%#{query}%")
                 .where(ativo: true)
                 .limit(20)
                 .map { |u| { id: u.id, nome: u.nome, login: u.login } }

    render json: usuarios
  end

  private

  def set_processo
    @processo = ProcessoImportacao.find(params[:id])
  end

  def processo_params
    params.require(:processo_importacao).permit(
      :fornecedor_id, :responsavel_id, :pais_origem, :modal, :incoterm,
      :moeda, :valor_fob, :taxa_cambio,
      :porto_origem, :porto_destino, :aeroporto_origem, :aeroporto_destino,
      :numero_bl, :numero_container,
      :data_embarque_prevista, :data_chegada_prevista, :data_entrega_prevista,
      :observacoes
    )
  end

  # =====================================================
  # Helpers de Props
  # =====================================================

  def form_props(processo)
    {
      usuario: usuario_json,
      processo: processo ? processo_form_json(processo) : nil,
      fornecedoresOptions: fornecedores_options,
      responsaveisOptions: responsaveis_options,
      prestadoresOptions: prestadores_options,
      categoriasOptions: categorias_options,
      statusOptions: status_options,
      modalOptions: modal_options,
      incotermOptions: incoterm_options,
      moedaOptions: moeda_options,
      paisesOptions: paises_options
    }
  end

  # =====================================================
  # Helpers de JSON
  # =====================================================

  def usuario_json
    current_usuario.as_json(only: [:id, :login, :nome])
  end

  # JSON para listagem (compacto)
  def processo_list_json(processo)
    # Calcula situacao em dias (positivo = dias faltantes, negativo = dias atrasado)
    situacao_dias = calcular_situacao_dias(processo)

    {
      id: processo.id,
      numero: processo.numero,
      status: processo.status,
      statusLabel: STATUSES[processo.status],
      modal: processo.modal,
      modalLabel: MODAIS[processo.modal],
      fornecedor: {
        id: processo.fornecedor.id,
        nome: processo.fornecedor.nome,
        pais: processo.fornecedor.pais
      },
      responsavel: processo.responsavel ? {
        id: processo.responsavel.id,
        nome: processo.responsavel.nome
      } : nil,
      valorFob: processo.valor_fob&.to_f,
      moeda: processo.moeda,
      paisOrigem: processo.pais_origem,
      dataEmbarquePrevista: processo.data_embarque_prevista&.iso8601,
      dataChegadaPrevista: processo.data_chegada_prevista&.iso8601,
      custoPrevistoTotal: processo.custo_previsto_total&.to_f,
      custoRealTotal: processo.custo_real_total&.to_f,
      desvioPercentual: processo.desvio_percentual&.to_f,
      atrasado: processo.atrasado?,
      diasAtraso: processo.dias_atraso,
      situacaoDias: situacao_dias,
      editavel: processo.editavel?,
      createdAt: processo.created_at.iso8601,
      updatedAt: processo.updated_at.iso8601
    }
  end

  # Calcula dias faltantes ou atrasados
  # Retorna: positivo = dias faltantes, negativo = dias atrasado, nil = sem data ou não aplicável
  #
  # Regras:
  # - Finalizado/Cancelado: nil (não aplicável)
  # - Desembaracado: nil (já chegou, situação não relevante)
  # - Se tem data_chegada_real: calcula atraso/antecipação em relação ao previsto
  # - Senão: calcula dias até chegada prevista a partir de hoje
  def calcular_situacao_dias(processo)
    return nil unless processo.data_chegada_prevista
    return nil if processo.status.in?(%w[finalizado cancelado desembaracado])

    # Se já tem data de chegada real, calcula diferença com previsto
    if processo.data_chegada_real.present?
      # Negativo = chegou atrasado, Positivo = chegou antes do previsto
      (processo.data_chegada_prevista - processo.data_chegada_real).to_i
    else
      # Dias até a chegada prevista (positivo = faltam dias, negativo = atrasado)
      (processo.data_chegada_prevista - Date.current).to_i
    end
  end

  # JSON para formulario
  def processo_form_json(processo)
    {
      id: processo.id,
      numero: processo.numero,
      fornecedorId: processo.fornecedor_id,
      responsavelId: processo.responsavel_id,
      paisOrigem: processo.pais_origem,
      modal: processo.modal,
      incoterm: processo.incoterm,
      moeda: processo.moeda,
      valorFob: processo.valor_fob&.to_f,
      taxaCambio: processo.taxa_cambio&.to_f,
      portoOrigem: processo.porto_origem,
      portoDestino: processo.porto_destino,
      aeroportoOrigem: processo.aeroporto_origem,
      aeroportoDestino: processo.aeroporto_destino,
      numeroBl: processo.numero_bl,
      numeroContainer: processo.numero_container,
      dataEmbarquePrevista: processo.data_embarque_prevista&.iso8601,
      dataChegadaPrevista: processo.data_chegada_prevista&.iso8601,
      dataEntregaPrevista: processo.data_entrega_prevista&.iso8601,
      observacoes: processo.observacoes
    }
  end

  # JSON para visualizacao detalhada
  def processo_detail_json(processo)
    processo_list_json(processo).merge(
      incoterm: processo.incoterm,
      taxaCambio: processo.taxa_cambio&.to_f,
      portoOrigem: processo.porto_origem,
      portoDestino: processo.porto_destino,
      aeroportoOrigem: processo.aeroporto_origem,
      aeroportoDestino: processo.aeroporto_destino,
      numeroBl: processo.numero_bl,
      numeroAwb: processo.numero_awb,
      numeroContainer: processo.numero_container,
      numeroDi: processo.numero_di,
      numeroDuimp: processo.numero_duimp,
      dataEmbarqueReal: processo.data_embarque_real&.iso8601,
      dataChegadaReal: processo.data_chegada_real&.iso8601,
      dataDesembaraco: processo.data_desembaraco&.iso8601,
      dataEntregaPrevista: processo.data_entrega_prevista&.iso8601,
      dataEntregaReal: processo.data_entrega_real&.iso8601,
      dataFinalizacao: processo.data_finalizacao&.iso8601,
      leadTimeDias: processo.lead_time_dias,
      desvioAbsoluto: processo.desvio_absoluto&.to_f,
      observacoes: processo.observacoes,
      bloqueadoEm: processo.bloqueado_em&.iso8601,
      criadoPor: {
        id: processo.criado_por.id,
        nome: processo.criado_por.nome
      },
      atualizadoPor: processo.atualizado_por ? {
        id: processo.atualizado_por.id,
        nome: processo.atualizado_por.nome
      } : nil,
      custosPrevistos: processo.custos_previstos.includes(:categoria_custo).map { |c| custo_previsto_json(c) },
      custosReais: processo.custos_reais.includes(:categoria_custo, :prestador_servico).map { |c| custo_real_json(c) },
      eventosLogisticos: processo.eventos_logisticos.order(data_evento: :desc).map { |e| evento_logistico_json(e) },
      prestadores: processo.prestadores_servico.map { |p| { id: p.id, nome: p.nome, tipo: p.tipo } },
      totalAnexos: processo.anexos.count
    )
  end

  def custo_previsto_json(custo)
    {
      id: custo.id,
      categoriaId: custo.categoria_custo_id,
      categoria: { id: custo.categoria_custo.id, nome: custo.categoria_custo.nome },
      descricao: custo.descricao,
      moeda: custo.moeda,
      valor: custo.valor&.to_f,
      valorBrl: custo.valor_brl&.to_f,
      taxaCambio: custo.taxa_cambio&.to_f,
      dataPrevisao: custo.data_previsao&.iso8601,
      realizado: custo.realizado?,
      createdAt: custo.created_at.iso8601
    }
  end

  def custo_real_json(custo)
    {
      id: custo.id,
      categoria: { id: custo.categoria_custo.id, nome: custo.categoria_custo.nome },
      prestador: custo.prestador_servico ? { id: custo.prestador_servico.id, nome: custo.prestador_servico.nome } : nil,
      custoPrevisto: custo.custo_previsto ? { id: custo.custo_previsto.id } : nil,
      descricao: custo.descricao,
      moeda: custo.moeda,
      valor: custo.valor&.to_f,
      valorBrl: custo.valor_brl&.to_f,
      taxaCambio: custo.taxa_cambio&.to_f,
      dataLancamento: custo.data_lancamento&.iso8601,
      numeroDocumento: custo.numero_documento,
      dataVencimento: custo.data_vencimento&.iso8601,
      dataPagamento: custo.data_pagamento&.iso8601
    }
  end

  def evento_logistico_json(evento)
    {
      id: evento.id,
      tipo: evento.tipo,
      tipoLabel: EventoLogistico::TIPOS[evento.tipo] || evento.tipo,
      descricao: evento.descricao,
      dataEvento: evento.data_evento&.iso8601,
      localEvento: evento.local,
      observacoes: evento.observacoes,
      registradoPor: { id: evento.criado_por.id, nome: evento.criado_por.nome },
      createdAt: evento.created_at.iso8601
    }
  end

  # =====================================================
  # Helpers de Options
  # =====================================================

  def status_options
    STATUSES.map { |k, v| { value: k, label: v } }
  end

  def modal_options
    MODAIS.map { |k, v| { value: k, label: v } }
  end

  def incoterm_options
    INCOTERMS.map { |i| { value: i, label: i } }
  end

  def moeda_options
    MOEDAS.map { |k, v| { value: k, label: v } }
  end

  def fornecedores_options
    Fornecedor.where(ativo: true).order(:nome).map do |f|
      { value: f.id, label: f.nome }
    end
  end

  def responsaveis_options
    Usuario.where(status: 'A').order(:nome).map do |u|
      { value: u.id, label: u.nome }
    end
  end

  def prestadores_options
    PrestadorServico.where(ativo: true).order(:nome).map do |p|
      { value: p.id, label: "#{p.nome} (#{p.tipo})" }
    end
  end

  def categorias_options
    CategoriaCusto.where(ativo: true).order(:ordem, :nome).map do |c|
      { value: c.id, label: c.nome }
    end
  end

  # Categorias disponíveis para custos previstos (formato completo para modal)
  def categorias_para_previstos
    CategoriaCusto
      .ativos
      .para_previstos
      .ordenados
      .map do |cat|
        {
          id: cat.id,
          nome: cat.nome,
          codigo: cat.codigo,
          grupo: cat.grupo,
          grupoNome: cat.grupo_nome,
          obrigatorio: cat.obrigatorio
        }
      end
  end

  # Categorias disponíveis para custos reais (formato completo para modal)
  def categorias_para_reais
    CategoriaCusto
      .ativos
      .para_reais
      .ordenados
      .map do |cat|
        {
          id: cat.id,
          nome: cat.nome,
          codigo: cat.codigo,
          grupo: cat.grupo,
          grupoNome: cat.grupo_nome,
          obrigatorio: cat.obrigatorio
        }
      end
  end

  # Prestadores para select no modal de custo real
  def prestadores_para_select
    PrestadorServico
      .where(ativo: true)
      .order(:nome)
      .map do |p|
        {
          id: p.id,
          nome: p.nome,
          tipo: p.tipo
        }
      end
  end

  # Custos previstos que ainda não foram vinculados a custos reais
  def custos_previstos_pendentes(processo)
    # IDs de custos previstos já vinculados
    vinculados_ids = processo.custos_reais.where.not(custo_previsto_id: nil).pluck(:custo_previsto_id)

    processo.custos_previstos
      .includes(:categoria_custo)
      .where.not(id: vinculados_ids)
      .order(:created_at)
      .map do |cp|
        {
          id: cp.id,
          categoriaId: cp.categoria_custo_id,
          categoria: cp.categoria_custo.nome,
          valorBrl: cp.valor_brl&.to_f,
          label: "#{cp.categoria_custo.nome} - #{ActionController::Base.helpers.number_to_currency(cp.valor_brl, unit: 'R$ ', separator: ',', delimiter: '.')}"
        }
      end
  end

  def paises_options
    # Lista simplificada de paises mais comuns em importacao
    [
      { value: 'China', label: 'China' },
      { value: 'Estados Unidos', label: 'Estados Unidos' },
      { value: 'Alemanha', label: 'Alemanha' },
      { value: 'Japão', label: 'Japão' },
      { value: 'Coreia do Sul', label: 'Coreia do Sul' },
      { value: 'Itália', label: 'Itália' },
      { value: 'França', label: 'França' },
      { value: 'Reino Unido', label: 'Reino Unido' },
      { value: 'Índia', label: 'Índia' },
      { value: 'México', label: 'México' },
      { value: 'Argentina', label: 'Argentina' },
      { value: 'Chile', label: 'Chile' },
      { value: 'Espanha', label: 'Espanha' },
      { value: 'Portugal', label: 'Portugal' },
      { value: 'Taiwan', label: 'Taiwan' },
      { value: 'Vietnã', label: 'Vietnã' },
      { value: 'Tailândia', label: 'Tailândia' },
      { value: 'Outros', label: 'Outros' }
    ]
  end

  # =====================================================
  # Helpers de Custos
  # =====================================================

  def comparativo_custos(processo)
    categorias = CategoriaCusto.where(ativo: true).order(:ordem)

    categorias.map do |cat|
      previsto = processo.custos_previstos.where(categoria_custo_id: cat.id).sum(:valor_brl)
      real = processo.custos_reais.where(categoria_custo_id: cat.id).sum(:valor_brl)
      desvio = real - previsto
      desvio_pct = previsto.positive? ? (desvio / previsto * 100).round(2) : 0

      {
        categoriaId: cat.id,
        categoria: cat.nome,
        previsto: previsto.to_f,
        real: real.to_f,
        desvio: desvio.to_f,
        desvioPercentual: desvio_pct
      }
    end.select { |c| c[:previsto].positive? || c[:real].positive? }
  end

  def salvar_custos_previstos(processo, custos_params)
    return if custos_params.blank?

    custos_params.each do |custo_data|
      custo = processo.custos_previstos.find_or_initialize_by(id: custo_data[:id])
      custo.assign_attributes(
        categoria_custo_id: custo_data[:categoria_custo_id],
        prestador_servico_id: custo_data[:prestador_servico_id],
        descricao: custo_data[:descricao],
        moeda: custo_data[:moeda] || 'BRL',
        valor: custo_data[:valor],
        taxa_cambio: custo_data[:taxa_cambio] || 1,
        data_previsao: custo_data[:data_previsao],
        criado_por: current_usuario
      )
      custo.save!
    end
  end
end
