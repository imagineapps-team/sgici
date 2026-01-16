# frozen_string_literal: true

# Service para cálculo automático de impostos de importação
#
# Fórmulas baseadas na legislação brasileira:
# - Base = (FOB + Frete Internacional + Seguro) * Taxa Câmbio
# - II = Base * Alíquota II
# - IPI = (Base + II) * Alíquota IPI
# - PIS/COFINS = Base * Alíquota PIS/COFINS
# - ICMS = ((Base + II + IPI + PIS/COFINS) / (1 - Alíquota ICMS)) * Alíquota ICMS
#
class CalculadoraImpostosService
  # Alíquotas padrão (podem ser sobrescritas via parâmetros)
  ALIQUOTAS_PADRAO = {
    ii: 0.14,        # 14% - Imposto de Importação
    ipi: 0.10,       # 10% - IPI
    pis_cofins: 0.0965, # 9.65% - PIS/COFINS combinado
    icms: 0.18       # 18% - ICMS (varia por estado)
  }.freeze

  attr_reader :fob, :frete, :seguro, :taxa_cambio, :aliquotas

  # @param fob [Decimal] Valor FOB em moeda estrangeira
  # @param frete [Decimal] Frete internacional em moeda estrangeira
  # @param seguro [Decimal] Seguro internacional em moeda estrangeira
  # @param taxa_cambio [Decimal] Taxa de câmbio para BRL
  # @param aliquotas [Hash] Alíquotas customizadas (opcional)
  def initialize(fob:, frete: 0, seguro: 0, taxa_cambio: 1, aliquotas: {})
    @fob = fob.to_d
    @frete = frete.to_d
    @seguro = seguro.to_d
    @taxa_cambio = taxa_cambio.to_d
    @aliquotas = ALIQUOTAS_PADRAO.merge(aliquotas.symbolize_keys)
  end

  # Calcula todos os impostos e retorna um hash completo
  # @return [Hash] Hash com todos os valores calculados
  def calcular
    {
      fob_brl: fob_brl,
      frete_brl: frete_brl,
      seguro_brl: seguro_brl,
      base_calculo: base_calculo,
      ii: ii,
      ipi: ipi,
      pis_cofins: pis_cofins,
      icms: icms,
      total_impostos: total_impostos,
      custo_total: custo_total,
      aliquotas: {
        ii: aliquota_ii,
        ipi: aliquota_ipi,
        pis_cofins: aliquota_pis_cofins,
        icms: aliquota_icms
      }
    }
  end

  # Calcula e retorna custos previstos para criação em lote
  # @param processo [ProcessoImportacao] Processo de importação
  # @param usuario [Usuario] Usuário que está criando
  # @return [Array<Hash>] Array de hashes para criação de custos previstos
  def custos_previstos_para_criar(processo, usuario)
    categorias = categorias_impostos

    [
      custo_hash(categorias[:ii], ii, 'Imposto de Importação calculado automaticamente'),
      custo_hash(categorias[:ipi], ipi, 'IPI calculado automaticamente'),
      custo_hash(categorias[:pis_cofins], pis_cofins, 'PIS/COFINS calculado automaticamente'),
      custo_hash(categorias[:icms], icms, 'ICMS calculado automaticamente')
    ].compact.map do |custo|
      custo.merge(
        processo_importacao_id: processo.id,
        criado_por_id: usuario.id,
        moeda: 'BRL',
        taxa_cambio: 1
      )
    end
  end

  # Valor FOB convertido para BRL
  def fob_brl
    (fob * taxa_cambio).round(2)
  end

  # Frete convertido para BRL
  def frete_brl
    (frete * taxa_cambio).round(2)
  end

  # Seguro convertido para BRL
  def seguro_brl
    (seguro * taxa_cambio).round(2)
  end

  # Base de cálculo (CIF em BRL)
  def base_calculo
    (fob_brl + frete_brl + seguro_brl).round(2)
  end

  # Imposto de Importação
  def ii
    (base_calculo * aliquota_ii).round(2)
  end

  # IPI - base = CIF + II
  def ipi
    ((base_calculo + ii) * aliquota_ipi).round(2)
  end

  # PIS/COFINS - incide sobre base
  def pis_cofins
    (base_calculo * aliquota_pis_cofins).round(2)
  end

  # ICMS - cálculo "por dentro"
  # ICMS = ((Base + II + IPI + PIS/COFINS) / (1 - Alíquota ICMS)) * Alíquota ICMS
  def icms
    return 0.0 if aliquota_icms.zero?

    base_icms = base_calculo + ii + ipi + pis_cofins
    ((base_icms / (1 - aliquota_icms)) * aliquota_icms).round(2)
  end

  # Total de impostos
  def total_impostos
    (ii + ipi + pis_cofins + icms).round(2)
  end

  # Custo total (CIF + impostos)
  def custo_total
    (base_calculo + total_impostos).round(2)
  end

  private

  def aliquota_ii
    aliquotas[:ii].to_d
  end

  def aliquota_ipi
    aliquotas[:ipi].to_d
  end

  def aliquota_pis_cofins
    aliquotas[:pis_cofins].to_d
  end

  def aliquota_icms
    aliquotas[:icms].to_d
  end

  def categorias_impostos
    {
      ii: CategoriaCusto.find_by(codigo: 'II'),
      ipi: CategoriaCusto.find_by(codigo: 'IPI'),
      pis_cofins: CategoriaCusto.find_by(codigo: 'PIS_COFINS'),
      icms: CategoriaCusto.find_by(codigo: 'ICMS')
    }
  end

  def custo_hash(categoria, valor, descricao)
    return nil if categoria.nil? || valor.zero?

    {
      categoria_custo_id: categoria.id,
      valor: valor,
      valor_brl: valor,
      descricao: descricao
    }
  end
end
