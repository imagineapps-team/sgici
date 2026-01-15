# frozen_string_literal: true

namespace :db do
  namespace :migrate do
    desc "Roda migrations compartilhadas + específicas do APP_PROFILE atual"
    task status_all: :environment do
      puts "\n=== Migrations Status (APP_PROFILE=#{ENV.fetch('APP_PROFILE', 'default')}) ===\n\n"

      ActiveRecord::Migrator.migrations_paths.each do |path|
        puts "Path: #{path}"
      end

      puts "\n"
      Rake::Task["db:migrate:status"].invoke
    end
  end

  namespace :multiapp do
    desc "Gera migration para app específico. Uso: rails db:multiapp:generate[app_name,NomeDaMigration]"
    task :generate, [:app, :name] => :environment do |_t, args|
      app = args[:app]
      name = args[:name]

      if app.blank? || name.blank?
        puts "Uso: rails db:multiapp:generate[app_name,NomeDaMigration]"
        puts "Exemplo: rails db:multiapp:generate[ecoenel,CreateTabelaEspecifica]"
        puts ""
        puts "Apps disponíveis:"
        Dir.glob(Rails.root.join("db", "migrate_*")).each do |dir|
          app_name = File.basename(dir).sub("migrate_", "")
          puts "  - #{app_name}"
        end
        exit 1
      end

      migrations_path = Rails.root.join("db", "migrate_#{app}")

      unless Dir.exist?(migrations_path)
        puts "Criando pasta: #{migrations_path}"
        FileUtils.mkdir_p(migrations_path)
      end

      # Gera o timestamp e nome do arquivo
      timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
      filename = "#{timestamp}_#{name.underscore}.rb"
      filepath = migrations_path.join(filename)

      # Template da migration
      class_name = name.camelize
      content = <<~RUBY
        # frozen_string_literal: true

        # Migration específica para: #{app.upcase}
        # Gerada em: #{Time.now}
        class #{class_name} < ActiveRecord::Migration[7.1]
          def up
            # Implementar aqui
          end

          def down
            # Implementar rollback aqui
          end
        end
      RUBY

      File.write(filepath, content)
      puts "Migration criada: #{filepath}"
    end

    desc "Lista todas as migrations por app"
    task list: :environment do
      puts "\n=== Migrations por App ===\n\n"

      # Compartilhadas
      shared_path = Rails.root.join("db", "migrate")
      shared_count = Dir.glob(shared_path.join("*.rb")).count
      puts "📁 Compartilhadas (db/migrate): #{shared_count} migrations"

      # Por app
      Dir.glob(Rails.root.join("db", "migrate_*")).sort.each do |dir|
        app_name = File.basename(dir).sub("migrate_", "")
        count = Dir.glob(File.join(dir, "*.rb")).count
        puts "📁 #{app_name.upcase} (#{File.basename(dir)}): #{count} migrations"
      end

      puts ""
    end

    desc "Cria pasta de migrations para novo app. Uso: rails db:multiapp:create_app[app_name]"
    task :create_app, [:app] => :environment do |_t, args|
      app = args[:app]

      if app.blank?
        puts "Uso: rails db:multiapp:create_app[app_name]"
        puts "Exemplo: rails db:multiapp:create_app[light]"
        exit 1
      end

      migrations_path = Rails.root.join("db", "migrate_#{app}")

      if Dir.exist?(migrations_path)
        puts "Pasta já existe: #{migrations_path}"
      else
        FileUtils.mkdir_p(migrations_path)
        puts "Pasta criada: #{migrations_path}"

        # Cria um README na pasta
        readme_content = <<~MD
          # Migrations específicas: #{app.upcase}

          Esta pasta contém migrations que rodam **apenas** quando `APP_PROFILE=#{app}`.

          ## Como usar

          ```bash
          # Rodar migrations (compartilhadas + #{app})
          APP_PROFILE=#{app} rails db:migrate

          # Gerar nova migration para #{app}
          rails db:multiapp:generate[#{app},NomeDaMigration]
          ```

          ## Quando usar

          - Tabelas que existem APENAS neste app
          - Alterações de schema específicas deste app
          - Seeds/dados específicos deste app

          ## Quando NÃO usar

          - Tabelas compartilhadas entre apps (usar db/migrate/)
          - Features temporárias (usar Flipper)
          - Regras de negócio variáveis (usar Business Policies)
        MD

        File.write(migrations_path.join("README.md"), readme_content)
        puts "README criado: #{migrations_path.join('README.md')}"
      end
    end
  end
end
