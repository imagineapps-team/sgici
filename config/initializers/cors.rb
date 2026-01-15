# frozen_string_literal: true

# Configuração de CORS para permitir requisições da API mobile
# Requer a gem 'rack-cors'
#
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Origens permitidas (configurável via ENV)
    # Em desenvolvimento: permite localhost e 127.0.0.1
    # Em produção: definir CORS_ORIGINS com os domínios do mobile
    origins_list = if Rails.env.development?
                     [
                       'http://localhost:3000', 'http://127.0.0.1:3000',
                       'http://localhost:3001', 'http://127.0.0.1:3001',
                       'http://localhost:3002', 'http://127.0.0.1:3002',
                       'http://localhost:3003', 'http://127.0.0.1:3003',
                       'http://localhost:3004', 'http://127.0.0.1:3004',
                       'http://localhost:8080', 'http://localhost:8081'
                     ]
                   else
                     ENV.fetch('CORS_ORIGINS', '').split(',').map(&:strip)
                   end

    # Adiciona origens dinâmicas para apps mobile (capacitor, expo, etc)
    origins_list += ['capacitor://localhost', 'ionic://localhost', 'http://localhost']

    origins(*origins_list)

    # Recursos da API
    resource '/api/*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             expose: ['Authorization', 'X-Request-Id'],
             max_age: 600,  # Preflight cache de 10 minutos
             credentials: false
  end
end
