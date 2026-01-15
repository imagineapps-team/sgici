# frozen_string_literal: true

# Feature Flags para Arquitetura Multi-App
#
# Execute com: rails runner db/seeds/feature_flags.rb
# Ou inclua no db/seeds.rb
#
# Este arquivo configura as feature flags baseadas no APP_PROFILE atual.

puts "Configurando feature flags para #{AppProfile.current}..."

# === MÓDULOS LIGHT-ESPECÍFICOS ===
# Estes módulos só existem no Light

light_modules = %i[
  modulo_doacao_lampadas
  modulo_doacao_pngd
  modulo_venda_pngv
]

# === FEATURES DENTRO DE MÓDULOS ===
# Features específicas que podem variar

lamp_features = %i[
  lampadas_led_apenas
  lampadas_saldo_livre
  lampadas_sucata_obrigatoria
  lampadas_produto_brinde
]

pngd_features = %i[
  pngd_vistoria_digital
  pngd_termo_garantia_digital
]

pngv_features = %i[
  pngv_quiosque
  pngv_nota_fiscal_digital
]

# === KILL SWITCHES ===
# Para desabilitar emergencialmente

kill_switches = %i[
  kill_doacao_lampadas
  kill_doacao_pngd
  kill_vendas
  kill_reciclagem
]

# === CONFIGURAÇÃO POR APP_PROFILE ===

case AppProfile.current
when :light
  puts "  -> Configurando Light..."

  # Light NÃO tem módulo de doação de lâmpadas
  # Estes módulos pertencem a outra aplicação (futura)
  # Desabilitar todos os módulos light-específicos
  light_modules.each do |feature|
    Flipper.disable(feature)
    puts "     ✗ #{feature} = OFF"
  end

  # Features de lâmpadas desabilitadas (módulo não pertence ao Light)
  Flipper.disable(:lampadas_sucata_obrigatoria)
  Flipper.disable(:lampadas_produto_brinde)

  # Kill switches (default OFF - desabilitados = sistema funcionando)
  kill_switches.each do |feature|
    Flipper.disable(feature)
  end

when :ecoenel
  puts "  -> Configurando EcoEnel..."

  # Desabilita módulos Light
  light_modules.each do |feature|
    Flipper.disable(feature)
    puts "     ✗ #{feature} = OFF"
  end

  # Kill switches (default OFF)
  kill_switches.each do |feature|
    Flipper.disable(feature)
  end

else
  puts "  -> Profile '#{AppProfile.current}' não reconhecido, mantendo defaults..."
end

puts ""
puts "Feature flags configuradas!"
puts ""
puts "Acesse /flipper para gerenciar as flags via UI."
