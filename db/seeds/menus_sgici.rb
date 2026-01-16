# frozen_string_literal: true

# Seeds de Menus para o SGICI
# Configura a estrutura de menus e permissoes do sistema

puts "  Configurando menus do SGICI..."

# Limpar menus antigos (reciclagem)
menus_antigos = %w[
  reciclagens recibos beneficiarios contratos clientes acaos tipo_acaos eventos
  instituicaos parceiros recicladors tipo_residuos unidade_medidas residuos
  comunidades bairros campanhas veiculos
]

Menu.where(controller: menus_antigos).destroy_all
puts "    - Menus antigos removidos"

# Estrutura de menus do SGICI
# Formato: { nome:, controller:, action: (opcional) }
# Nota: tabela menus nao tem campo 'ordem' no banco atual

menus_data = [
  # Principal
  { nome: 'Dashboard', controller: 'dashboard', action: 'index' },

  # Operacional
  { nome: 'Processos de Importacao', controller: 'processos_importacao' },
  { nome: 'Custos Previstos', controller: 'custos_previstos' },
  { nome: 'Custos Reais', controller: 'custos_reais' },
  { nome: 'Eventos Logisticos', controller: 'eventos_logisticos' },

  # Cadastros
  { nome: 'Fornecedores', controller: 'fornecedores' },
  { nome: 'Prestadores de Servico', controller: 'prestadores_servico' },
  { nome: 'Categorias de Custo', controller: 'categorias_custo' },

  # Relatorios
  { nome: 'Relatorio de Processos', controller: 'relatorios', action: 'processos' },
  { nome: 'Analise de Custos', controller: 'relatorios', action: 'custos' },
  { nome: 'Performance Fornecedores', controller: 'relatorios', action: 'fornecedores' },

  # Administrativo
  { nome: 'Usuarios', controller: 'usuarios' },
  { nome: 'Controle de Acesso', controller: 'permissoes_menu' }
]

created_count = 0
updated_count = 0

menus_data.each do |menu_attrs|
  # Buscar por controller + action (ou apenas controller se action nil)
  if menu_attrs[:action].present?
    menu = Menu.find_or_initialize_by(controller: menu_attrs[:controller], action: menu_attrs[:action])
  else
    menu = Menu.find_or_initialize_by(controller: menu_attrs[:controller])
  end

  was_new = menu.new_record?

  menu.assign_attributes(
    nome: menu_attrs[:nome]
  )

  if menu.save
    if was_new
      created_count += 1
    else
      updated_count += 1
    end
  else
    puts "    ! Erro ao criar menu #{menu_attrs[:nome]}: #{menu.errors.full_messages.join(', ')}"
  end
end

puts "    - #{created_count} menus criados"
puts "    - #{updated_count} menus atualizados" if updated_count > 0

# Associar menus ao perfil Admin (se existir)
perfil_admin = Perfil.find_by(nome: 'Administrador') || Perfil.find_by(administrador: true)

if perfil_admin
  # Associar todos os menus ao admin
  menus_sgici = Menu.where(controller: menus_data.map { |m| m[:controller] }.uniq)
  menus_sgici.each do |menu|
    perfil_admin.menus << menu unless perfil_admin.menus.include?(menu)
  end
  puts "    - Menus associados ao perfil Admin (#{perfil_admin.nome})"
else
  puts "    ! Perfil Admin nao encontrado"
end

puts "  Menus do SGICI configurados!"
