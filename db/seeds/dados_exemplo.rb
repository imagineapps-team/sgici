# frozen_string_literal: true

# Seeds de dados de exemplo para desenvolvimento do SGICI

return unless Rails.env.development?

puts "Criando dados de exemplo para desenvolvimento..."

# Criar usuário admin se não existir
admin = Usuario.find_or_create_by!(email: "admin@sgici.com") do |u|
  u.nome = "Administrador"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.perfil_id = Perfil.find_or_create_by!(nome: "Administrador").id
end

gestor = Usuario.find_or_create_by!(email: "gestor@sgici.com") do |u|
  u.nome = "Gestor de Importação"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.perfil_id = Perfil.find_or_create_by!(nome: "Gestor").id
end

operacional = Usuario.find_or_create_by!(email: "operacional@sgici.com") do |u|
  u.nome = "Operador Logístico"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.perfil_id = Perfil.find_or_create_by!(nome: "Operacional").id
end

puts "Usuários criados: admin, gestor, operacional (senha: password123)"

# Fornecedores
fornecedores_data = [
  {
    nome: "Shenzhen Electronics Co., Ltd",
    pais: "China",
    cidade: "Shenzhen",
    email: "sales@shenzhenelec.com",
    moeda_padrao: "USD",
    prazo_pagamento_dias: 30,
    contato_comercial_nome: "Wang Wei",
    contato_comercial_email: "wang@shenzhenelec.com"
  },
  {
    nome: "Shanghai Trading Corp",
    pais: "China",
    cidade: "Shanghai",
    email: "export@shanghaitrading.com",
    moeda_padrao: "USD",
    prazo_pagamento_dias: 45,
    contato_comercial_nome: "Li Ming",
    contato_comercial_email: "li@shanghaitrading.com"
  },
  {
    nome: "US Parts Supply Inc",
    pais: "Estados Unidos",
    estado: "California",
    cidade: "Los Angeles",
    email: "orders@usparts.com",
    moeda_padrao: "USD",
    prazo_pagamento_dias: 30,
    contato_comercial_nome: "John Smith",
    contato_comercial_email: "john@usparts.com"
  }
]

fornecedores_data.each do |attrs|
  Fornecedor.find_or_create_by!(nome: attrs[:nome]) do |f|
    f.assign_attributes(attrs)
  end
end

puts "#{Fornecedor.count} fornecedores criados."

# Prestadores de Serviço
prestadores_data = [
  { nome: "DHL Global Forwarding", tipo: "freight_forwarder", pais: "Brasil", cidade: "Santos" },
  { nome: "Kuehne + Nagel", tipo: "freight_forwarder", pais: "Brasil", cidade: "Santos" },
  { nome: "Despachos Aduaneiros Brasil", tipo: "despachante", pais: "Brasil", cidade: "Santos" },
  { nome: "Mapfre Seguros", tipo: "seguradora", pais: "Brasil", cidade: "São Paulo" },
  { nome: "Transportes Rápido", tipo: "transportadora", pais: "Brasil", cidade: "São Paulo" },
  { nome: "Santos Port Logistics", tipo: "armazem", pais: "Brasil", cidade: "Santos" }
]

prestadores_data.each do |attrs|
  PrestadorServico.find_or_create_by!(nome: attrs[:nome]) do |p|
    p.assign_attributes(attrs)
  end
end

puts "#{PrestadorServico.count} prestadores de serviço criados."

# Processos de Importação de Exemplo
if ProcessoImportacao.count == 0
  fornecedor_china = Fornecedor.find_by(pais: "China")

  processos_data = [
    {
      numero: "IMP-2026-0001",
      fornecedor: fornecedor_china,
      criado_por: operacional,
      responsavel: gestor,
      pais_origem: "China",
      porto_origem: "Shanghai",
      porto_destino: "Santos",
      modal: "maritimo",
      incoterm: "FOB",
      moeda: "USD",
      taxa_cambio: 5.85,
      valor_fob: 50000.00,
      status: "em_transito",
      data_criacao: 30.days.ago,
      data_pedido: 28.days.ago,
      data_embarque_prevista: 15.days.ago,
      data_embarque_real: 14.days.ago,
      data_chegada_prevista: 10.days.from_now,
      descricao_mercadoria: "Componentes eletrônicos diversos"
    },
    {
      numero: "IMP-2026-0002",
      fornecedor: fornecedor_china,
      criado_por: operacional,
      responsavel: gestor,
      pais_origem: "China",
      porto_origem: "Shenzhen",
      porto_destino: "Santos",
      modal: "maritimo",
      incoterm: "CIF",
      moeda: "USD",
      taxa_cambio: 5.82,
      valor_fob: 75000.00,
      status: "planejado",
      data_criacao: 5.days.ago,
      data_pedido: 3.days.ago,
      data_embarque_prevista: 15.days.from_now,
      data_chegada_prevista: 45.days.from_now,
      descricao_mercadoria: "Equipamentos industriais"
    },
    {
      numero: "IMP-2026-0003",
      fornecedor: Fornecedor.find_by(pais: "Estados Unidos"),
      criado_por: operacional,
      responsavel: gestor,
      pais_origem: "Estados Unidos",
      aeroporto_origem: "LAX",
      aeroporto_destino: "GRU",
      modal: "aereo",
      incoterm: "EXW",
      moeda: "USD",
      taxa_cambio: 5.88,
      valor_fob: 25000.00,
      status: "desembaracado",
      data_criacao: 20.days.ago,
      data_pedido: 18.days.ago,
      data_embarque_prevista: 12.days.ago,
      data_embarque_real: 12.days.ago,
      data_chegada_prevista: 10.days.ago,
      data_chegada_real: 9.days.ago,
      data_desembaraco: 2.days.ago,
      descricao_mercadoria: "Peças de reposição urgentes"
    }
  ]

  processos_data.each do |attrs|
    ProcessoImportacao.create!(attrs)
  end

  puts "#{ProcessoImportacao.count} processos de importação criados."

  # Custos para os processos
  processo1 = ProcessoImportacao.find_by(numero: "IMP-2026-0001")
  cat_fob = CategoriaCusto.find_by(codigo: "FOB")
  cat_frete = CategoriaCusto.find_by(codigo: "FRETE_INT")
  cat_seguro = CategoriaCusto.find_by(codigo: "SEGURO_INT")
  cat_ii = CategoriaCusto.find_by(codigo: "II")

  if processo1 && cat_fob
    # Custos Previstos
    CustoPrevisto.create!(
      processo_importacao: processo1,
      categoria_custo: cat_fob,
      criado_por: operacional,
      valor: 50000.00,
      moeda: "USD",
      taxa_cambio: 5.85,
      valor_brl: 292500.00
    )

    CustoPrevisto.create!(
      processo_importacao: processo1,
      categoria_custo: cat_frete,
      criado_por: operacional,
      valor: 3500.00,
      moeda: "USD",
      taxa_cambio: 5.85,
      valor_brl: 20475.00
    )

    # Custos Reais (parcialmente lançados)
    CustoReal.create!(
      processo_importacao: processo1,
      categoria_custo: cat_fob,
      criado_por: operacional,
      valor: 50000.00,
      moeda: "USD",
      taxa_cambio: 5.85,
      valor_brl: 292500.00,
      data_lancamento: 14.days.ago,
      status_pagamento: "pago",
      data_pagamento: 10.days.ago
    )

    puts "Custos de exemplo criados para processo IMP-2026-0001."
  end
end

puts "Dados de exemplo criados com sucesso!"
