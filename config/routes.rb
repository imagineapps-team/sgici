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

  # =====================================================
  # SGICI - Sistema de Gestao de Importacoes
  # =====================================================

  # Processos de Importacao
  resources :processos_importacao do
    member do
      post :aprovar        # planejado -> aprovado
      post :transitar      # aprovado -> em_transito
      post :desembaracar   # em_transito -> desembaracado
      post :finalizar      # desembaracado -> finalizado
      post :cancelar       # qualquer -> cancelado
    end
    collection do
      get :autocomplete_fornecedores
      get :autocomplete_responsaveis
    end

    # Anexos do processo
    resources :anexos, only: [:index, :show, :create, :destroy]

    # Custos Previstos (AJAX endpoints)
    resources :custos_previstos, only: [] do
      collection do
        get :ajax_list
        post :ajax_create
        post :calcular_impostos
        post :gerar_impostos
        get :categorias_disponiveis
      end
      member do
        patch :ajax_update
        delete :ajax_destroy
      end
    end

    # Custos Reais (AJAX endpoints)
    resources :custos_reais, only: [] do
      collection do
        get :ajax_list
        post :ajax_create
        get :categorias_disponiveis
      end
      member do
        patch :ajax_update
        delete :ajax_destroy
        post :registrar_pagamento
      end
    end
  end

  # Custos (standalone)
  resources :custos_previstos
  resources :custos_reais

  # Eventos Logisticos
  resources :eventos_logisticos, only: [:index, :show, :create, :destroy]

  # Ocorrencias
  resources :ocorrencias do
    member do
      post :iniciar_analise
      post :resolver
      post :cancelar
    end

    # Anexos da ocorrencia
    resources :anexos, only: [:index, :show, :create, :destroy]
  end

  # Cadastros SGICI
  resources :fornecedores do
    member do
      get :processos
      get :estatisticas
    end
  end

  resources :prestadores_servico do
    collection do
      get :por_tipo
    end
  end

  resources :categorias_custo

  # =====================================================
  # Rotas legadas (manter para referencia)
  # =====================================================

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

  # Relatórios SGICI
  resources :relatorios, only: [:index] do
    collection do
      get 'processos'
      post 'processos/data', to: 'relatorios#processos_data'
      get 'processos/excel', to: 'relatorios#processos_excel', defaults: { format: :xlsx }
      get 'custos'
      post 'custos/data', to: 'relatorios#custos_data'
      get 'custos/excel', to: 'relatorios#custos_excel', defaults: { format: :xlsx }
      get 'fornecedores'
      post 'fornecedores/data', to: 'relatorios#fornecedores_data'
      get 'fornecedores/excel', to: 'relatorios#fornecedores_excel', defaults: { format: :xlsx }
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
