# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "=" * 60
puts "SGICI - Sistema de Gestão de Importações, Custos e Indicadores"
puts "=" * 60

# Carregar seeds na ordem correta
seed_files = %w[
  feature_flags
  categorias_custo
  menus_sgici
  dados_exemplo
]

seed_files.each do |seed_file|
  seed_path = Rails.root.join("db/seeds/#{seed_file}.rb")
  if File.exist?(seed_path)
    puts "\n>> Carregando seeds: #{seed_file}"
    load seed_path
  else
    puts "\n>> Arquivo não encontrado: #{seed_file}"
  end
end

puts "\n" + "=" * 60
puts "Seeds carregados com sucesso!"
puts "=" * 60
