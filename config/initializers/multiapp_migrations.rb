# frozen_string_literal: true

# Configuração de migrations por aplicação (multiapp)
#
# Estrutura de pastas:
#   db/migrate/           -> Migrations compartilhadas (todas as apps)
#   db/migrate_ecoenel/   -> Apenas EcoEnel
#   db/migrate_light/     -> Apenas Light
#   db/migrate_<app>/     -> Apenas App específico
#
# A pasta específica é selecionada via ENV APP_PROFILE:
#   APP_PROFILE=ecoenel  -> db/migrate + db/migrate_ecoenel
#   APP_PROFILE=light    -> db/migrate + db/migrate_light
#
# Uso:
#   # Rodar migrations compartilhadas + específicas do app
#   APP_PROFILE=light rails db:migrate
#
#   # Gerar migration específica para um app
#   APP_PROFILE=ecoenel rails g migration CreateTabelaX --migrations-path=db/migrate_ecoenel
#
Rails.application.config.after_initialize do
  app_profile = ENV.fetch("APP_PROFILE", "default").to_s.downcase

  # Pasta de migrations específica do app
  app_migrations_path = Rails.root.join("db", "migrate_#{app_profile}")

  # Se a pasta específica existir, adiciona ao paths
  if Dir.exist?(app_migrations_path)
    # Adiciona o path específico do app às migrations
    ActiveRecord::Migrator.migrations_paths << app_migrations_path.to_s

    Rails.logger.info "[Multiapp] Migrations paths: #{ActiveRecord::Migrator.migrations_paths.join(', ')}"
  end
end
