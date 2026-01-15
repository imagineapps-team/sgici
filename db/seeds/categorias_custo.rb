# frozen_string_literal: true

# Seeds para Categorias de Custo do SGICI

puts "Criando categorias de custo..."

categorias = [
  # Custos de Produto
  { nome: "Valor FOB", codigo: "FOB", grupo: "fob", tipo: "ambos", ordem: 1, obrigatorio: true,
    descricao: "Valor do produto no local de origem (Free on Board)" },

  # Custos Internacionais
  { nome: "Frete Internacional", codigo: "FRETE_INT", grupo: "frete", tipo: "ambos", ordem: 10, obrigatorio: true,
    descricao: "Custo do transporte internacional (marítimo, aéreo ou rodoviário)" },
  { nome: "Seguro Internacional", codigo: "SEGURO_INT", grupo: "seguro", tipo: "ambos", ordem: 11,
    descricao: "Seguro da carga durante transporte internacional" },
  { nome: "Taxas de Origem", codigo: "TAXAS_ORIGEM", grupo: "frete", tipo: "ambos", ordem: 12,
    descricao: "Taxas cobradas no porto/aeroporto de origem" },
  { nome: "THC Origem", codigo: "THC_ORIGEM", grupo: "frete", tipo: "ambos", ordem: 13,
    descricao: "Terminal Handling Charge no porto de origem" },

  # Impostos de Importação
  { nome: "Imposto de Importação (II)", codigo: "II", grupo: "impostos", tipo: "ambos", ordem: 20, obrigatorio: true,
    descricao: "Imposto federal sobre produtos importados" },
  { nome: "IPI", codigo: "IPI", grupo: "impostos", tipo: "ambos", ordem: 21,
    descricao: "Imposto sobre Produtos Industrializados" },
  { nome: "PIS Importação", codigo: "PIS_IMP", grupo: "impostos", tipo: "ambos", ordem: 22,
    descricao: "Contribuição PIS sobre importação" },
  { nome: "COFINS Importação", codigo: "COFINS_IMP", grupo: "impostos", tipo: "ambos", ordem: 23,
    descricao: "Contribuição COFINS sobre importação" },
  { nome: "ICMS", codigo: "ICMS", grupo: "impostos", tipo: "ambos", ordem: 24,
    descricao: "Imposto estadual sobre circulação de mercadorias" },
  { nome: "Taxa Siscomex", codigo: "SISCOMEX", grupo: "impostos", tipo: "real", ordem: 25,
    descricao: "Taxa de utilização do Siscomex" },
  { nome: "AFRMM", codigo: "AFRMM", grupo: "impostos", tipo: "ambos", ordem: 26,
    descricao: "Adicional ao Frete para Renovação da Marinha Mercante" },

  # Custos Portuários/Aeroportuários
  { nome: "THC Destino", codigo: "THC_DESTINO", grupo: "armazenagem", tipo: "ambos", ordem: 30,
    descricao: "Terminal Handling Charge no porto de destino" },
  { nome: "Capatazia", codigo: "CAPATAZIA", grupo: "armazenagem", tipo: "ambos", ordem: 31,
    descricao: "Movimentação de carga no terminal" },
  { nome: "Armazenagem", codigo: "ARMAZENAGEM", grupo: "armazenagem", tipo: "ambos", ordem: 32,
    descricao: "Custos de armazenamento em recinto alfandegado" },
  { nome: "Demurrage", codigo: "DEMURRAGE", grupo: "armazenagem", tipo: "real", ordem: 33,
    descricao: "Multa por atraso na devolução de container" },
  { nome: "Detention", codigo: "DETENTION", grupo: "armazenagem", tipo: "real", ordem: 34,
    descricao: "Multa por retenção de container fora do terminal" },

  # Serviços de Despachante
  { nome: "Honorários Despachante", codigo: "DESPACHANTE", grupo: "servicos", tipo: "ambos", ordem: 40,
    descricao: "Honorários do despachante aduaneiro" },
  { nome: "Taxa de Liberação", codigo: "LIBERACAO", grupo: "servicos", tipo: "real", ordem: 41,
    descricao: "Taxa para liberação da carga" },

  # Transporte Nacional
  { nome: "Frete Nacional", codigo: "FRETE_NAC", grupo: "transporte", tipo: "ambos", ordem: 50,
    descricao: "Frete do porto/aeroporto até destino final" },
  { nome: "Seguro Nacional", codigo: "SEGURO_NAC", grupo: "seguro", tipo: "ambos", ordem: 51,
    descricao: "Seguro da carga no transporte nacional" },

  # Outros Custos
  { nome: "Inspeção/Vistoria", codigo: "INSPECAO", grupo: "outros", tipo: "ambos", ordem: 60,
    descricao: "Custos de inspeção ou vistoria da carga" },
  { nome: "Certificações", codigo: "CERTIFICACOES", grupo: "outros", tipo: "ambos", ordem: 61,
    descricao: "Custos com certificados e laudos" },
  { nome: "Embalagem", codigo: "EMBALAGEM", grupo: "outros", tipo: "ambos", ordem: 62,
    descricao: "Custos de embalagem especial" },
  { nome: "Câmbio (Spread)", codigo: "CAMBIO", grupo: "outros", tipo: "real", ordem: 63,
    descricao: "Spread bancário na operação de câmbio" },
  { nome: "Outros Custos", codigo: "OUTROS", grupo: "outros", tipo: "ambos", ordem: 99,
    descricao: "Custos diversos não categorizados" }
]

categorias.each do |attrs|
  CategoriaCusto.find_or_create_by!(codigo: attrs[:codigo]) do |cat|
    cat.assign_attributes(attrs)
  end
end

puts "#{CategoriaCusto.count} categorias de custo criadas."
