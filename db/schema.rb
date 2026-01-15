# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_19_200000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "acaos", id: :serial, force: :cascade do |t|
    t.string "integracao_auto", limit: 1, default: "N"
    t.string "nome", limit: 100, null: false
    t.integer "projeto_id"
    t.integer "tipo_acao_id"

    t.unique_constraint ["nome", "projeto_id"], name: "unique_acaos_nome_projeto"
  end

  create_table "agendamentos", id: :serial, force: :cascade do |t|
    t.string "contato", limit: 45, null: false
    t.date "data", null: false
    t.text "observacao", null: false
    t.integer "refrigerador_id"
    t.string "telefone", limit: 13, null: false
    t.integer "triagem_pngv_id", null: false
    t.string "visita_ok", limit: 1, default: "N", null: false, comment: "S = sim\nN = não"

    t.unique_constraint ["triagem_pngv_id"], name: "unique_agendamentos_triagems"
  end

  create_table "arquivos", id: :serial, force: :cascade do |t|
    t.datetime "data_cadastro", precision: nil, null: false
    t.string "link", limit: 255
    t.string "model", limit: 50, null: false
    t.string "nome", limit: 255, null: false
    t.integer "registro_id", null: false
  end

  create_table "arquivos_eventos", force: :cascade do |t|
    t.integer "evento_id", null: false
    t.string "nome", limit: 100
  end

  create_table "arquivos_triagem_pngd", id: :serial, force: :cascade do |t|
    t.string "nome", limit: 255, null: false
    t.integer "triagem_pngd_id", null: false
  end

  create_table "arquivos_triagems", id: :serial, force: :cascade do |t|
    t.string "nome", limit: 255, null: false
    t.integer "triagem_pngv_id", null: false
  end

  create_table "arquivos_vendas", force: :cascade do |t|
    t.string "nome", limit: 80
    t.integer "venda_id"
  end

  create_table "arquivos_vistoria_pngd", id: :serial, force: :cascade do |t|
    t.string "nome", limit: 255, null: false
    t.integer "vistoria_pngd_id", null: false
  end

  create_table "b_i_forms", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: 0
    t.datetime "updated_at", precision: 0
  end

  create_table "bairros", id: :serial, force: :cascade do |t|
    t.integer "cidade_id", null: false
    t.string "nome", limit: 255, null: false
  end

  create_table "bi_contratos", id: :serial, force: :cascade do |t|
    t.date "data_final", null: false
    t.date "data_inicial", null: false
    t.string "nome", null: false
    t.boolean "permitir_uso_dados_bi", default: false
    t.boolean "permitir_uso_metas_bi", default: false, null: false
  end

  create_table "bi_form_item_bairros", id: :serial, force: :cascade do |t|
    t.integer "bairro_id", null: false
    t.integer "bi_form_item_id", null: false
    t.index ["id"], name: "bi_form_item_bairros_id_uindex", unique: true
  end

  create_table "bi_form_item_cidades", id: :serial, force: :cascade do |t|
    t.integer "bi_form_item_id", null: false
    t.integer "cidade_id", null: false
    t.index ["id"], name: "bi_form_item_cidades_id_uindex", unique: true
  end

  create_table "bi_form_item_comunidades", id: :serial, force: :cascade do |t|
    t.integer "bi_form_item_id", null: false
    t.integer "comunidade_id", null: false
    t.index ["bi_form_item_id", "comunidade_id"], name: "bi_form_item_comunidades_bi_form_item_id_comunidade_id_uindex", unique: true
    t.index ["id"], name: "bi_form_item_comunidades_id_uindex", unique: true
  end

  create_table "bi_form_item_respostas", id: :integer, default: -> { "nextval('bi_form_item_resposta_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "bairro_id"
    t.integer "bi_form_item_id", null: false
    t.integer "bi_form_resposta_id"
    t.integer "bi_select_id"
    t.integer "cidade_id"
    t.integer "comunidade_id"
    t.datetime "data_cadastro", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "valor"
    t.index ["id"], name: "bi_form_item_resposta_id_uindex", unique: true
    t.unique_constraint ["bi_form_item_id", "bi_form_resposta_id"], name: "bi_form_item_respostas_bi_form_item_id_bi_form_resposta_id_key"
  end

  create_table "bi_form_item_selects", id: :serial, force: :cascade do |t|
    t.boolean "enabled", default: true
    t.integer "form_item_id", null: false
    t.string "label"
    t.string "value", null: false
    t.index ["id"], name: "bi_form_item_selects_id_uindex", unique: true
  end

  create_table "bi_form_items", id: :serial, force: :cascade do |t|
    t.integer "bi_form_id", null: false
    t.datetime "data_cadastro", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "disabled", default: false, null: false
    t.string "file_name"
    t.boolean "obrigatorio", default: false, null: false
    t.boolean "searchable", default: false, null: false
    t.string "status", limit: 1, default: "A", null: false
    t.integer "stepper_id"
    t.integer "tamanho"
    t.string "tipo", null: false
    t.string "titulo", null: false
    t.index ["id"], name: "bi_form_items_id_uindex", unique: true
  end

  create_table "bi_form_resposta_reciclagens", id: :serial, force: :cascade do |t|
    t.integer "bi_resposta_id", null: false
    t.integer "reciclagem_id", null: false
    t.index ["bi_resposta_id"], name: "bi_form_resposta_reciclagens_bi_resposta_id_uindex", unique: true
    t.index ["id"], name: "bi_form_resposta_reciclagens_id_uindex", unique: true
    t.index ["reciclagem_id"], name: "bi_form_resposta_reciclagens_reciclagem_id_uindex", unique: true
    t.unique_constraint ["bi_resposta_id"], name: "bi_form_resposta_reciclagens_bi_resposta_id_uk"
    t.unique_constraint ["reciclagem_id"], name: "bi_form_resposta_reciclagens_reciclagem_id_uk"
  end

  create_table "bi_form_respostas", id: :integer, default: -> { "nextval('bi_form_resposta_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "bi_form_id", null: false
    t.datetime "data_cadastro", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "usuario_id", null: false
    t.index ["id"], name: "bi_form_resposta_id_uindex", unique: true
  end

  create_table "bi_form_steppers", id: :serial, force: :cascade do |t|
    t.integer "bi_form_id", null: false
    t.string "status", default: "A", null: false
    t.string "title"
    t.index ["id"], name: "bi_form_steppers_id_uindex", unique: true
  end

  create_table "bi_forms", id: :serial, force: :cascade do |t|
    t.datetime "data_cadastro", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "editavel", default: false, null: false
    t.string "key", null: false
    t.boolean "mobile", default: true, null: false
    t.boolean "mobile_clientes", default: false, null: false
    t.string "nome", null: false
    t.string "status", limit: 1, default: "A", null: false
    t.index ["id"], name: "bi_forms_id_uindex", unique: true
  end

  create_table "bi_metas", id: :serial, force: :cascade do |t|
    t.integer "bi_contrato_id", null: false
    t.float "custo"
    t.date "data", null: false
    t.datetime "data_cadastro", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.float "meta"
    t.float "meta_beneficios", null: false
    t.float "meta_ee", null: false
    t.float "meta_rcb", null: false
    t.float "meta_rdp", null: false
    t.index ["id"], name: "bi_metas_id_uindex", unique: true
  end

  create_table "campanhas", id: :serial, force: :cascade do |t|
    t.datetime "data_final", precision: nil
    t.datetime "data_inicial", precision: nil
    t.integer "modulo_id", null: false
    t.string "nome", limit: 255, null: false
    t.string "status", limit: 1, null: false
  end

  create_table "cidades", id: :integer, default: nil, force: :cascade do |t|
    t.string "nome", limit: 255, null: false
    t.integer "uf_id", null: false
  end

  create_table "cliente_estabelecimento_entregas", id: :integer, default: -> { "nextval('clientes_estabelecimento_entregas_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "cliente_id", null: false
    t.integer "estabelecimento_entrega_id", null: false

    t.unique_constraint ["cliente_id", "estabelecimento_entrega_id"], name: "unique_cliente_estabelecimento_entregas"
  end

  create_table "clientes", id: :serial, force: :cascade do |t|
    t.string "celular", limit: 14
    t.string "como_conheceu", limit: 10, default: "N", comment: "MOBI = MOBILIZAÇAO, INDI = INDICAÇÃO,PUBL = PUBLICIDADE,N  = NÃO SE APLICA,outros = (CAMPO DIGITADO),"
    t.string "conheceTSEE", limit: 1, comment: "S = sim\nN = não"
    t.string "cpf", limit: 11
    t.date "dataNascimento"
    t.datetime "data_cadastro", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.string "documento", limit: 20
    t.string "email", limit: 255
    t.string "estadoCivil", limit: 1, comment: "C = Casado\nS = solteiro\nD = divorciado\nV = viuvo\nU = união estável"
    t.integer "evento_id"
    t.boolean "legado", default: false, null: false
    t.string "nis", limit: 11
    t.string "nome", limit: 120, null: false
    t.string "recebe_fatura", limit: 1, default: "N", null: false
    t.string "regiao", limit: 1, comment: "C - Capital;\nI - Interior;"
    t.integer "rg_uf_id"
    t.string "telefone", limit: 14
    t.string "tipoDocumento", limit: 15, comment: "RG, CNH, CTPS, Passaporte..."
    t.integer "usuario_id"
  end

  create_table "clientes_contratos_projetos", id: :serial, force: :cascade do |t|
    t.integer "cliente_id", null: false
    t.integer "contrato_id", null: false
    t.timestamptz "data_cadastro", default: -> { "timezone('BRT'::text, now())" }, null: false
    t.integer "projeto_id", null: false
  end

  create_table "clientes_evento_entregas", id: :serial, force: :cascade do |t|
    t.integer "cliente_id", null: false
    t.integer "contrato_id"
    t.integer "evento_entrega_id", null: false

    t.unique_constraint ["cliente_id", "contrato_id", "evento_entrega_id"], name: "unique_clientes_evento_entregas"
  end

  create_table "clientes_eventos_contratos", id: :integer, default: -> { "nextval('clientes_eventos_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "cliente_id", null: false
    t.integer "contrato_id", null: false
    t.datetime "data_cadastro", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.integer "evento_id", null: false
    t.boolean "legado", default: false, null: false
    t.integer "modulo_id", null: false
    t.string "status", limit: 1, default: "A"

    t.unique_constraint ["contrato_id", "evento_id", "modulo_id"], name: "unique_clientes_eventos_contratos_contrato_evento_modulo"
  end

  create_table "comunidades", id: :serial, force: :cascade do |t|
    t.integer "acao_id", comment: "Id da ação serve para determinar qual será o local quando ol local for para ação Educativo CV ou Museu"
    t.text "bairro"
    t.integer "bairro_id"
    t.string "cep", limit: 8
    t.text "cidade"
    t.string "complemento", limit: 150
    t.string "latitude", limit: 50
    t.string "logradouro", limit: 100
    t.string "longitude", limit: 50
    t.string "nome", limit: 50, null: false
    t.integer "parceiro_id"
    t.string "status", limit: 1, default: "A", null: false
    t.integer "tipo_id"
    t.text "uf"
    t.integer "uf_id"

    t.unique_constraint ["nome"], name: "comunidades_nome_key"
  end

  create_table "comunidades_tipos", id: :serial, force: :cascade do |t|
    t.string "nome", null: false
    t.index ["id"], name: "comunidades_tipos_id_uindex", unique: true
    t.index ["nome"], name: "comunidades_tipos_nome_uindex", unique: true
  end

  create_table "configuracao", id: :serial, force: :cascade do |t|
    t.string "chave", limit: 20, null: false
    t.integer "modulo_id"
    t.string "valor", limit: 20, null: false

    t.unique_constraint ["chave", "valor"], name: "unique_configuracao"
  end

  create_table "contrato_campanhas", id: :integer, default: -> { "nextval('contratos_campanhas_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "campanha_id", null: false
    t.integer "contrato_id", null: false
    t.datetime "data_cadastro", precision: nil, null: false
    t.integer "model_id", null: false
    t.integer "registro_id", null: false

    t.unique_constraint ["campanha_id", "contrato_id"], name: "unique_campanha_contrato"
  end

  create_table "contratos", id: :serial, force: :cascade do |t|
    t.string "bairro", limit: 255
    t.integer "bairro_id"
    t.string "cep", limit: 8
    t.string "cidade", limit: 255
    t.integer "cliente_id"
    t.string "complemento", limit: 255
    t.integer "contrato_tipo_id", default: 1, null: false
    t.string "cpf_cnpj_titular", limit: 14
    t.datetime "data_cadastro", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.boolean "legado", default: false, null: false
    t.integer "local_cadastro_id"
    t.string "logradouro", limit: 255
    t.string "nomeTitular", limit: 120, null: false
    t.string "numero", limit: 45, null: false
    t.string "numeroMedidor", limit: 20
    t.string "numeroParceiro", limit: 20
    t.string "numero_endereco", limit: 45
    t.text "observacoes"
    t.text "referenciaEndereco"
    t.string "status", limit: 1, default: "A", null: false
    t.string "tensao", limit: 1, comment: "1 = 110v\n2 = 220v"
    t.text "uf"
    t.integer "uf_id"

    t.unique_constraint ["numero"], name: "unique_contrato_numero"
  end

  create_table "contratos_tipos", id: :serial, force: :cascade do |t|
    t.string "nome", limit: 255, null: false
    t.string "status", limit: 1, null: false
  end

  create_table "doacao_historicos", id: :bigint, default: -> { "nextval('doacao_historico_id_seq'::regclass)" }, force: :cascade do |t|
    t.datetime "data_alteracao", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.text "descricao"
    t.integer "usuario_alteracao"
    t.integer "vistoria_pngd_id"
  end

  create_table "doacao_lampada_historicos", id: :serial, force: :cascade do |t|
    t.timestamptz "data_alteracao", default: -> { "timezone('BRT'::text, now())" }, null: false
    t.text "descricao", null: false
    t.text "doacao_lampada_ids", null: false
    t.integer "usuario_alteracao", null: false
  end

  create_table "doacao_lampadas", id: :serial, force: :cascade do |t|
    t.integer "cliente_id", null: false
    t.string "cliente_tipo", limit: 1, null: false, comment: "R = Residencial\nB = Baixa renda"
    t.integer "contrato_id", null: false
    t.datetime "data", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.integer "evento_doacao_lampada_id"
    t.integer "evento_entrega_id"
    t.integer "evento_id"
    t.integer "lampada_id", null: false
    t.integer "modulo_id", null: false
    t.string "nis", limit: 11
    t.string "participa_mev", limit: 1, default: "N", comment: "Campo que serve para o vale luz e define se o cliente participa de projeto M&V\n'S' = Sim ou 'N' = Não"
    t.integer "projeto_id", null: false
    t.integer "quantidade", null: false
    t.integer "servico_id"
    t.check_constraint "participa_mev::text = 'S'::text OR participa_mev::text = 'N'::text", name: "doacao_lampadas_participa_mev_check"
    t.check_constraint "quantidade > 0", name: "unsigned_doacao_lampadas_quantidade"
  end

  create_table "ecoenel_lancamento_historicos", id: :serial, comment: "Historico de movimentacoes dos lancamentos EcoEnel Empresas (auditoria)", force: :cascade do |t|
    t.string "acao", limit: 50, null: false, comment: "Tipo de acao: CRIADO, SUBMETIDO, APROVADO, RECUSADO, EXPIRADO, REENVIADO"
    t.datetime "created", precision: nil, default: -> { "now()" }
    t.integer "ecoenel_lancamento_id", null: false
    t.string "ip_address", limit: 45
    t.text "observacao", comment: "Obrigatorio para RECUSADO (motivo da recusa)"
    t.integer "status_anterior_id"
    t.integer "status_novo_id", null: false
    t.text "user_agent"
    t.integer "usuario_id", null: false
    t.index ["acao"], name: "idx_hist_acao"
    t.index ["created"], name: "idx_hist_created"
    t.index ["ecoenel_lancamento_id"], name: "idx_hist_lancamento"
    t.index ["usuario_id"], name: "idx_hist_usuario"
  end

  create_table "ecoenel_lancamento_residuos", id: :serial, comment: "Residuos/recursos de cada lancamento EcoEnel Empresas", force: :cascade do |t|
    t.datetime "created", precision: nil, default: -> { "now()" }
    t.integer "ecoenel_lancamento_id", null: false
    t.decimal "quantidade", precision: 10, scale: 2, null: false
    t.integer "recurso_id", null: false
    t.decimal "valor_total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "valor_unitario", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["ecoenel_lancamento_id"], name: "idx_ecoenel_res_lancamento"
  end

  create_table "ecoenel_lancamento_status", id: :serial, comment: "Tabela de status para lancamentos EcoEnel Empresas", force: :cascade do |t|
    t.boolean "ativo", default: true
    t.string "codigo", limit: 1, null: false, comment: "Codigo unico do status (S=Submetida, R=Recebida, X=Cancelada)"
    t.string "cor", limit: 20, default: "secondary", comment: "Cor do badge Bootstrap (warning, success, danger, info, primary, secondary)"
    t.datetime "created", precision: nil, default: -> { "now()" }
    t.text "descricao"
    t.datetime "modified", precision: nil, default: -> { "now()" }
    t.string "nome", limit: 50, null: false
    t.integer "ordem", default: 0
    t.index ["ativo"], name: "idx_ecoenel_status_ativo"
    t.index ["codigo"], name: "idx_ecoenel_status_codigo"
    t.unique_constraint ["codigo"], name: "ecoenel_lancamento_status_codigo_key"
  end

  create_table "ecoenel_lancamentos", id: :serial, comment: "Lancamentos de reciclagem EcoEnel Empresas (staging antes de sincronizar com reciclagems)", force: :cascade do |t|
    t.string "codigo", limit: 255, null: false, comment: "Codigo unico do lancamento formato EE-YYYYMMDD-XXXXX"
    t.integer "contrato_id", null: false
    t.datetime "created", precision: nil, default: -> { "now()" }
    t.date "data_expiracao", comment: "Data limite para resposta do reciclador (30 dias apos criacao)"
    t.date "data_reciclagem", null: false
    t.integer "evento_id", null: false
    t.integer "gerador_usuario_id", null: false
    t.datetime "modified", precision: nil, default: -> { "now()" }
    t.boolean "notificacao_20dias_enviada", default: false, comment: "Flag indicando se lembrete de 20 dias foi enviado"
    t.boolean "notificacao_25dias_enviada", default: false, comment: "Flag indicando se alerta de urgencia de 25 dias foi enviado"
    t.boolean "notificacao_criacao_enviada", default: false, comment: "Flag indicando se notificacao de criacao foi enviada ao reciclador"
    t.text "observacoes"
    t.integer "reciclador_id", null: false
    t.integer "reciclador_usuario_id"
    t.integer "reciclagem_id", comment: "Preenchido apos aprovacao - referencia ao registro criado em reciclagems"
    t.integer "status_id", default: 1, null: false
    t.index ["contrato_id"], name: "idx_ecoenel_lanc_contrato"
    t.index ["created"], name: "idx_ecoenel_lanc_created"
    t.index ["data_expiracao"], name: "idx_ecoenel_lanc_expiracao"
    t.index ["evento_id"], name: "idx_ecoenel_lanc_evento"
    t.index ["gerador_usuario_id"], name: "idx_ecoenel_lanc_gerador"
    t.index ["notificacao_20dias_enviada"], name: "idx_ecoenel_lanc_notif_20dias", where: "(notificacao_20dias_enviada = false)"
    t.index ["notificacao_25dias_enviada"], name: "idx_ecoenel_lanc_notif_25dias", where: "(notificacao_25dias_enviada = false)"
    t.index ["reciclador_id"], name: "idx_ecoenel_lanc_reciclador_entidade"
    t.index ["reciclador_usuario_id"], name: "idx_ecoenel_lanc_reciclador_usuario"
    t.index ["status_id"], name: "idx_ecoenel_lanc_status"
  end

  create_table "equipamentos", force: :cascade do |t|
    t.timestamptz "data_cadastro", default: -> { "now()" }, null: false
    t.string "nome", limit: 35
  end

  create_table "esqueci_senha", id: :serial, force: :cascade do |t|
    t.integer "codigo", null: false
    t.datetime "created_at", precision: 0
    t.string "status", limit: 1, default: "A", null: false
    t.datetime "updated_at", precision: 0
    t.integer "usuario_id", null: false
  end

  create_table "estabelecimento_entregas", id: :serial, force: :cascade do |t|
    t.date "data", null: false
    t.integer "estabelecimento_id", null: false
    t.integer "quantidade", null: false
    t.integer "quantidade_atual", null: false
    t.string "turno", limit: 1, null: false, comment: "M = manhã\nT = tarde"

    t.check_constraint "quantidade > 0", name: "unsigned_estabelecimento_entregas_quantidade"
    t.check_constraint "quantidade_atual >= 0", name: "unsigned_estabelecimento_entregas_quantidade_atual"
    t.unique_constraint ["data", "turno", "estabelecimento_id"], name: "unique_estabelecimento_entregas_data_turno_estabelecimento"
  end

  create_table "estabelecimentos", id: :serial, force: :cascade do |t|
    t.string "bairroEndereco", limit: 255, null: false
    t.string "cep", limit: 8
    t.string "cidadeEndereco", limit: 255, null: false
    t.string "complementoEndereco", limit: 255
    t.string "endereco", limit: 255, null: false
    t.integer "endereco_uf_id", null: false
    t.string "nome", limit: 45, null: false
    t.string "numeroEndereco", limit: 45, null: false
    t.string "referenciaEndereco", limit: 255
    t.string "regiao", limit: 1, null: false, comment: "C - Capital;\nI - Interior;"
  end

  create_table "evento_doacao_lampada_reserva_lampadas", id: :serial, force: :cascade do |t|
    t.integer "evento_doacao_lampada_id", null: false
    t.integer "reserva_lampada_id", null: false
  end

  create_table "evento_doacao_lampadas", id: :serial, force: :cascade do |t|
    t.float "consumo_minimo"
    t.integer "evento_id", null: false
    t.boolean "possui_servico"
    t.boolean "possui_sucatas"
    t.integer "qtd_por_cliente", null: false
    t.boolean "saldo_livre"

    t.unique_constraint ["evento_id"], name: "unique_evento_doacao_lampadas"
  end

  create_table "evento_entrega_nota_saidas", id: :bigint, default: -> { "nextval('evento_entregas_nota_saidas_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "evento_entrega_id"
    t.integer "nota_saida_id"

    t.unique_constraint ["evento_entrega_id", "nota_saida_id"], name: "unique_entrega_nota"
  end

  create_table "evento_entregas", id: :serial, force: :cascade do |t|
    t.date "data", null: false
    t.integer "evento_id", null: false
    t.integer "instituicao_id"
    t.integer "local_entrega"
    t.integer "quantidade", null: false
    t.integer "quantidade_atual", null: false
    t.string "turno", limit: 1, comment: "M = manhã\nT = tarde"

    t.check_constraint "quantidade > 0", name: "unsigned_evento_entregas_quantidade"
    t.check_constraint "quantidade_atual >= 0", name: "unsigned_evento_entregas_quantidade_atual"
    t.unique_constraint ["data", "evento_id", "instituicao_id", "turno"], name: "unique_evento_entregas"
  end

  create_table "evento_escalacaos", force: :cascade do |t|
    t.datetime "data_criacao", precision: nil
    t.datetime "data_fim", precision: nil
    t.datetime "data_inicio", precision: nil
    t.integer "evento_id", null: false
    t.integer "usuario_id", null: false
    t.integer "usuario_operador_id", null: false
  end

  create_table "evento_historicos", id: :serial, force: :cascade do |t|
    t.timestamptz "data_alteracao", default: -> { "timezone('BRT'::text, now())" }, null: false
    t.text "descricao"
    t.integer "evento_id", null: false
    t.integer "usuario_alteracao"
  end

  create_table "evento_horario_ecopontos", force: :cascade do |t|
    t.timestamptz "data_atualizacao", default: -> { "now()" }
    t.timestamptz "data_cadastro", default: -> { "now()" }, null: false
    t.integer "dia_semana", null: false
    t.integer "evento_id", null: false
    t.string "manha_hora_final", null: false
    t.string "manha_hora_inicial", null: false
    t.boolean "status", default: true, null: false
    t.string "tarde_hora_final"
    t.string "tarde_hora_inicial"
  end

  create_table "evento_lampadas", force: :cascade do |t|
    t.integer "evento_id", null: false
    t.integer "lampada_id", null: false
    t.integer "quantidade_lampadas"

    t.unique_constraint ["evento_id", "lampada_id"], name: "unique_evento_lampada"
    t.unique_constraint ["evento_id", "quantidade_lampadas", "lampada_id"], name: "unique_evento_lampada_quantidade"
  end

  create_table "evento_parceiros", id: :integer, default: -> { "nextval('eventos_parceiros_id_seq'::regclass)" }, force: :cascade do |t|
    t.float "bonus_saldo", null: false
    t.integer "contrato_id"
    t.integer "contrato_origem_id"
    t.date "data_cadastro", null: false
    t.datetime "dt_inativacao", precision: nil
    t.integer "evento_id", null: false
    t.integer "instituicao_id"
    t.string "status", limit: 1
    t.integer "vigencia_id", null: false
    t.check_constraint "bonus_saldo > 0::double precision", name: "eventos_parceiros_check_quantidade"
  end

  create_table "evento_reciclador_vigencias", id: :serial, force: :cascade do |t|
    t.datetime "data_cadastro", precision: nil, default: -> { "now()" }
    t.datetime "data_inativacao", precision: nil
    t.integer "evento_id", null: false
    t.integer "reciclador_id", null: false
    t.string "status", limit: 1
    t.integer "vigencia_id", null: false

    t.unique_constraint ["evento_id", "reciclador_id", "vigencia_id"], name: "unique_evento_reciclador_vigencias"
  end

  create_table "evento_recursos", id: :serial, force: :cascade do |t|
    t.date "data_cadastro", null: false
    t.integer "evento_id", null: false
    t.integer "quantidade", null: false
    t.integer "recurso_id", null: false
    t.integer "valor", null: false
    t.check_constraint "quantidade > 0", name: "evento_recursos_check_quantidade"
    t.check_constraint "valor > 0", name: "evento_recursos_valor"
  end

  create_table "eventos", id: :serial, force: :cascade do |t|
    t.integer "acao_id", null: false
    t.datetime "data_cadastro", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.datetime "data_final", precision: nil, null: false
    t.datetime "data_inicial", precision: nil, null: false
    t.boolean "itinerante", default: false, null: false, comment: "True = Sim, False = Não"
    t.integer "local_acao", null: false
    t.integer "modulo_id", null: false
    t.integer "qtdPlanejadoRefrigerador"
    t.string "status", limit: 1, null: false, comment: "C = cadastro\nE = entrega\nF = finalizado"

    t.unique_constraint ["acao_id", "local_acao", "data_inicial", "data_final"], name: "unique_eventos_full"
    t.unique_constraint ["acao_id", "local_acao", "data_inicial"], name: "unique_eventos"
  end

  create_table "eventos_nota_saidas", id: :serial, force: :cascade do |t|
    t.integer "evento_id", null: false
    t.integer "nota_saida_id", null: false
  end

  create_table "eventos_reserva_lampadas", id: :serial, force: :cascade do |t|
    t.integer "evento_id", null: false
    t.integer "reserva_lampada_id", null: false
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "historicos", id: :integer, default: -> { "nextval('historico_ev_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "cliente_id", null: false
    t.integer "contrato_id", null: false
    t.string "cpf_responsavel", limit: 11
    t.datetime "data_cadastro", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.date "data_inscricao"
    t.integer "doacao_lampada_id"
    t.integer "evento_id"
    t.string "local_inscricao", limit: 100
    t.integer "modulo_id", null: false
    t.string "nota_fiscal", limit: 10
    t.integer "projeto_id"
    t.integer "quantidade_lampadas"
    t.string "refrigerador", limit: 200
    t.string "responsavel_compra", limit: 100
    t.string "status", limit: 1, default: "B", null: false, comment: "B = Bonificado - C = Cancelado"
    t.string "sucata", limit: 200
    t.integer "venda_doacao_id"
  end

  create_table "indices_ambientais", id: :serial, comment: "Índices ambientais configuráveis conforme Ticket #5198 - Valores únicos para reutilização em todo o sistema", force: :cascade do |t|
    t.boolean "ativo", default: true
    t.string "codigo", limit: 50, null: false, comment: "Código único para referência no código (ex: CO2_EVITADO)"
    t.datetime "data_atualizacao", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "data_cadastro", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.float "fator", null: false, comment: "Valor numérico usado no cálculo"
    t.string "fonte_estudo", limit: 200, null: false, comment: "Fonte científica ou técnica do índice"
    t.string "formula_display", limit: 100, null: false, comment: "Fórmula formatada para exibição ao usuário"
    t.string "nome", limit: 100, null: false
    t.text "referencia_url"
    t.string "tipo_operacao", limit: 20, null: false, comment: "Tipo de operação matemática: MULTIPLY ou DIVIDE"
    t.string "unidade_entrada", limit: 20, null: false
    t.string "unidade_saida", limit: 50, null: false
    t.index ["ativo"], name: "idx_indices_ambientais_ativo"
    t.index ["codigo"], name: "idx_indices_ambientais_codigo"
    t.unique_constraint ["codigo"], name: "indices_ambientais_codigo_key"
  end

  create_table "instituicaos", id: :serial, force: :cascade do |t|
    t.integer "bairro_id"
    t.integer "cidade_id"
    t.string "cnpj", limit: 14
    t.string "contato", limit: 100
    t.string "nome", limit: 100, null: false
    t.string "responsavel", limit: 100
    t.string "status", limit: 1
    t.string "telefone", limit: 60
    t.integer "uf_id"
  end

  create_table "instituicaos_contratos", id: :serial, force: :cascade do |t|
    t.integer "contrato_id", null: false
    t.integer "instituicao_id", null: false

    t.unique_constraint ["contrato_id"], name: "uq_instituicao_contrato_id"
  end

  create_table "item_resposta", id: false, force: :cascade do |t|
    t.string "bairro_value", limit: 255
    t.string "cidade_value", limit: 255
    t.string "comunidade_value", limit: 50
    t.string "plaintext_value"
    t.string "select_value"
    t.string "tipo"
  end

  create_table "lampadas", id: { comment: "Tabela que assume o conjunto das informações, Tipo, Modelo, potência" }, force: :cascade do |t|
    t.integer "lampada_modelo_id", comment: "FK para modelo de lâmpada"
    t.integer "lampada_tipo_id", comment: "FK para tipo de lâmpada"
    t.float "potencia", comment: "valor para potência"

    t.unique_constraint ["lampada_tipo_id", "lampada_modelo_id", "potencia"], name: "lamp_tipo_modelo_potencia_uk"
  end

  create_table "lampadas_modelo", id: :serial, comment: "Tabela que guarda as infomações dos modelos de lâmpadas possíveis: Tubular, Espiral, Bulbo", force: :cascade do |t|
    t.string "descricao", limit: 45, null: false, comment: "Nome do modelo"
  end

  create_table "lampadas_tipo", id: :integer, default: -> { "nextval('lampadas_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "descricao", limit: 45, null: false
    t.string "potencia", limit: 10
    t.string "troca", limit: 1, default: "N", comment: "Campo para informar se a lâmpada é aceita para troca, devolução...utilizado inicialmente pleo Vale Luz"
    t.check_constraint "troca::text = 'S'::text OR troca::text = 'N'::text", name: "troca_ck"
  end

  create_table "localidades", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: 0
    t.datetime "updated_at", precision: 0
  end

  create_table "locals", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: 0
    t.datetime "updated_at", precision: 0
  end

  create_table "log_chatbot", force: :cascade do |t|
    t.datetime "data_req", precision: nil, null: false
    t.datetime "data_res", precision: nil, null: false
    t.string "intencao", limit: 255, null: false
    t.string "req_palavra", limit: 255, null: false
    t.text "resposta", null: false
    t.integer "usuario_id"
    t.index ["id"], name: "log_chatbot_pk", unique: true
  end

  create_table "logs", id: :integer, default: -> { "nextval('log_id_seq'::regclass)" }, force: :cascade do |t|
    t.timestamptz "data_alteracao", default: -> { "timezone('BRT'::text, now())" }, null: false
    t.text "descricao"
    t.string "nome_model", null: false
    t.integer "registro_id"
    t.integer "usuario_alteracao"
  end

  create_table "marca_refrigeradors", id: :serial, force: :cascade do |t|
    t.string "nome", limit: 50, null: false
  end

  create_table "menus", id: :serial, force: :cascade do |t|
    t.string "action", limit: 50
    t.boolean "ativo", default: true, null: false
    t.boolean "can_mobile", default: false, null: false
    t.string "controller", limit: 50
    t.oid "imagem"
    t.integer "menu_pai_id"
    t.string "mobile_icon", limit: 100
    t.string "nome", limit: 50, null: false
    t.string "nome_imagem", limit: 100
    t.integer "ordem"
    t.string "parametros", limit: 100
  end

  create_table "menus_backup_5954", id: false, force: :cascade do |t|
    t.string "action", limit: 50
    t.boolean "ativo"
    t.boolean "can_mobile"
    t.string "controller", limit: 50
    t.integer "id"
    t.oid "imagem"
    t.integer "menu_pai_id"
    t.string "mobile_icon", limit: 100
    t.string "nome", limit: 50
    t.string "nome_imagem", limit: 100
    t.integer "ordem"
    t.string "parametros", limit: 100
  end

  create_table "menus_modulos", id: :integer, default: -> { "nextval('menus_projetos_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "menu_id", null: false
    t.integer "modulo_id", null: false

    t.unique_constraint ["modulo_id", "menu_id"], name: "unique_menus_modulos"
  end

  create_table "menus_modulos_backup_5954", id: false, force: :cascade do |t|
    t.integer "id"
    t.integer "menu_id"
    t.integer "modulo_id"
  end

  create_table "menus_perfils", id: :integer, default: -> { "nextval('\"MenuPerfils_id_seq\"'::regclass)" }, force: :cascade do |t|
    t.integer "menu_id", null: false
    t.integer "perfil_id", null: false

    t.unique_constraint ["menu_id", "perfil_id"], name: "unique_menus_perfils"
  end

  create_table "menus_perfils_backup_5954", id: false, force: :cascade do |t|
    t.integer "id"
    t.integer "menu_id"
    t.integer "perfil_id"
  end

  create_table "message_deliveries", force: :cascade do |t|
    t.integer "attempts", default: 0
    t.text "body"
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.bigint "deliverable_id"
    t.string "deliverable_type"
    t.datetime "delivered_at"
    t.text "error_message"
    t.string "external_id"
    t.datetime "failed_at"
    t.jsonb "metadata", default: {}
    t.string "provider", null: false
    t.string "recipient", null: false
    t.string "status", default: "pending", null: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["channel"], name: "index_message_deliveries_on_channel"
    t.index ["created_at"], name: "index_message_deliveries_on_created_at"
    t.index ["deliverable_type", "deliverable_id"], name: "index_message_deliveries_on_deliverable"
    t.index ["status", "channel"], name: "index_message_deliveries_on_status_and_channel"
    t.index ["status"], name: "index_message_deliveries_on_status"
  end

  create_table "meta_lampadas", id: :serial, force: :cascade do |t|
    t.integer "acao_id", null: false
    t.integer "ano", null: false
    t.integer "lampada_id", null: false
    t.integer "quantidade", null: false
    t.integer "quantidade_atual", null: false
    t.string "tipo_cliente", limit: 1, null: false, comment: "R = Residencial\nB = Baixa renda"

    t.check_constraint "quantidade > 0", name: "unsigned_meta_lampadas_quantidade"
    t.check_constraint "quantidade_atual >= 0", name: "unsigned_meta_lampadas_quantidade_atual"
    t.unique_constraint ["ano", "lampada_id", "tipo_cliente", "acao_id"], name: "unique_meta_lampadas"
  end

  create_table "meta_refrigeradors", id: :serial, force: :cascade do |t|
    t.integer "acao_id", null: false
    t.integer "ano", null: false
    t.integer "equipamento_id"
    t.integer "quantidade", null: false
    t.integer "quantidade_atual", null: false
    t.integer "refrigerador_id"
    t.string "tipo_cliente", limit: 1, null: false, comment: "R = Residencial\nB = Baixa renda"

    t.check_constraint "quantidade > 0", name: "unsigned_meta_refrigeradors_quantidade"
    t.check_constraint "quantidade_atual >= 0", name: "unsigned_meta_refrigeradors_quantidade_atual"
    t.unique_constraint ["ano", "refrigerador_id", "tipo_cliente", "acao_id"], name: "unique_meta_refrigeradors"
  end

  create_table "metas", id: :serial, force: :cascade do |t|
    t.integer "acao_id", null: false
    t.integer "ano", null: false
    t.string "cliente_tipo", limit: 1, comment: "R = Residencial\n\tB = Baixa renda"
    t.datetime "data_cadastro", precision: nil, default: -> { "now()" }, null: false
    t.string "model"
    t.integer "modulo_id", null: false
    t.datetime "periodo_final", precision: nil, null: false
    t.datetime "periodo_inicial", precision: nil, null: false
    t.float "previsto", null: false
    t.float "realizado", null: false
    t.integer "registro_id"

    t.check_constraint "previsto > 0::double precision", name: "unsigned_metas_previsto"
    t.check_constraint "realizado >= 0::double precision", name: "unsigned_metas_realizado"
    t.unique_constraint ["ano", "periodo_inicial", "periodo_final", "cliente_tipo", "modulo_id", "acao_id", "model", "registro_id"], name: "unique_metas"
  end

  create_table "migrations", id: :serial, force: :cascade do |t|
    t.integer "batch", null: false
    t.string "migration", limit: 255, null: false
  end

  create_table "models", id: false, force: :cascade do |t|
    t.serial "id", null: false
    t.string "nome", limit: 255, null: false

    t.unique_constraint ["nome"], name: "unique_model"
  end

  create_table "modulo_projetos", id: :integer, default: -> { "nextval('modulos_projetos_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "modulo_id", null: false
    t.integer "projeto_id", null: false

    t.unique_constraint ["modulo_id", "projeto_id"], name: "uq_modulo_projeto_id"
  end

  create_table "modulos", id: :serial, force: :cascade do |t|
    t.string "nome", limit: 50, null: false
    t.string "nome_imagem", limit: 255, null: false
    t.string "nome_imagem_svg", limit: 50
    t.string "sigla", limit: 10
  end

  create_table "n_log", id: :serial, force: :cascade do |t|
    t.timestamptz "data_cadastro", default: -> { "timezone('BRT'::text, now())" }, null: false
    t.text "descricao"
    t.string "ip", limit: 16
    t.string "model", null: false
    t.string "nome_log", limit: 50
    t.integer "registro_id"
    t.string "tipo", limit: 1, comment: "I = INSERT, U = UPDATE, D = DELETE"
    t.integer "usuario_id"
  end

  create_table "nota_fabricantes", id: :integer, default: -> { "nextval('nota_fabricante_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "arquivo", limit: 255, null: false
    t.datetime "data_cadastro", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.date "data_emissao", null: false
    t.string "numero", limit: 20, null: false
    t.integer "quantidade", null: false
    t.integer "quantidade_atual", null: false
    t.integer "refrigerador_id", null: false

    t.check_constraint "quantidade > 0", name: "unsigned_nota_fabricante_quantidade"
    t.unique_constraint ["numero"], name: "unique_nota_fabricantes_numero"
  end

  create_table "nota_fabricantes_nota_saidas", id: :serial, force: :cascade do |t|
    t.datetime "data_cadastro", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.integer "nota_fabricante_id", null: false
    t.integer "nota_saida_id", null: false
    t.integer "quantidade", null: false
    t.integer "quantidade_atual", default: 0, null: false

    t.check_constraint "quantidade > 0", name: "unsigned_nota_fabricantes_nota_saidas_quantidade"
    t.check_constraint "quantidade_atual >= 0", name: "unsigned_nota_fabricantes_nota_saidas_quantidade_atual"
    t.unique_constraint ["nota_saida_id", "nota_fabricante_id"], name: "unique_nota_fabricantes_nota_saidas"
  end

  create_table "nota_saidas", id: :serial, force: :cascade do |t|
    t.string "arquivo", limit: 255, null: false
    t.datetime "data_cadastro", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.date "data_emissao", null: false
    t.string "numero", limit: 20, null: false
    t.string "projeto", limit: 1, comment: "N = PNG\nD = PDR"
    t.integer "qtd_nota_saida"
    t.string "status", limit: 1, default: "A", null: false

    t.check_constraint "qtd_nota_saida > 0", name: "unsigned_qtd_nota_saida"
    t.unique_constraint ["numero"], name: "unique_nota_saidas_numero"
  end

  create_table "oauth_access_tokens", id: { type: :string, limit: 100 }, force: :cascade do |t|
    t.integer "client_id", null: false
    t.datetime "created_at", precision: 0
    t.datetime "expires_at", precision: 0
    t.string "name", limit: 255
    t.boolean "revoked", null: false
    t.text "scopes"
    t.datetime "updated_at", precision: 0
    t.integer "user_id"
    t.index ["client_id"], name: "oauth_access_tokens_client_id_index"
    t.index ["user_id"], name: "oauth_access_tokens_user_id_index"
  end

  create_table "oauth_auth_codes", id: { type: :string, limit: 100 }, force: :cascade do |t|
    t.integer "client_id", null: false
    t.datetime "expires_at", precision: 0
    t.boolean "revoked", null: false
    t.text "scopes"
    t.integer "user_id", null: false
  end

  create_table "oauth_clients", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: 0
    t.string "name", limit: 255, null: false
    t.boolean "password_client", null: false
    t.boolean "personal_access_client", null: false
    t.text "redirect", null: false
    t.boolean "revoked", null: false
    t.string "secret", limit: 100, null: false
    t.datetime "updated_at", precision: 0
    t.integer "user_id"
    t.index ["user_id"], name: "oauth_clients_user_id_index"
  end

  create_table "oauth_personal_access_clients", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.datetime "created_at", precision: 0
    t.datetime "updated_at", precision: 0
    t.index ["client_id"], name: "oauth_personal_access_clients_client_id_index"
  end

  create_table "oauth_refresh_tokens", id: { type: :string, limit: 100 }, force: :cascade do |t|
    t.string "access_token_id", limit: 100, null: false
    t.datetime "expires_at", precision: 0
    t.boolean "revoked", null: false
    t.index ["access_token_id"], name: "oauth_refresh_tokens_access_token_id_index"
  end

  create_table "parceiros", id: :serial, force: :cascade do |t|
    t.integer "bairro_id"
    t.integer "cidade_id"
    t.string "cnpj", limit: 14
    t.string "contato", limit: 100
    t.string "nome", limit: 100, null: false
    t.integer "parceiro_tipo_id"
    t.string "responsavel", limit: 100
    t.string "status", limit: 1
    t.integer "uf_id"

    t.unique_constraint ["nome"], name: "unique_parceiros_nome"
  end

  create_table "parceiros_contratos", id: :serial, force: :cascade do |t|
    t.integer "contrato_id", null: false
    t.integer "parceiro_id", null: false

    t.unique_constraint ["contrato_id"], name: "uq_parceiro_contrato_id"
  end

  create_table "parceiros_tipos", id: :serial, force: :cascade do |t|
    t.string "nome", limit: 255, null: false
    t.string "status", limit: 1, null: false
  end

  create_table "perfil_permissao", id: :serial, force: :cascade do |t|
    t.integer "perfil_id"
    t.integer "permissao_id"
  end

  create_table "perfils", id: :serial, force: :cascade do |t|
    t.string "nome", limit: 100, null: false
    t.string "status", limit: 1, default: "A"

    t.unique_constraint ["nome"], name: "unique_perfils_nome"
  end

  create_table "perfils_backup_5954", id: false, force: :cascade do |t|
    t.integer "id"
    t.string "nome", limit: 100
    t.string "status", limit: 1
  end

  create_table "perfils_modulos", id: :integer, default: -> { "nextval('\"PerfilProjetos_id_seq\"'::regclass)" }, force: :cascade do |t|
    t.integer "modulo_id", null: false
    t.integer "perfil_id", null: false

    t.unique_constraint ["perfil_id", "modulo_id"], name: "unique_perfils_modulos"
  end

  create_table "permissoes", id: :serial, force: :cascade do |t|
    t.string "codigo", limit: 50, null: false
    t.string "nome", limit: 255, null: false
  end

  create_table "potencias", force: :cascade do |t|
    t.string "nome", limit: 5, comment: "Descrição da potência da lâmpada"
  end

  create_table "programacao_estabelecimentos", id: :serial, force: :cascade do |t|
    t.date "data_final", null: false
    t.date "data_inicial", null: false
    t.integer "estabelecimento_id", null: false
  end

  create_table "projetos", id: :integer, default: -> { "nextval('\"Projetos_id_seq\"'::regclass)" }, force: :cascade do |t|
    t.integer "ativo", default: 1, null: false
    t.string "nome", limit: 45, null: false
    t.string "sigla", limit: 10
  end

  create_table "promotors", id: :serial, force: :cascade do |t|
    t.string "nome", limit: 45, null: false
  end

  create_table "recicladors", id: :serial, force: :cascade do |t|
    t.integer "bairro_id"
    t.integer "cidade_id"
    t.string "cnpj", limit: 14
    t.string "contato", limit: 100
    t.boolean "legado", default: false, null: false
    t.string "nome", limit: 100, null: false
    t.string "responsavel", limit: 100
    t.string "status", limit: 1, default: "A"
    t.string "telefone", limit: 60
    t.integer "uf_id"

    t.unique_constraint ["cnpj"], name: "unique_recicladors_cnpj"
    t.unique_constraint ["nome"], name: "unique_recicladors_nome"
  end

  create_table "recicladors_contratos", id: :serial, force: :cascade do |t|
    t.integer "contrato_id", null: false
    t.integer "reciclador_id", null: false

    t.unique_constraint ["contrato_id"], name: "uq_reciclador_contrato_id"
  end

  create_table "reciclagem_integracao", id: :serial, force: :cascade do |t|
    t.string "arquivo", limit: 50, null: false
    t.float "bonus_total", null: false
    t.datetime "data_geracao", precision: nil
    t.integer "qt_registros", null: false
    t.integer "sequencial", null: false
    t.string "status", limit: 1, null: false
    t.string "tipo", limit: 1, null: false
  end

  create_table "reciclagem_recursos", id: :serial, force: :cascade do |t|
    t.float "bonus_valor", null: false
    t.float "co2", default: 0.0, null: false
    t.float "kwheco", default: 0.0, null: false
    t.boolean "legado", default: false, null: false
    t.decimal "quantidade", null: false
    t.integer "reciclador_id"
    t.integer "reciclagem_id", null: false
    t.integer "recurso_id", null: false
    t.integer "vigencia_id"
    t.index ["reciclador_id"], name: "reciclagem_recursos_reciclador_id_index"
    t.index ["reciclagem_id"], name: "reciclagem_recursos_reciclagem_id_index"
    t.index ["recurso_id"], name: "reciclagem_recursos_recurso_id_index"
  end

  create_table "reciclagems", id: :serial, force: :cascade do |t|
    t.string "bonus_percentual", limit: 5, default: "100", null: false
    t.float "bonus_total", null: false
    t.integer "cliente_evento_contrato_id", null: false
    t.string "codigo", limit: 255, null: false
    t.integer "contrato_origem_id"
    t.datetime "data_cadastro", precision: nil
    t.integer "integracao_debito_id"
    t.integer "integracao_id"
    t.boolean "legado", default: false, null: false
    t.string "recibo_status", limit: 20
    t.string "status", limit: 1, null: false, comment: "R = Recebido; T = Trasmitido; N = Não Trasmitido; X = Cancelado"
    t.string "status_debito", limit: 1, default: "R", null: false
    t.integer "veiculo_id"
    t.index ["cliente_evento_contrato_id"], name: "reciclagems_cliente_evento_contrato_id_index"
    t.index ["contrato_origem_id"], name: "reciclagems_contrato_origem_id_index"
    t.index ["veiculo_id"], name: "reciclagems_veiculo_id_index"
  end

  create_table "recovery", id: :serial, force: :cascade do |t|
    t.string "code", limit: 255, null: false
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "entity", null: false
    t.integer "entity_id", null: false
    t.string "type", limit: 255, default: "sms", null: false
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "used", default: false, null: false
  end

  create_table "recursos", id: :serial, force: :cascade do |t|
    t.float "co2", default: 0.0, null: false
    t.date "data_cadastro", null: false
    t.float "kwheco", default: 0.0, null: false
    t.boolean "legado", default: false, null: false
    t.string "nome", limit: 100, null: false
    t.string "status", limit: 1, null: false
    t.integer "tipo_recurso_id", null: false
    t.integer "unidade_medida_id", null: false
    t.index ["tipo_recurso_id"], name: "recursos_tipo_recurso_id_index"
    t.unique_constraint ["nome", "unidade_medida_id", "tipo_recurso_id"], name: "unique_nome_tipo_unidade_medida"
  end

  create_table "refrigeradors", id: :serial, force: :cascade do |t|
    t.integer "ativo", default: 1, null: false
    t.string "cor", limit: 20
    t.datetime "data_cadastro", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.integer "equipamento_id", default: 1, null: false
    t.integer "marca_refrigerador_id", null: false
    t.string "modelo", limit: 30, null: false, comment: "Nome do modelo da Geladeira. Ex: CRA30F, RCD37 "
    t.string "tensao", limit: 1, comment: "1 = 110v\n2 = 220v"
    t.string "tipo", limit: 20, comment: "Simples,Duplex através de uma combo"
    t.integer "valor_bonus"
    t.float "volume"
    t.check_constraint "volume > 0::double precision", name: "unsigned_refrigeradors_volume"
  end

  create_table "regionals", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: 0
    t.datetime "updated_at", precision: 0
  end

  create_table "reserva_lampada_vendas", id: :serial, force: :cascade do |t|
    t.integer "quantidade", null: false
    t.integer "reserva_lampada_id", null: false
    t.integer "venda_id", null: false
  end

  create_table "reserva_lampadas", id: :serial, force: :cascade do |t|
    t.datetime "data_cadastro", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.integer "doados", default: 0, null: false
    t.integer "lampada_id", null: false
    t.string "numero", limit: 10, null: false
    t.integer "projeto_id", null: false
    t.integer "quantidade", null: false
    t.integer "quantidade_atual", null: false
    t.integer "quantidade_avaria", default: 0, null: false
    t.string "status", limit: 1, default: "A", null: false
    t.check_constraint "quantidade > 0", name: "unsigned_reserva_lampadas_quantidade"
    t.check_constraint "quantidade_atual >= 0", name: "unsigned_reserva_lampadas_quantidadeAtual"
  end

  create_table "reserva_lampadas_doacao_lampadas", id: :serial, force: :cascade do |t|
    t.integer "doacao_lampada_id", null: false
    t.integer "quantidade", null: false
    t.integer "reserva_lampada_id", null: false
  end

  create_table "reserva_lampadas_vistoria_pngd", id: :serial, force: :cascade do |t|
    t.integer "quantidade", null: false
    t.integer "reserva_lampada_id", null: false
    t.integer "vistoria_d_id", null: false
  end

  create_table "ruas", id: :integer, default: nil, force: :cascade do |t|
    t.integer "bairro_id", null: false
    t.string "cep", limit: 8, null: false
    t.string "nome", limit: 255, null: false
  end

  create_table "servicos", id: :serial, force: :cascade do |t|
    t.string "nome", limit: 100, null: false
    t.integer "parceiro_id", null: false
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "sucata_entradas_itens", id: :serial, force: :cascade do |t|
    t.integer "cliente_id"
    t.integer "contrato_id"
    t.integer "lote_id"
    t.integer "sucata_pngd_id"
    t.integer "sucata_pngv_id"

    t.unique_constraint ["sucata_pngd_id", "contrato_id", "cliente_id"], name: "uk_sucata_pngd_id"
    t.unique_constraint ["sucata_pngv_id", "contrato_id", "cliente_id"], name: "uk_sucata_pngv_id"
  end

  create_table "sucata_entradas_lote", id: :serial, force: :cascade do |t|
    t.datetime "data_recebimento", precision: nil
    t.integer "modulo_id"
    t.string "numero_lote", limit: 50
    t.integer "parceiro_id"
    t.string "situacao", limit: 1, default: "A"
    t.integer "usuario_recebimento"

    t.unique_constraint ["numero_lote", "modulo_id"], name: "uk_numero_lote"
  end

  create_table "sucata_saidas_itens", id: :serial, force: :cascade do |t|
    t.integer "item_entrada_id"
    t.integer "lote_id"
  end

  create_table "sucata_saidas_lote", id: :serial, force: :cascade do |t|
    t.datetime "data_saida", precision: nil
    t.integer "modulo_id"
    t.string "numero_lote", limit: 50
    t.integer "parceiro_id"
    t.string "situacao", limit: 1
    t.integer "usuario_saida"

    t.unique_constraint ["numero_lote", "modulo_id"], name: "uk_saida_numero_lote"
  end

  create_table "sucatas_lampada", id: { comment: "PK" }, force: :cascade do |t|
    t.bigint "doacao_lampada_id", null: false
    t.integer "lampada_id", null: false, comment: "Lâmpada sucata usada na troca por novas no projeto Vale Luz"
    t.integer "potencia", comment: "descrição da potência, aceita apenas números"
    t.integer "quantidade", null: false, comment: "Quantidade de lampadas trocadas"
  end

  create_table "sucatas_pngd", id: :serial, force: :cascade do |t|
    t.string "cor", limit: 45, null: false
    t.integer "equipamento_id", default: 1, null: false
    t.string "estado_conservacao", limit: 10, null: false, comment: "Bom, Regular, Ruim"
    t.integer "marca_refrigerador_id", null: false
    t.string "tipo", limit: 15, comment: "Simples, Duplex através de combos"
    t.integer "triagem_d_id", null: false

    t.unique_constraint ["triagem_d_id"], name: "unique_sucatas_pngd_triagem_pngd"
  end

  create_table "sucatas_pngv", id: :serial, force: :cascade do |t|
    t.string "cor", limit: 45, null: false
    t.date "data_recebimento"
    t.string "equip_entregue", limit: 1, default: "N", null: false, comment: "S = Sim\nN = Não"
    t.integer "equipamento_id", default: 1, null: false
    t.string "estado_conservacao", limit: 10, null: false, comment: "B = Bom\nR = Regular\nU = Ruim"
    t.integer "marca_refrigerador_id", null: false
    t.string "tipo", limit: 20, comment: "Simples, Duplex através de combos"
    t.integer "triagem_pngv_id", null: false

    t.unique_constraint ["triagem_pngv_id"], name: "unique_sucatas_triagems"
  end

  create_table "tipo_acaos", id: :serial, force: :cascade do |t|
    t.string "nome", limit: 50, null: false

    t.unique_constraint ["nome"], name: "unique_nome"
  end

  create_table "tipo_recursos", id: :serial, force: :cascade do |t|
    t.float "indice"
    t.string "nome", limit: 100, null: false

    t.unique_constraint ["nome"], name: "unique_nome_tipo_recursos"
  end

  create_table "tipo_veiculo", force: :cascade do |t|
    t.datetime "data_cadastro", precision: nil, default: -> { "now()" }, null: false
    t.string "descricao", limit: 200, null: false
    t.boolean "is_editable", default: true, null: false
    t.boolean "status", default: true, null: false
  end

  create_table "tipos_acaos", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: 0
    t.datetime "updated_at", precision: 0
  end

  create_table "triagem_pngd", id: :serial, force: :cascade do |t|
    t.integer "cliente_evento_contrato_id", null: false
    t.float "consumo1", null: false
    t.float "consumo2", null: false
    t.float "consumo3", null: false
    t.date "data_cadastro", default: -> { "('now'::text)::date" }, null: false
    t.date "data_ultima_fatura", null: false
    t.string "negociado", limit: 1, comment: "S - Participante que está em negociação. É apenas demonstrativo\nN - Indica Participante não está em negociação"
    t.string "nis", limit: 11
    t.text "observacoes"
    t.string "pendencia", limit: 1, comment: "S = Sim\nN = Não"
    t.string "possui_nis", limit: 1, null: false, comment: "S = Sim\nN = Não"
    t.string "validado", limit: 1, default: "N", null: false, comment: "S = Sim\nN = Não"

    t.check_constraint "consumo1 >= 0::double precision AND consumo2 >= 0::double precision AND consumo3 >= 0::double precision", name: "triagem_pngd_consumos_check"
    t.check_constraint "negociado = ANY (ARRAY['S'::bpchar, 'N'::bpchar])", name: "triagem_pngd_negociado_check"
    t.unique_constraint ["cliente_evento_contrato_id"], name: "unique_triagem_pngd_cliente_evento_contrato_id"
    t.unique_constraint ["nis"], name: "unique_triagem_pngd_nis"
  end

  create_table "triagem_pngv", id: :serial, force: :cascade do |t|
    t.integer "cliente_contrato_projeto_id", null: false
    t.string "compra_direta", limit: 1, comment: "S = sim\nN = não"
    t.float "consumo1", null: false
    t.float "consumo2", null: false
    t.float "consumo3", null: false
    t.date "dataUltimoConsumo", null: false
    t.date "data_emissao"
    t.integer "estabelecimento_id"
    t.string "negociado", limit: 1, comment: "S - É um participante que foi negociado;\nN - Paciente não Negociado."
    t.string "nis", limit: 11
    t.string "nota_fiscal", limit: 20
    t.string "possui_nis", limit: 1, null: false, comment: "S = sim\nN = não"
    t.string "situacao_cliente", limit: 1, null: false, comment: "A = apto\nI = inapto"
    t.string "situacao_nis", limit: 1, comment: "V = válido\nI = Inválido"

    t.check_constraint "consumo1 >= 0::double precision AND consumo2 >= 0::double precision AND consumo3 >= 0::double precision", name: "triagem_pngv_consumos_check"
    t.check_constraint "negociado = ANY (ARRAY['S'::bpchar, 'N'::bpchar])", name: "triagem_pngv_negociado_check"
    t.unique_constraint ["cliente_contrato_projeto_id"], name: "triagem_pngv_cliente_contrato_projeto_id_key"
  end

  create_table "ufs", id: :integer, default: nil, force: :cascade do |t|
    t.string "nome", limit: 255, null: false
    t.string "sigla", limit: 2, null: false
  end

  create_table "unidade_medidas", id: :serial, force: :cascade do |t|
    t.string "nome", limit: 100, null: false
    t.string "sigla", limit: 4

    t.unique_constraint ["nome"], name: "unique_unidade_medidas_nome"
  end

  create_table "usuarios", id: :serial, force: :cascade do |t|
    t.string "contexto"
    t.string "email", limit: 255
    t.integer "evento_id"
    t.string "login", limit: 20, null: false
    t.string "nome", limit: 45, null: false
    t.integer "perfil_id"
    t.string "push_token", limit: 255, comment: "Código para mensagens push do app"
    t.integer "reciclador_id"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "senha", limit: 64, null: false
    t.string "status", limit: 1, default: "A", null: false
    t.index ["reset_password_token"], name: "index_usuarios_on_reset_password_token", unique: true
    t.unique_constraint ["login"], name: "unique_usuarios_login"
  end

  create_table "veiculo", force: :cascade do |t|
    t.decimal "ano", precision: 4
    t.datetime "data_cadastro", precision: nil, default: -> { "now()" }, null: false
    t.boolean "is_editable", default: true, null: false
    t.string "marca", limit: 20, null: false
    t.string "modelo", limit: 100, null: false
    t.string "placa", limit: 7, null: false
    t.boolean "status", default: true, null: false
    t.integer "tipo_veiculo_id", null: false
  end

  create_table "venda_historicos", id: :bigint, default: -> { "nextval('vendas_historico_id_seq'::regclass)" }, force: :cascade do |t|
    t.timestamptz "data_alteracao", default: -> { "timezone('BRT'::text, now())" }, null: false
    t.text "descricao"
    t.integer "usuario_alteracao"
    t.integer "vendas_id", null: false
  end

  create_table "vendas", id: :serial, force: :cascade do |t|
    t.string "cpfResponsavel", limit: 11, null: false
    t.datetime "data", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.timestamptz "data_cancelamento"
    t.integer "estabelecimento_id", null: false
    t.integer "lampada_id", null: false
    t.text "motivo_cancelamento"
    t.string "nomeResponsavel", limit: 45, null: false
    t.string "nota_fiscal", limit: 20
    t.string "numeroPedidoCompra", limit: 45
    t.string "numero_cartao", limit: 20
    t.text "observacao"
    t.integer "quantidade_lampadas"
    t.integer "refrigerador_id", null: false
    t.string "status", limit: 1, default: "P", null: false, comment: "P = Pendente\nB = Bonificado\nR = Resolvido"
    t.integer "sucata_pngv_id", null: false
    t.integer "usuario_id", null: false
    t.integer "valor_bonus"

    t.unique_constraint ["sucata_pngv_id"], name: "unique_vendas_sucatas"
  end

  create_table "vigencias", id: :serial, force: :cascade do |t|
    t.date "data_final"
    t.date "data_inicial", null: false
    t.string "model", limit: 90
    t.integer "registro_id", null: false
    t.string "status", limit: 1, null: false
    t.float "valor", null: false
    t.check_constraint "\nCASE model\n    WHEN 'Recurso'::bpchar THEN valor > 0::double precision\n    ELSE NULL::boolean\nEND", name: "check_vigencia_valor"
  end

  create_table "vistoria_pngd", id: :serial, force: :cascade do |t|
    t.datetime "data_cadastro", precision: nil, default: -> { "timezone('BRT'::text, now())" }, null: false
    t.integer "nota_fabricante_nota_saida_id", null: false
    t.string "numero_sequencial", limit: 20, null: false
    t.string "numero_serie", limit: 20, null: false
    t.integer "quantidade_lampadas", null: false
    t.string "remover_kit", limit: 1, default: "S", null: false
    t.integer "triagem_d_id", null: false
    t.integer "usuario_id", null: false

    t.unique_constraint ["triagem_d_id"], name: "unique_vistoria_pngd_triagem_pngd"
  end

  add_foreign_key "acaos", "projetos", name: "fk_acaos_projetos"
  add_foreign_key "agendamentos", "refrigeradors", name: "fk_agendamentos_refrigeradors"
  add_foreign_key "agendamentos", "triagem_pngv", name: "fk_agendamentos_triagems", on_delete: :cascade
  add_foreign_key "arquivos_eventos", "eventos", name: "arquivos_eventos_evento_id_fkey"
  add_foreign_key "arquivos_triagem_pngd", "triagem_pngd", name: "fk_arquivos_triagem_pngd_triagems", on_delete: :cascade
  add_foreign_key "arquivos_triagems", "triagem_pngv", name: "fk_arquivos_triagems_triagems", on_delete: :cascade
  add_foreign_key "arquivos_vendas", "vendas", name: "arquivos_venda_venda_id_fkey"
  add_foreign_key "arquivos_vistoria_pngd", "vistoria_pngd", name: "fk_arquivos_vistoria_pngd_vistoria_pngd", on_delete: :cascade
  add_foreign_key "bairros", "cidades", name: "fk_bairros_cidades"
  add_foreign_key "bi_form_item_bairros", "bairros", name: "bi_form_item_bairros_bairros_id_fk"
  add_foreign_key "bi_form_item_bairros", "bi_form_items", name: "bi_form_item_bairros_bi_form_items_id_fk"
  add_foreign_key "bi_form_item_cidades", "bi_form_items", name: "bi_form_item_cidades_bi_form_items_id_fk"
  add_foreign_key "bi_form_item_cidades", "cidades", name: "bi_form_item_cidades_cidades_id_fk"
  add_foreign_key "bi_form_item_comunidades", "bi_form_items", name: "bi_form_item_comunidades_bi_form_items_id_fk"
  add_foreign_key "bi_form_item_comunidades", "comunidades", name: "bi_form_item_comunidades_comunidades_id_fk"
  add_foreign_key "bi_form_item_respostas", "bairros", name: "bi_form_item_respostas_bairros_id_fk"
  add_foreign_key "bi_form_item_respostas", "bi_form_item_selects", column: "bi_select_id", name: "bi_form_item_respostas_bi_form_item_selects_id_fk"
  add_foreign_key "bi_form_item_respostas", "bi_form_respostas", name: "bi_form_item_resposta_bi_form_resposta_id_fk"
  add_foreign_key "bi_form_item_respostas", "cidades", name: "bi_form_item_respostas_cidades_id_fk"
  add_foreign_key "bi_form_item_respostas", "comunidades", name: "bi_form_item_respostas_comunidades_id_fk"
  add_foreign_key "bi_form_item_selects", "bi_form_items", column: "form_item_id", name: "bi_form_item_selects_bi_form_items_id_fk"
  add_foreign_key "bi_form_items", "bi_form_steppers", column: "stepper_id", name: "bi_form_items_bi_form_steppers_id_fk"
  add_foreign_key "bi_form_items", "bi_forms", name: "bi_form_items_bi_forms_id_fk"
  add_foreign_key "bi_form_respostas", "bi_forms", name: "bi_form_resposta_bi_forms_id_fk"
  add_foreign_key "bi_form_respostas", "usuarios", name: "bi_form_resposta_usuarios_id_fk"
  add_foreign_key "bi_form_steppers", "bi_forms", name: "bi_form_steppers_bi_forms_id_fk"
  add_foreign_key "bi_metas", "bi_contratos", name: "bi_metas_bi_contratos_id_fk"
  add_foreign_key "campanhas", "modulos", name: "fk_campanha_modulo_id"
  add_foreign_key "cidades", "ufs", name: "fk_cidades_ufs"
  add_foreign_key "cliente_estabelecimento_entregas", "clientes", name: "fk_clientes_estabelecimento_entregas_clientes"
  add_foreign_key "cliente_estabelecimento_entregas", "estabelecimento_entregas", name: "fk_clientes_estabelecimento_entregas_estabelecimento_entregas"
  add_foreign_key "clientes", "eventos", name: "cliente_evento_id_fkey"
  add_foreign_key "clientes", "ufs", column: "rg_uf_id", name: "fk_clientes_ufs"
  add_foreign_key "clientes", "usuarios", name: "clientes_usuarios_id_fk"
  add_foreign_key "clientes_contratos_projetos", "clientes", name: "fk_clientes_projetos_clientes"
  add_foreign_key "clientes_contratos_projetos", "contratos", name: "fk_clientes_contratos_projetos_contratos"
  add_foreign_key "clientes_contratos_projetos", "projetos", name: "fk_clientes_projetos_projetos"
  add_foreign_key "clientes_evento_entregas", "clientes", name: "fk_clientes_evento_entregas_clientes"
  add_foreign_key "clientes_evento_entregas", "contratos", name: "fk_clientes_evento_entregas_contrato"
  add_foreign_key "clientes_evento_entregas", "evento_entregas", name: "fk_clientes_evento_entregas_evento_entregas"
  add_foreign_key "clientes_eventos_contratos", "clientes", name: "fk_clientes_eventos_clientes"
  add_foreign_key "clientes_eventos_contratos", "contratos", name: "fk_clientes_eventos_contratos_contratos"
  add_foreign_key "clientes_eventos_contratos", "eventos", name: "fk_clientes_eventos_eventos"
  add_foreign_key "clientes_eventos_contratos", "modulos", name: "clientes_eventos_contratos_modulo_id_fkey"
  add_foreign_key "comunidades", "acaos", name: "comunidades_acao_id_fkey"
  add_foreign_key "comunidades", "comunidades_tipos", column: "tipo_id", name: "comunidades_comunidades_tipos_id_fk"
  add_foreign_key "comunidades", "parceiros", name: "comunidades_parceiros_id_fk"
  add_foreign_key "contrato_campanhas", "campanhas", name: "fk_contrato_campanhas_campanha_id"
  add_foreign_key "contrato_campanhas", "contratos", name: "fk_contrato_campanhas_contrato_id"
  add_foreign_key "contratos", "bairros", name: "fk_contratos_bairros"
  add_foreign_key "contratos", "comunidades", column: "local_cadastro_id", name: "contrato_local_fkey"
  add_foreign_key "contratos", "contratos_tipos", column: "contrato_tipo_id", name: "fk_contrato_contrato_tipo"
  add_foreign_key "contratos", "ufs", name: "fk_contratos_ufs"
  add_foreign_key "doacao_historicos", "usuarios", column: "usuario_alteracao", name: "doacao_historico_usuario_alteracao_fkey"
  add_foreign_key "doacao_historicos", "vistoria_pngd", name: "doacao_historico_vistoria_pngd_id_fkey"
  add_foreign_key "doacao_lampada_historicos", "usuarios", column: "usuario_alteracao", name: "fk_doacao_lampada_historicos_usuarios"
  add_foreign_key "doacao_lampadas", "clientes", name: "fk_doacao_lampadas_clientes"
  add_foreign_key "doacao_lampadas", "contratos", name: "fk_doacao_lampadas_contratos"
  add_foreign_key "doacao_lampadas", "evento_entregas", name: "fk_doacao_lampadas_evento_entregas"
  add_foreign_key "doacao_lampadas", "eventos", name: "fk_doacao_lampadas_eventos"
  add_foreign_key "doacao_lampadas", "lampadas", name: "fk_doacao_lampadas_lampadas"
  add_foreign_key "doacao_lampadas", "modulos", name: "fk_doacao_lampadas_modulos"
  add_foreign_key "doacao_lampadas", "projetos", name: "fk_doacao_lampadas_projetos"
  add_foreign_key "doacao_lampadas", "servicos", name: "fk_doacao_lampadas_servicos"
  add_foreign_key "ecoenel_lancamento_historicos", "ecoenel_lancamento_status", column: "status_anterior_id", name: "fk_hist_status_anterior"
  add_foreign_key "ecoenel_lancamento_historicos", "ecoenel_lancamento_status", column: "status_novo_id", name: "fk_hist_status_novo"
  add_foreign_key "ecoenel_lancamento_historicos", "ecoenel_lancamentos", name: "fk_hist_lancamento", on_delete: :cascade
  add_foreign_key "ecoenel_lancamento_historicos", "usuarios", name: "fk_hist_usuario"
  add_foreign_key "ecoenel_lancamento_residuos", "ecoenel_lancamentos", name: "fk_ecoenel_res_lancamento", on_delete: :cascade
  add_foreign_key "ecoenel_lancamento_residuos", "recursos", name: "fk_ecoenel_res_recurso"
  add_foreign_key "ecoenel_lancamentos", "contratos", name: "fk_ecoenel_lanc_contrato"
  add_foreign_key "ecoenel_lancamentos", "ecoenel_lancamento_status", column: "status_id", name: "fk_ecoenel_lanc_status"
  add_foreign_key "ecoenel_lancamentos", "eventos", name: "fk_ecoenel_lanc_evento"
  add_foreign_key "ecoenel_lancamentos", "recicladors", name: "fk_ecoenel_lanc_reciclador"
  add_foreign_key "ecoenel_lancamentos", "reciclagems", name: "fk_ecoenel_lanc_reciclagem"
  add_foreign_key "ecoenel_lancamentos", "usuarios", column: "gerador_usuario_id", name: "fk_ecoenel_lanc_gerador_usuario"
  add_foreign_key "ecoenel_lancamentos", "usuarios", column: "reciclador_usuario_id", name: "fk_ecoenel_lanc_reciclador_usuario"
  add_foreign_key "esqueci_senha", "usuarios", name: "esqueci_senha_usuario_id_foreign"
  add_foreign_key "estabelecimento_entregas", "estabelecimentos", name: "estabelecimento_entregas_estabelecimento_id_fkey", on_delete: :cascade
  add_foreign_key "estabelecimentos", "ufs", column: "endereco_uf_id", name: "fk_estabelecimentos_ufs"
  add_foreign_key "evento_doacao_lampada_reserva_lampadas", "evento_doacao_lampadas", name: "fk_evento_doacao_lampadas_reserva_lampadas_edl_id"
  add_foreign_key "evento_doacao_lampada_reserva_lampadas", "reserva_lampadas", name: "fk_evento_doacao_lampadas_reserva_lampadas_reserva_id"
  add_foreign_key "evento_doacao_lampadas", "eventos", name: "evento_doacao_lampadas_evento_id_fkey"
  add_foreign_key "evento_entrega_nota_saidas", "evento_entregas", name: "evento_entregas_nota_saidas_evento_entrega_id_fkey", on_delete: :cascade
  add_foreign_key "evento_entrega_nota_saidas", "nota_saidas", name: "evento_entregas_nota_saidas_nota_saida_id_fkey"
  add_foreign_key "evento_entregas", "comunidades", column: "local_entrega", name: "evento_entregas_comunidade_id_fkey"
  add_foreign_key "evento_entregas", "eventos", name: "fk_evento_entregas_eventos"
  add_foreign_key "evento_entregas", "instituicaos", name: "fk_evento_entregas_instituicaos"
  add_foreign_key "evento_escalacaos", "eventos", name: "evento_escalacao_eventos_id_fk"
  add_foreign_key "evento_escalacaos", "usuarios", column: "usuario_operador_id", name: "evento_escalacao_usuarios_id_fk"
  add_foreign_key "evento_escalacaos", "usuarios", name: "evento_escalacao_usuarios_id_fk_2"
  add_foreign_key "evento_historicos", "eventos", name: "eventos_historico_eventos_id_fkey", on_delete: :cascade
  add_foreign_key "evento_historicos", "usuarios", column: "usuario_alteracao", name: "eventos_historico_usuario_alteracao_fkey"
  add_foreign_key "evento_horario_ecopontos", "eventos", name: "horario_ecopontos_eventos_id_fk"
  add_foreign_key "evento_lampadas", "eventos", name: "evento_lampadas_evento_id_fkey"
  add_foreign_key "evento_lampadas", "lampadas", name: "evento_lampadas_lampada_id_fkey"
  add_foreign_key "evento_parceiros", "contratos", column: "contrato_origem_id", name: "fk_contrato_origem"
  add_foreign_key "evento_parceiros", "contratos", name: "fk_evento_parceiros_contrato"
  add_foreign_key "evento_parceiros", "eventos", name: "fk_eventos_parceiros_eventos"
  add_foreign_key "evento_parceiros", "instituicaos", name: "fk_eventos_parceiros_instituicaos"
  add_foreign_key "evento_parceiros", "vigencias", name: "fk_eventos_parceiros_vigencias"
  add_foreign_key "evento_reciclador_vigencias", "eventos", name: "evento_reciclador_vigencias_evento_id_fkey"
  add_foreign_key "evento_reciclador_vigencias", "recicladors", name: "evento_reciclador_vigencias_reciclador_id_fkey"
  add_foreign_key "evento_reciclador_vigencias", "vigencias", name: "evento_reciclador_vigencias_vigencia_id_fkey"
  add_foreign_key "evento_recursos", "eventos", name: "fk_evento_recursos_eventos"
  add_foreign_key "evento_recursos", "recursos", name: "fk_evento_recursos_recursos"
  add_foreign_key "eventos", "acaos", name: "fk_eventos_acaos"
  add_foreign_key "eventos", "comunidades", column: "local_acao", name: "fk_eventos_comunidades"
  add_foreign_key "eventos", "modulos", name: "fk_eventos_modulos"
  add_foreign_key "eventos_nota_saidas", "eventos", name: "fk_eventos_nota_saidas_eventos"
  add_foreign_key "eventos_nota_saidas", "nota_saidas", name: "fk_eventos_nota_saidas_nota_saidas"
  add_foreign_key "eventos_reserva_lampadas", "eventos", name: "fk_eventos_reserva_lampadas_eventos"
  add_foreign_key "eventos_reserva_lampadas", "reserva_lampadas", name: "fk_eventos_reserva_lampadas_reserva_lampadas"
  add_foreign_key "historicos", "clientes", name: "fk_historico_ev_clientes"
  add_foreign_key "historicos", "contratos", name: "fk_historico_ev_contratos"
  add_foreign_key "historicos", "doacao_lampadas", name: "fk_historicos_doacao_lampadas"
  add_foreign_key "historicos", "modulos", name: "historicos_modulo_id_fkey"
  add_foreign_key "instituicaos", "bairros", name: "fk_instituicaos_bairros"
  add_foreign_key "instituicaos", "cidades", name: "fk_instituicaos_cidades"
  add_foreign_key "instituicaos", "ufs", name: "fk_instituicaos_ufs"
  add_foreign_key "instituicaos_contratos", "contratos", name: "fk_instituicaos_contratos_contrato"
  add_foreign_key "instituicaos_contratos", "instituicaos", name: "fk_instituicaos_instituicao"
  add_foreign_key "lampadas", "lampadas_modelo", column: "lampada_modelo_id", name: "lampadas_lampada_modelo_id_fkey"
  add_foreign_key "lampadas", "lampadas_tipo", column: "lampada_tipo_id", name: "lampadas_lampada_tipo_id_fkey"
  add_foreign_key "log_chatbot", "usuarios", name: "FK_fa38605f4b1973a26e0263a3433"
  add_foreign_key "log_chatbot", "usuarios", name: "log_chatbot_usuarios_id_fk"
  add_foreign_key "logs", "usuarios", column: "usuario_alteracao", name: "log_usuario_alteracao_fkey"
  add_foreign_key "menus_modulos", "menus", name: "fk_menus_projetos_menus"
  add_foreign_key "menus_modulos", "modulos", name: "fk_menus_modulos_modulos"
  add_foreign_key "menus_perfils", "menus", name: "fk_menuperfils_idMenu"
  add_foreign_key "menus_perfils", "perfils", name: "fk_menuperfils_idPerfil"
  add_foreign_key "meta_lampadas", "acaos", name: "fk_meta_lampadas_acaos"
  add_foreign_key "meta_lampadas", "lampadas", name: "fk_meta_lampadas_lampadas"
  add_foreign_key "meta_refrigeradors", "acaos", name: "fk_meta_refrigeradors_acaos"
  add_foreign_key "meta_refrigeradors", "equipamentos", name: "fk_meta_refrigeradors_equipamento"
  add_foreign_key "meta_refrigeradors", "refrigeradors", name: "fk_meta_refrigeradors_refrigeradors"
  add_foreign_key "metas", "acaos", name: "fk_metas_acaos"
  add_foreign_key "metas", "modulos", name: "fk_metas_modulos"
  add_foreign_key "modulo_projetos", "modulos", name: "fk_modulo_projetos_modulo"
  add_foreign_key "modulo_projetos", "projetos", name: "fk_modulo_projetos_projeto"
  add_foreign_key "n_log", "usuarios", name: "log_usuario_alteracao_fkey"
  add_foreign_key "nota_fabricantes", "refrigeradors", name: "fk_nota_fabricante_refrigeradors"
  add_foreign_key "nota_fabricantes_nota_saidas", "nota_fabricantes", name: "fk_nota_fabricantes_nota_saidas_nota_fabricantes"
  add_foreign_key "nota_fabricantes_nota_saidas", "nota_saidas", name: "fk_nota_fabricantes_nota_saidas_nota_saidas"
  add_foreign_key "parceiros", "bairros", name: "fk_parceiros_bairros"
  add_foreign_key "parceiros", "cidades", name: "fk_parceiros_cidades"
  add_foreign_key "parceiros", "parceiros_tipos", column: "parceiro_tipo_id", name: "fk_parceiros_parceiro_tipo"
  add_foreign_key "parceiros", "ufs", name: "fk_parceiros_ufs"
  add_foreign_key "parceiros_contratos", "contratos", name: "fk_parceiros_contratos_contrato"
  add_foreign_key "parceiros_contratos", "parceiros", name: "fk_parceiros_contratos_parceiros"
  add_foreign_key "perfil_permissao", "perfils", name: "FK_137296089c30c0eb8ca061a42ea", on_update: :cascade, on_delete: :cascade
  add_foreign_key "perfil_permissao", "permissoes", column: "permissao_id", name: "FK_60fb34e9d84b870a5a9f5ec7fc0", on_update: :cascade, on_delete: :cascade
  add_foreign_key "perfils_modulos", "modulos", name: "fk_perfils_modulos_modulos"
  add_foreign_key "perfils_modulos", "perfils", name: "fk_perfilprojetos_idPerfil"
  add_foreign_key "programacao_estabelecimentos", "estabelecimentos", name: "fk_programacao_estabelecimentos_estabelecimentos", on_delete: :cascade
  add_foreign_key "recicladors", "bairros", name: "fk_recicladors_bairros"
  add_foreign_key "recicladors", "cidades", name: "fk_recicladors_cidades"
  add_foreign_key "recicladors", "ufs", name: "fk_recicladors_ufs"
  add_foreign_key "recicladors_contratos", "contratos", name: "fk_recicladors_contratos_contrato"
  add_foreign_key "recicladors_contratos", "recicladors", name: "fk_recicladors_contratos_reciclador"
  add_foreign_key "reciclagem_recursos", "recicladors", name: "rr_reciclador_id_fkey"
  add_foreign_key "reciclagem_recursos", "reciclagems", name: "fk_reciclagem_recursos_reciclagem"
  add_foreign_key "reciclagem_recursos", "recursos", name: "fk_reciclagem_recursos_recurso"
  add_foreign_key "reciclagem_recursos", "vigencias", name: "rr_vigencia_id_fkey"
  add_foreign_key "reciclagems", "clientes_eventos_contratos", column: "cliente_evento_contrato_id", name: "fk_reciclagem_cliente_evento_contrato"
  add_foreign_key "reciclagems", "contratos", column: "contrato_origem_id", name: "reciclagems_contratos_id_fk"
  add_foreign_key "reciclagems", "reciclagem_integracao", column: "integracao_debito_id", name: "fk_reciclagem_integracao_debito"
  add_foreign_key "reciclagems", "reciclagem_integracao", column: "integracao_id", name: "reciclagems_reciclagem_integracao_id_fk"
  add_foreign_key "reciclagems", "veiculo", name: "fk_reciclagems_veiculo_id"
  add_foreign_key "recursos", "tipo_recursos", name: "fk_recursos_tipo_recurso"
  add_foreign_key "recursos", "unidade_medidas", name: "fk_recursos_unidade_medidas"
  add_foreign_key "refrigeradors", "equipamentos", name: "refrigeradors_equipamento_id_fkey"
  add_foreign_key "refrigeradors", "marca_refrigeradors", name: "fk_refrigeradors_marca_refrigeradors"
  add_foreign_key "reserva_lampada_vendas", "reserva_lampadas", name: "fk_reserva_lampada_vendas_reserva_lampadas"
  add_foreign_key "reserva_lampada_vendas", "vendas", name: "fk_reserva_lampada_vendas_vendas", on_delete: :cascade
  add_foreign_key "reserva_lampadas", "lampadas", name: "fk_reserva_lampadas_lampadas"
  add_foreign_key "reserva_lampadas", "projetos", name: "fk_reserva_lampadas_projetos"
  add_foreign_key "reserva_lampadas_doacao_lampadas", "doacao_lampadas", name: "fk_reserva_lampadas_doacao_lampadas_doacao_lampadas"
  add_foreign_key "reserva_lampadas_doacao_lampadas", "reserva_lampadas", name: "fk_reserva_lampadas_doacao_lampadas_reserva_lampadas"
  add_foreign_key "reserva_lampadas_vistoria_pngd", "reserva_lampadas", name: "fk_reserva_lampadas_vistoria_pngd_reserva_lampadas"
  add_foreign_key "reserva_lampadas_vistoria_pngd", "vistoria_pngd", column: "vistoria_d_id", name: "reserva_lampadas_vistoria_pngd_vistoria_d_id_fkey"
  add_foreign_key "ruas", "bairros", name: "fk_ruas_bairros"
  add_foreign_key "servicos", "parceiros", name: "fk_servicos_parceiros"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "sucata_entradas_itens", "clientes", name: "fk_sucatas_entradas_itens_id_cliente"
  add_foreign_key "sucata_entradas_itens", "contratos", name: "fk_sucatas_entradas_itens_id_contrato"
  add_foreign_key "sucata_entradas_itens", "sucata_entradas_lote", column: "lote_id", name: "fk_sucatas_entradas_itens_id_lote"
  add_foreign_key "sucata_entradas_itens", "sucatas_pngd", column: "sucata_pngd_id", name: "fk_sucatas_entradas_itens_id_sucata_pngd"
  add_foreign_key "sucata_entradas_itens", "sucatas_pngv", column: "sucata_pngv_id", name: "fk_sucatas_entradas_itens_id_sucata"
  add_foreign_key "sucata_entradas_lote", "modulos", name: "fk_sucatas_entradas_lote_id_modulo"
  add_foreign_key "sucata_entradas_lote", "parceiros", name: "fk_sucatas_entradas_lote_id_parceiro"
  add_foreign_key "sucata_entradas_lote", "usuarios", column: "usuario_recebimento", name: "fk_sucatas_entradas_lote_id_usuario"
  add_foreign_key "sucata_saidas_itens", "sucata_entradas_itens", column: "item_entrada_id", name: "fk_sucatas_saidas_itens_id_item"
  add_foreign_key "sucata_saidas_itens", "sucata_saidas_lote", column: "lote_id", name: "fk_sucatas_saidas_itens_id_lote"
  add_foreign_key "sucata_saidas_lote", "modulos", name: "fk_sucatas_saidas_lote_id_modulo"
  add_foreign_key "sucata_saidas_lote", "parceiros", name: "fk_sucatas_saidas_lote_id_parceiro"
  add_foreign_key "sucata_saidas_lote", "usuarios", column: "usuario_saida", name: "fk_sucatas_saidas_lote_id_usuario"
  add_foreign_key "sucatas_lampada", "doacao_lampadas", name: "sucatas_lampadas_doacao_lampada_id_fkey", on_delete: :cascade
  add_foreign_key "sucatas_lampada", "lampadas_tipo", column: "lampada_id", name: "sucatas_lampadas_lampada_id_fkey", on_delete: :cascade
  add_foreign_key "sucatas_pngd", "equipamentos", name: "sucata_pngd_equipamento_id_fkey"
  add_foreign_key "sucatas_pngd", "marca_refrigeradors", name: "fk_sucata_pngd_marca_refrigeradors"
  add_foreign_key "sucatas_pngd", "triagem_pngd", column: "triagem_d_id", name: "fk_sucata_pngd_triagem_pngd_id", on_delete: :cascade
  add_foreign_key "sucatas_pngv", "marca_refrigeradors", name: "fk_sucatas_marca_refrigeradors"
  add_foreign_key "sucatas_pngv", "triagem_pngv", name: "fk_sucatas_triagems", on_delete: :cascade
  add_foreign_key "triagem_pngd", "clientes_eventos_contratos", column: "cliente_evento_contrato_id", name: "triagem_pngd_cliente_evento_contrato_id_fkey", on_delete: :cascade
  add_foreign_key "triagem_pngv", "clientes_contratos_projetos", column: "cliente_contrato_projeto_id", name: "triagem_pngv_cliente_contrato_projeto_id_fkey", on_delete: :cascade
  add_foreign_key "triagem_pngv", "estabelecimentos", name: "fk_triagems_estabelecimentos"
  add_foreign_key "usuarios", "eventos", name: "usuarios_evento_id_fkey"
  add_foreign_key "usuarios", "perfils", name: "fk_usuarios_perfils"
  add_foreign_key "usuarios", "recicladors", name: "usuarios_reciclador_id_fkey"
  add_foreign_key "veiculo", "tipo_veiculo", name: "veiculo_tipo_veiculo_id_fkey"
  add_foreign_key "venda_historicos", "usuarios", column: "usuario_alteracao", name: "vendas_historico_usuario_alteracao_fkey"
  add_foreign_key "venda_historicos", "vendas", column: "vendas_id", name: "vendas_historico_vendas_id_fkey", on_delete: :cascade
  add_foreign_key "vendas", "estabelecimentos", name: "fk_vendas_estabelecimentos"
  add_foreign_key "vendas", "lampadas", name: "fk_vendas_lampadas"
  add_foreign_key "vendas", "refrigeradors", name: "fk_vendas_refrigeradors"
  add_foreign_key "vendas", "sucatas_pngv", column: "sucata_pngv_id", name: "fk_vendas_sucatas", on_delete: :cascade
  add_foreign_key "vendas", "usuarios", name: "fk_vendas_usuarios"
  add_foreign_key "vistoria_pngd", "nota_fabricantes_nota_saidas", column: "nota_fabricante_nota_saida_id", name: "fk_vistoria_pngd_nota_fabricante_nota_saida_id"
  add_foreign_key "vistoria_pngd", "triagem_pngd", column: "triagem_d_id", name: "fk_vistoria_pngd_triagem_pngd"
  add_foreign_key "vistoria_pngd", "usuarios", name: "fk_vistoria_pngd_usuarios"
end
