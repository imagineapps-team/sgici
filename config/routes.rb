require "flipper/ui"

Rails.application.routes.draw do
  # Flipper UI - gerenciamento de feature flags (apenas admins)
  flipper_constraint = lambda { |request|
    # Permite acesso se usuário logado tem perfil admin
    usuario = request.env["warden"]&.user(:usuario)
    usuario&.perfil&.acesso_total?
  }
  constraints(flipper_constraint) do
    mount Flipper::UI.app(Flipper) => "/flipper"
  end

  # =====================================================
  # API Mobile (JWT Authentication)
  # =====================================================
  namespace :api do
    namespace :v1 do
      # Configuração da aplicação (multi-tenant, branding)
      get 'config', to: 'config#show'

      # Autenticação
      post 'auth/login', to: 'auth#login'
      post 'auth/refresh', to: 'auth#refresh'
      get 'auth/me', to: 'auth#me'
      post 'auth/logout', to: 'auth#logout'

      # Eventos
      resources :eventos, only: [:index, :show] do
        member do
          get :participantes
          post :adicionar_participante
          delete :remover_participante
          put :alterar_status
        end
      end

      # Reciclagens
      resources :reciclagens, only: [:index, :show, :create, :update, :destroy] do
        collection do
          get :buscar_clientes
          get :buscar_contratos
        end
      end

      # Lookups (dados para dropdowns)
      namespace :lookups do
        get :eventos
        get :acoes
        get :comunidades
        get :veiculos
        get :recicladores
        get :recursos
        get :status_reciclagem
        get :vigencias_evento_reciclador
      end
    end
  end

  devise_for :usuarios, skip: [:sessions]

  as :usuario do
    get 'login', to: 'usuarios/sessions#new', as: :new_usuario_session
    post 'login', to: 'usuarios/sessions#create', as: :usuario_session
    delete 'logout', to: 'usuarios/sessions#destroy', as: :destroy_usuario_session
  end

  # Redirect to localhost from 127.0.0.1 to use same IP address with Vite server
  constraints(host: "127.0.0.1") do
    get "(*path)", to: redirect { |params, req| "#{req.protocol}localhost:#{req.port}/#{params[:path]}" }
  end
  root 'dashboard#index'

  # Dashboard endpoints (AJAX)
  get 'dashboard/metrics', to: 'dashboard#metrics'
  get 'dashboard/kpis', to: 'dashboard#kpis'
  get 'dashboard/indicadores_ambientais', to: 'dashboard#indicadores_ambientais'
  get 'dashboard/por_categoria', to: 'dashboard#por_categoria'
  get 'dashboard/evolucao', to: 'dashboard#evolucao'

  resources :contratos do
    member do
      delete :remove_cliente
    end
  end

  resources :clientes
  resources :acaos
  resources :tipo_acaos
  resources :eventos do
    member do
      post :add_recurso
      delete :remove_recurso
    end
  end

  resources :instituicaos do
    collection do
      get :cidades_by_uf
      get :bairros_by_cidade
    end
  end

  resources :parceiros do
    collection do
      get :cidades_by_uf
      get :bairros_by_cidade
    end
  end

  resources :recicladors do
    collection do
      get :cidades_by_uf
      get :bairros_by_cidade
    end
  end

  resources :tipo_residuos
  resources :unidade_medidas
  resources :residuos

  resources :bairros do
    collection do
      get :cidades_by_uf
    end
  end

  resources :comunidades do
    collection do
      get :cidades_by_uf
      get :bairros_by_cidade
    end
  end

  resources :campanhas
  resources :veiculos

  # === MÓDULOS LIGHT / ECOENEL ===

  # Emissão de Recibos
  resources :recibos, only: [:index] do
    collection do
      post :data                  # AJAX: DataTable server-side
      post :enviar_individual     # Envia recibo para uma reciclagem
      post :enviar_lote           # Envia recibos em lote para parceiro
      get :eventos_por_contrato   # AJAX: Eventos de um contrato
    end
  end

  resources :reciclagens do
    collection do
      get :participantes           # AJAX: Lista participantes de um evento (DataTable)
      post :adicionar_participante # AJAX: Adiciona participante ao evento
      delete :remover_participante # AJAX: Remove participante do evento
      post :alterar_status_evento  # AJAX: Abre/fecha evento
      get :buscar_clientes         # AJAX: Autocomplete clientes
      get :buscar_contratos        # AJAX: Autocomplete contratos
      get :buscar_contratos_doacao # AJAX: Autocomplete contratos para doacao
    end
  end

  resources :usuarios
  resources :permissoes_menu, only: [:index, :edit, :update]

  # Relatórios
  resources :relatorios, only: [:index] do
    collection do
      # Histórico por Ação
      get 'historico_eventos', to: 'relatorios#historico_eventos'
      post 'historico_eventos/data', to: 'relatorios#historico_eventos_data'
      get 'historico_eventos/excel', to: 'relatorios#historico_eventos_excel'
      get 'historico_eventos/pdf', to: 'relatorios#historico_eventos_pdf'

      # Histórico por Participação
      get 'historico_participacao', to: 'relatorios#historico_participacao'
      post 'historico_participacao/data', to: 'relatorios#historico_participacao_data'
      get 'historico_participacao/excel', to: 'relatorios#historico_participacao_excel'
      get 'historico_participacao/pdf', to: 'relatorios#historico_participacao_pdf'

      # Histórico de Resíduos
      get 'historico_residuos', to: 'relatorios#historico_residuos'
      post 'historico_residuos/data', to: 'relatorios#historico_residuos_data'
      get 'historico_residuos/excel', to: 'relatorios#historico_residuos_excel'
      get 'historico_residuos/pdf', to: 'relatorios#historico_residuos_pdf'

      # Histórico Reciclador por Evento
      get 'historico_reciclador_evento', to: 'relatorios#historico_reciclador_evento'
      post 'historico_reciclador_evento/data', to: 'relatorios#historico_reciclador_evento_data'
      get 'historico_reciclador_evento/excel', to: 'relatorios#historico_reciclador_evento_excel'
      get 'historico_reciclador_evento/pdf', to: 'relatorios#historico_reciclador_evento_pdf'

      # Fatura do Reciclador
      get 'historico_fatura_reciclador', to: 'relatorios#historico_fatura_reciclador'
      post 'historico_fatura_reciclador/data', to: 'relatorios#historico_fatura_reciclador_data'
      get 'historico_fatura_reciclador/excel', to: 'relatorios#historico_fatura_reciclador_excel'
      get 'historico_fatura_reciclador/pdf', to: 'relatorios#historico_fatura_reciclador_pdf'

      # Campanhas
      get 'campanhas', to: 'relatorios#campanhas', as: :relatorio_campanhas
      post 'campanhas/data', to: 'relatorios#campanhas_data'
      get 'campanhas/excel', to: 'relatorios#campanhas_excel'
      get 'campanhas/pdf', to: 'relatorios#campanhas_pdf'

      # Veiculos
      get 'veiculos', to: 'relatorios#veiculos', as: :relatorio_veiculos
      post 'veiculos/data', to: 'relatorios#veiculos_data'
      get 'veiculos/excel', to: 'relatorios#veiculos_excel'
      get 'veiculos/pdf', to: 'relatorios#veiculos_pdf'
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
