# frozen_string_literal: true

# Migration idempotente para criar tabela indices_ambientais
# Funciona em ambiente multiapp - não falha se tabela já existir
class CreateIndicesAmbientaisIfNotExists < ActiveRecord::Migration[7.1]
  def up
    # Verifica se a tabela já existe (EcoEnel já tem, Light não)
    return if table_exists?(:indices_ambientais)

    create_table :indices_ambientais, id: :serial, comment: 'Índices ambientais configuráveis - Valores únicos para reutilização em todo o sistema' do |t|
      t.boolean :ativo, default: true
      t.string :codigo, limit: 50, null: false, comment: 'Código único para referência no código (ex: CO2_EVITADO)'
      t.datetime :data_atualizacao, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :data_cadastro, default: -> { 'CURRENT_TIMESTAMP' }
      t.float :fator, null: false, comment: 'Valor numérico usado no cálculo'
      t.string :fonte_estudo, limit: 200, null: false, comment: 'Fonte científica ou técnica do índice'
      t.string :formula_display, limit: 100, null: false, comment: 'Fórmula formatada para exibição ao usuário'
      t.string :nome, limit: 100, null: false
      t.text :referencia_url
      t.string :tipo_operacao, limit: 20, null: false, comment: 'Tipo de operação matemática: MULTIPLY ou DIVIDE'
      t.string :unidade_entrada, limit: 20, null: false
      t.string :unidade_saida, limit: 50, null: false
    end

    add_index :indices_ambientais, :ativo, name: 'idx_indices_ambientais_ativo'
    add_index :indices_ambientais, :codigo, name: 'idx_indices_ambientais_codigo', unique: true

    # Inserir dados dos índices ambientais
    seed_indices_ambientais
  end

  def down
    drop_table :indices_ambientais if table_exists?(:indices_ambientais)
  end

  private

  def seed_indices_ambientais
    indices = [
      {
        codigo: 'CO2_EVITADO',
        nome: 'CO₂ Evitado',
        tipo_operacao: 'MULTIPLY',
        fator: 0.0545,
        unidade_entrada: 'kWh',
        unidade_saida: 'kg CO₂',
        formula_display: 'kWh × 0,0545',
        fonte_estudo: 'GHG Protocol 2024',
        referencia_url: 'https://www.ghgprotocolbrasil.com.br/'
      },
      {
        codigo: 'ARVORES_EQUIVALENTES',
        nome: 'Árvores Equivalentes',
        tipo_operacao: 'DIVIDE',
        fator: 73.4,
        unidade_entrada: 'kg CO₂',
        unidade_saida: 'árvores/ano',
        formula_display: 'CO₂ ÷ 73,4',
        fonte_estudo: 'Embrapa ILPF',
        referencia_url: 'https://www.embrapa.br/ilpf'
      },
      {
        codigo: 'KM_NAO_PERCORRIDOS',
        nome: 'KM Não Percorridos',
        tipo_operacao: 'DIVIDE',
        fator: 0.192,
        unidade_entrada: 'kg CO₂',
        unidade_saida: 'km',
        formula_display: 'CO₂ ÷ 0,192',
        fonte_estudo: 'GHG Protocol',
        referencia_url: 'https://www.ghgprotocolbrasil.com.br/'
      },
      {
        codigo: 'TEMPO_CHUVEIRO',
        nome: 'Tempo Chuveiro',
        tipo_operacao: 'DIVIDE',
        fator: 5.5,
        unidade_entrada: 'kWh',
        unidade_saida: 'horas',
        formula_display: 'kWh ÷ 5,5',
        fonte_estudo: 'Descarbonize',
        referencia_url: 'https://descarbonize.org.br/'
      },
      {
        codigo: 'TEMPO_AR_CONDICIONADO',
        nome: 'Tempo Ar-Condicionado 9.000 BTU',
        tipo_operacao: 'DIVIDE',
        fator: 0.77,
        unidade_entrada: 'kWh',
        unidade_saida: 'horas',
        formula_display: 'kWh ÷ 0,77',
        fonte_estudo: 'Sorocaba Elétrica',
        referencia_url: 'https://sorocabaeletrica.com.br/'
      },
      {
        codigo: 'TEMPO_LAMPADA_LED',
        nome: 'Tempo Lâmpada LED',
        tipo_operacao: 'DIVIDE',
        fator: 0.01,
        unidade_entrada: 'kWh',
        unidade_saida: 'horas',
        formula_display: 'kWh ÷ 0,01',
        fonte_estudo: 'Especificação Técnica',
        referencia_url: nil
      },
      {
        codigo: 'TEMPO_TV',
        nome: 'Tempo TV',
        tipo_operacao: 'DIVIDE',
        fator: 0.1,
        unidade_entrada: 'kWh',
        unidade_saida: 'horas',
        formula_display: 'kWh ÷ 0,1',
        fonte_estudo: 'Especificação Técnica',
        referencia_url: nil
      },
      {
        codigo: 'AGUA_ECONOMIZADA',
        nome: 'Água Economizada',
        tipo_operacao: 'MULTIPLY',
        fator: 32_000,
        unidade_entrada: 'toneladas',
        unidade_saida: 'litros',
        formula_display: 'ton × 32.000',
        fonte_estudo: 'BIR / WWF',
        referencia_url: 'https://www.bir.org/'
      },
      {
        codigo: 'PISCINAS_OLIMPICAS',
        nome: 'Piscinas Olímpicas',
        tipo_operacao: 'DIVIDE',
        fator: 2_500_000,
        unidade_entrada: 'litros',
        unidade_saida: 'piscinas',
        formula_display: 'litros ÷ 2.500.000',
        fonte_estudo: 'Volume Olímpico',
        referencia_url: 'https://www.fina.org/'
      },
      {
        codigo: 'CARVAO_EVITADO',
        nome: 'Carvão Evitado',
        tipo_operacao: 'DIVIDE',
        fator: 2.86,
        unidade_entrada: 'kg CO₂',
        unidade_saida: 'kg carvão',
        formula_display: 'CO₂ ÷ 2,86',
        fonte_estudo: 'IPCC',
        referencia_url: 'https://www.ipcc.ch/'
      }
    ]

    indices.each do |indice|
      execute <<-SQL.squish
        INSERT INTO indices_ambientais (codigo, nome, tipo_operacao, fator, unidade_entrada, unidade_saida, formula_display, fonte_estudo, referencia_url, ativo, data_cadastro, data_atualizacao)
        VALUES (
          '#{indice[:codigo]}',
          '#{indice[:nome]}',
          '#{indice[:tipo_operacao]}',
          #{indice[:fator]},
          '#{indice[:unidade_entrada]}',
          '#{indice[:unidade_saida]}',
          '#{indice[:formula_display]}',
          '#{indice[:fonte_estudo]}',
          #{indice[:referencia_url] ? "'#{indice[:referencia_url]}'" : 'NULL'},
          true,
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP
        )
        ON CONFLICT (codigo) DO NOTHING
      SQL
    end
  end
end
