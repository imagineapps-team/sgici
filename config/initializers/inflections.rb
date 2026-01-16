# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

# Inflexões para português brasileiro (SGICI)
ActiveSupport::Inflector.inflections(:en) do |inflect|
  # Processos de importação
  inflect.irregular 'processo_importacao', 'processos_importacao'
  inflect.irregular 'processo_prestador', 'processo_prestadores'

  # Prestadores e fornecedores
  inflect.irregular 'prestador_servico', 'prestadores_servico'
  inflect.irregular 'fornecedor', 'fornecedores'

  # Custos
  inflect.irregular 'categoria_custo', 'categorias_custo'
  inflect.irregular 'custo_previsto', 'custos_previstos'
  inflect.irregular 'custo_real', 'custos_reais'

  # Eventos e ocorrências
  inflect.irregular 'evento_logistico', 'eventos_logisticos'
  inflect.irregular 'ocorrencia', 'ocorrencias'

  # Outros
  inflect.irregular 'aprovacao', 'aprovacoes'
  inflect.irregular 'notificacao', 'notificacoes'
  inflect.irregular 'configuracao_usuario', 'configuracoes_usuario'
  inflect.irregular 'anexo', 'anexos'
  inflect.irregular 'usuario', 'usuarios'
end
