# SGICI - Requisitos Técnicos

## Stack Tecnológico

| Camada | Tecnologia | Versão |
|--------|------------|--------|
| Backend | Ruby on Rails | 8.1.1 |
| Frontend | Vue.js | 3.5.25 |
| SSR Framework | Inertia.js | 2.3.1 |
| Linguagem Frontend | TypeScript | 5.6.2 |
| Framework CSS | Tailwind CSS | 4.1.18 |
| Database | PostgreSQL | 12+ |
| Cache | Solid Cache (ActiveRecord) | Rails 8 |
| Queue | Solid Queue (ActiveRecord) | Rails 8 |
| Cable | Solid Cable (ActionCable) | Rails 8 |
| Web Server | Puma | 5.0+ |
| Assets | Vite | 7.3.0 |
| Autenticação | Devise | - |
| Autorização | Pundit | - |
| Feature Flags | Flipper | - |
| Excel Export | caxlsx / caxlsx_rails | - |
| PDF Export | grover (Chrome headless) | - |
| Emails | AWS SES | - |
| SMS | Zenvia | - |
| Deploy | Kamal | - |

---

## RT001 - Arquitetura Geral

### Diagrama de Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                      FRONTEND                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Web Browser │  │  Mobile App  │  │   Admin Web  │      │
│  │  (Vue/TS)    │  │  (API JWT)   │  │  (Vue/TS)    │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │ Inertia.js       │ REST API         │ Inertia.js
          │                  │ (JWT Auth)       │
          └──────────────────┼──────────────────┘
                             │ HTTPS
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      BACKEND                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Kamal / Docker / Puma                   │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Rails 8 Application                        │  │
│  │                                                       │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐    │  │
│  │  │Controllers │  │  Services  │  │  Policies  │    │  │
│  │  └──────┬─────┘  └──────┬─────┘  └──────┬─────┘    │  │
│  │         │                │                │          │  │
│  │  ┌──────▼───────────────▼────────────────▼─────┐   │  │
│  │  │            Models (ActiveRecord)           │   │  │
│  │  └────────────────────┬───────────────────────┘   │  │
│  └───────────────────────┼───────────────────────────┘  │
└────────────────────────┼─────────────────────────────────┘
                         │
┌────────────────────────┼─────────────────────────────────┐
│                    DATA LAYER                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │PostgreSQL│  │  Solid   │  │  Solid   │  │   AWS   │ │
│  │ (primary)│  │  Cache   │  │  Queue   │  │   SES   │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  Shard   │  │  Shard   │  │  Active  │              │
│  │(ecoenel  │  │(ecoenel  │  │ Storage  │              │
│  │   _sp)   │  │   _ce)   │  │  (S3?)   │              │
│  └──────────┘  └──────────┘  └──────────┘              │
└─────────────────────────────────────────────────────────┘
```

### Descrição dos Componentes

| Componente | Responsabilidade | Tecnologia |
|------------|------------------|------------|
| Web Browser | Interface web principal | Vue 3 + Inertia.js |
| Mobile App | Aplicativo mobile | REST API + JWT |
| Admin Web | Painel administrativo | Vue 3 + Inertia.js |
| Kamal/Docker | Orquestração de containers | Kamal 2.x |
| Puma | Web server | Puma 5+ |
| Controllers | Endpoints e roteamento | Rails Controllers |
| Services | Lógica de negócio complexa | Service Objects |
| Policies | Autorização | Pundit |
| Models | Camada de dados | ActiveRecord |
| PostgreSQL | Banco de dados principal | PostgreSQL 12+ |
| Solid Cache | Cache de dados | ActiveRecord |
| Solid Queue | Fila de jobs | ActiveRecord |
| AWS SES | Envio de emails | AWS SDK |
| Zenvia | Envio de SMS | HTTP API |

---

## RT002 - Multi-Tenancy

### Descrição
O sistema suporta dois modos de operação:
- **Single-tenant**: Uma aplicação por banco (ex: Light)
- **Multi-tenant**: Múltiplos bancos por aplicação (ex: EcoEnel SP + CE)

### Arquitetura Multi-Tenant

```
┌───────────────────────────────────────┐
│       Login (EcoEnel)                 │
│  ┌─────────────────────────────────┐ │
│  │  Regional: [São Paulo     ▼]    │ │
│  │  Login:    [______________]     │ │
│  │  Senha:    [______________]     │ │
│  └─────────────────────────────────┘ │
└───────────────────────────────────────┘
                  │
                  ▼
┌───────────────────────────────────────┐
│    Middleware: TenantSwitchable       │
│  session[:tenant] = 'ecoenel_sp'      │
└───────────────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        ▼                   ▼
┌──────────────┐    ┌──────────────┐
│  ecoenel_sp  │    │  ecoenel_ce  │
│   (banco)    │    │   (banco)    │
└──────────────┘    └──────────────┘
```

### Configuração

**ENV para Multi-Tenant (EcoEnel)**:
```env
MULTI_TENANT_ENABLED=true
DATABASE_NAME_SP=ecoenel
DATABASE_NAME_CE=ecoenel_ce
```

**ENV para Single-Tenant (Light)**:
```env
# MULTI_TENANT_ENABLED não definida
DATABASE_NAME=lightrecicla
```

### Implementação

**database.yml**:
```yaml
development:
  primary:
    <<: *default
    database: <%= ENV.fetch("DATABASE_NAME", "ecoenel") %>
<% if ENV["MULTI_TENANT_ENABLED"] == "true" %>
  ecoenel_sp:
    <<: *default
    database: <%= ENV.fetch("DATABASE_NAME_SP", "ecoenel") %>
  ecoenel_ce:
    <<: *default
    database: <%= ENV.fetch("DATABASE_NAME_CE", "ecoenel_ce") %>
<% end %>
```

**application_record.rb**:
```ruby
class ApplicationRecord < ActiveRecord::Base
  if ENV["MULTI_TENANT_ENABLED"] == "true"
    connects_to shards: {
      ecoenel_sp: { writing: :ecoenel_sp },
      ecoenel_ce: { writing: :ecoenel_ce }
    }
  end
end
```

**Middleware (TenantSwitchable)**:
```ruby
def switch_to_tenant
  return unless multi_tenant_enabled?
  tenant = session[:tenant]
  ActiveRecord::Base.connected_to(shard: tenant.to_sym) do
    yield
  end
end
```

### Adicionando Nova Regional

1. Adicionar shard no `database.yml`
2. Adicionar no `ApplicationRecord#connects_to`
3. Adicionar em `TenantSwitchable::VALID_TENANTS`
4. Configurar ENV `DATABASE_NAME_XX`

---

## RT003 - Padrão de Projeto: MVC + Service Layer

### Descrição
Arquitetura em camadas com separação clara de responsabilidades.

### Estrutura
```
app/
├── controllers/          # Endpoints e coordenação
│   ├── application_controller.rb
│   ├── contratos_controller.rb
│   ├── eventos_controller.rb
│   └── api/
│       └── v1/
│           └── eventos_controller.rb
├── models/              # Entidades e relacionamentos
│   ├── application_record.rb
│   ├── contrato.rb
│   ├── evento.rb
│   └── concerns/
│       └── tenant_switchable.rb
├── services/            # Lógica de negócio complexa
│   ├── service_result.rb
│   ├── branding.rb
│   ├── recibos/
│   │   └── envio_recibo_service.rb
│   └── messaging/
│       ├── messenger.rb
│       └── email/
│           └── aws_ses_adapter.rb
├── policies/            # Autorização (Pundit)
│   ├── application_policy.rb
│   └── business/
│       └── base_policy.rb
└── javascript/vue/      # Frontend (Inertia)
    ├── pages/
    ├── components/
    └── composables/
```

### Fluxo de Request (Web - Inertia.js)
```
Request (Browser)
    ↓
Controller
    ↓
Authorize (Pundit Policy)
    ↓
Service (se lógica complexa)
    ↓
Model (ActiveRecord)
    ↓
Database
    ↓
render inertia: 'pages/Entity', props: { ... }
    ↓
Vue Component
    ↓
Response (SPA-like)
```

### Fluxo de Request (API - JWT)
```
Request (Mobile)
    ↓
API::V1::BaseController
    ↓
JWT Authentication
    ↓
Authorize (Pundit Policy)
    ↓
Service
    ↓
Model
    ↓
Database
    ↓
JSON Response
```

### Exemplo de Código

**Controller**:
```ruby
class EventosController < ApplicationController
  before_action :authenticate_usuario!

  def index
    @eventos = Evento.includes(:acao, :comunidade).order(data: :desc)
    authorize @eventos

    render inertia: 'eventos/EventosIndex', props: {
      eventos: @eventos.map { |e| evento_as_json(e) },
      usuario: usuario_info
    }
  end

  def create
    @evento = Evento.new(evento_params)
    authorize @evento

    if @evento.save
      redirect_to eventos_path, notice: 'Evento criado com sucesso'
    else
      render inertia: 'eventos/EventosForm', props: {
        evento: @evento.as_json,
        errors: @evento.errors.full_messages
      }
    end
  end
end
```

**Service**:
```ruby
module Recibos
  class EnvioReciboService
    def initialize(reciclagem)
      @reciclagem = reciclagem
    end

    def execute
      return ServiceResult.failure('Parceiro não possui email') if parceiro.email.blank?

      pdf = gerar_pdf
      enviar_email(pdf)

      ServiceResult.success('Recibo enviado com sucesso')
    rescue => e
      ServiceResult.failure("Erro ao enviar recibo: #{e.message}")
    end
  end
end
```

**Policy**:
```ruby
class EventoPolicy < ApplicationPolicy
  def index?
    true # todos logados podem listar
  end

  def create?
    usuario.perfil.pode_criar_eventos?
  end

  def update?
    usuario.perfil.acesso_total? || record.criador_id == usuario.id
  end
end
```

---

## RT004 - Autenticação e Autorização

### Autenticação Web (Devise)

**Tipo**: Session-based com Devise

**Fluxo**:
```mermaid
sequenceDiagram
    participant U as User
    participant L as Login Page
    participant D as Devise
    participant S as Session
    participant A as App

    U->>L: GET /login
    L-->>U: Formulário de login
    U->>D: POST /login (email, senha, regional?)
    D->>D: Valida credenciais
    D->>S: Cria sessão
    S-->>U: Cookie de sessão
    U->>A: GET /dashboard (com cookie)
    A->>S: Valida sessão
    A-->>U: Dashboard
```

**Configuração**:
```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.mailer_sender = ENV.fetch('MAILER_FROM', 'noreply@avsi.com')
  config.authentication_keys = [:email]
  config.timeout_in = 30.minutes
end
```

### Autenticação API (JWT)

**Tipo**: Token JWT (JSON Web Token)

**Fluxo**:
```mermaid
sequenceDiagram
    participant M as Mobile
    participant A as API Auth
    participant D as Database
    participant R as Resource

    M->>A: POST /api/v1/auth/login (email, senha)
    A->>D: Valida credenciais
    A->>A: Gera JWT
    A-->>M: { access_token, refresh_token, expires_in }

    M->>R: GET /api/v1/eventos (Bearer token)
    R->>R: Valida JWT
    R->>D: Busca dados
    R-->>M: { data: [...] }
```

**Endpoints API**:
```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    post 'auth/login', to: 'auth#login'
    post 'auth/refresh', to: 'auth#refresh'
    get 'auth/me', to: 'auth#me'
    post 'auth/logout', to: 'auth#logout'

    resources :eventos, only: [:index, :show]
    resources :reciclagens
  end
end
```

**Token Payload**:
```json
{
  "user_id": 123,
  "email": "usuario@example.com",
  "tenant": "ecoenel_sp",
  "exp": 1735689600,
  "iat": 1735603200
}
```

### Autorização (Pundit)

**Convenção**: 1 Policy por Model

**Exemplo**:
```ruby
# app/policies/evento_policy.rb
class EventoPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    usuario.perfil.pode_criar_eventos?
  end

  def update?
    usuario.perfil.acesso_total? ||
      usuario.id == record.criador_id
  end

  def destroy?
    usuario.perfil.acesso_total?
  end
end
```

**Uso no Controller**:
```ruby
def create
  @evento = Evento.new(evento_params)
  authorize @evento  # levanta Pundit::NotAuthorizedError se falhar
  # ...
end
```

---

## RT005 - Banco de Dados

### Schema Principal

**Entidades Core**:
```sql
-- Usuários e Perfis
usuarios (id, email, nome, perfil_id, status)
perfis (id, nome, acesso_total)

-- Clientes e Contratos
clientes (id, nome, cpf, email, telefone, celular)
contratos (id, numero, nomeTitular, cliente_id, contrato_tipo_id, status)
contratos_tipos (id, nome, status)

-- Localização
ufs (id, nome, sigla)
cidades (id, nome, uf_id)
bairros (id, nome, cidade_id)
comunidades (id, nome, logradouro, latitude, longitude, parceiro_id)

-- Eventos e Ações
acaos (id, nome, projeto_id, tipo_acao_id)
tipo_acaos (id, nome)
projetos (id, nome)
eventos (id, data, acao_id, comunidade_id, status)

-- Reciclagem
reciclagens (id, evento_id, contrato_id, cliente_id, data, status)
reciclagem_recursos (id, reciclagem_id, recurso_id, quantidade, valor_unitario)
recursos (id, nome, tipo_recurso_id, unidade_medida_id)
tipo_residuos (id, nome)
unidade_medidas (id, nome, sigla)

-- Parceiros e Recicladores
parceiros (id, nome, tipo_id, cpf_cnpj, email, telefone)
parceiro_tipos (id, nome)
recicladors (id, nome, cpf_cnpj, email, telefone)

-- Índices Ambientais
indices_ambientais (id, nome, formula, unidade)
```

### Índices Críticos

```sql
-- Performance
CREATE INDEX idx_contratos_numero ON contratos(numero);
CREATE INDEX idx_contratos_cliente_id ON contratos(cliente_id);
CREATE INDEX idx_eventos_data ON eventos(data);
CREATE INDEX idx_eventos_status ON eventos(status);
CREATE INDEX idx_reciclagens_evento_id ON reciclagens(evento_id);
CREATE INDEX idx_reciclagens_contrato_id ON reciclagens(contrato_id);
CREATE INDEX idx_reciclagens_data ON reciclagens(data);
CREATE INDEX idx_clientes_cpf ON clientes(cpf);

-- Multi-tenancy (se aplicável)
CREATE INDEX idx_eventos_tenant ON eventos(tenant_id);
```

### Constraints

```sql
-- Unicidade
ALTER TABLE contratos ADD CONSTRAINT unique_contrato_numero UNIQUE (numero);
ALTER TABLE clientes ADD CONSTRAINT unique_cliente_cpf UNIQUE (cpf);
ALTER TABLE comunidades ADD CONSTRAINT comunidades_nome_key UNIQUE (nome);

-- Integridade referencial
ALTER TABLE contratos ADD CONSTRAINT fk_contrato_cliente
  FOREIGN KEY (cliente_id) REFERENCES clientes(id);

ALTER TABLE eventos ADD CONSTRAINT fk_evento_acao
  FOREIGN KEY (acao_id) REFERENCES acaos(id);

ALTER TABLE reciclagens ADD CONSTRAINT fk_reciclagem_evento
  FOREIGN KEY (evento_id) REFERENCES eventos(id);
```

### Migrations

**Localização**: `db/migrate/`
**Formato**: PostgreSQL SQL (structure.sql)

**Convenção**:
```ruby
# config/application.rb
config.active_record.schema_format = :sql
```

**Comandos**:
```bash
# Criar migration
bin/rails g migration AddCampoToTable campo:tipo

# Rodar migrations
bin/rails db:migrate

# Rollback
bin/rails db:rollback

# Reset (dev only)
bin/rails db:reset
```

---

## RT006 - API REST

### Convenções

| Método | Rota | Ação | Autenticação |
|--------|------|------|--------------|
| GET | /api/v1/recursos | Listar | JWT |
| GET | /api/v1/recursos/:id | Detalhar | JWT |
| POST | /api/v1/recursos | Criar | JWT |
| PUT | /api/v1/recursos/:id | Atualizar | JWT |
| DELETE | /api/v1/recursos/:id | Excluir | JWT |

### Formato de Resposta

**Sucesso (Lista)**:
```json
{
  "data": [
    {
      "id": 1,
      "nome": "Evento X",
      "data": "2025-01-15",
      "status": "aberto"
    }
  ],
  "meta": {
    "total": 100,
    "per_page": 20,
    "current_page": 1,
    "total_pages": 5
  }
}
```

**Sucesso (Item)**:
```json
{
  "data": {
    "id": 1,
    "nome": "Evento X",
    "data": "2025-01-15",
    "acao": {
      "id": 5,
      "nome": "Coleta Seletiva"
    }
  }
}
```

**Erro (Validação)**:
```json
{
  "error": "Validation failed",
  "messages": {
    "nome": ["não pode ficar em branco"],
    "data": ["é inválida"]
  }
}
```

**Erro (Autorização)**:
```json
{
  "error": "Unauthorized",
  "message": "Token inválido ou expirado"
}
```

### Códigos de Status

| Código | Significado | Uso |
|--------|-------------|-----|
| 200 | OK | Sucesso (GET, PUT, DELETE) |
| 201 | Created | Recurso criado (POST) |
| 204 | No Content | Sucesso sem retorno (DELETE) |
| 400 | Bad Request | Parâmetros inválidos |
| 401 | Unauthorized | Não autenticado |
| 403 | Forbidden | Não autorizado |
| 404 | Not Found | Recurso não encontrado |
| 422 | Unprocessable Entity | Validação falhou |
| 500 | Internal Server Error | Erro no servidor |

### Headers Obrigatórios (Request)

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
Accept: application/json
```

### Headers Padrão (Response)

```http
Content-Type: application/json; charset=utf-8
X-Request-Id: 3c8a7b2f-9d4e-4a1c-8f6b-2e3d4c5f6a7b
```

### Endpoints Disponíveis

**Autenticação**:
```
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
GET    /api/v1/auth/me
POST   /api/v1/auth/logout
```

**Configuração**:
```
GET    /api/v1/config
```

**Eventos**:
```
GET    /api/v1/eventos
GET    /api/v1/eventos/:id
GET    /api/v1/eventos/:id/participantes
POST   /api/v1/eventos/:id/adicionar_participante
DELETE /api/v1/eventos/:id/remover_participante
PUT    /api/v1/eventos/:id/alterar_status
```

**Reciclagens**:
```
GET    /api/v1/reciclagens
GET    /api/v1/reciclagens/:id
POST   /api/v1/reciclagens
PUT    /api/v1/reciclagens/:id
DELETE /api/v1/reciclagens/:id
GET    /api/v1/reciclagens/buscar_clientes
GET    /api/v1/reciclagens/buscar_contratos
```

**Lookups (Dropdowns)**:
```
GET    /api/v1/lookups/eventos
GET    /api/v1/lookups/acoes
GET    /api/v1/lookups/comunidades
GET    /api/v1/lookups/veiculos
GET    /api/v1/lookups/recicladores
GET    /api/v1/lookups/recursos
GET    /api/v1/lookups/status_reciclagem
GET    /api/v1/lookups/vigencias_evento_reciclador
```

---

## RT007 - Segurança

### Headers Obrigatórios

**Configuração (production.rb)**:
```ruby
config.force_ssl = true
config.assume_ssl = true

# Security headers
config.action_dispatch.default_headers = {
  'X-Frame-Options' => 'DENY',
  'X-Content-Type-Options' => 'nosniff',
  'X-XSS-Protection' => '1; mode=block',
  'Referrer-Policy' => 'strict-origin-when-cross-origin'
}
```

### CORS (API Mobile)

**Configuração (cors.rb)**:
```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('ALLOWED_ORIGINS', 'localhost:3000').split(',')

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options],
      credentials: true,
      max_age: 3600
  end
end
```

### Validação de Entrada

**Strong Parameters**:
```ruby
def evento_params
  params.require(:evento).permit(
    :data, :acao_id, :comunidade_id, :status, :observacoes
  )
end
```

**Sanitização de HTML**:
```ruby
# Automático via Rails (ActionView::Helpers::SanitizeHelper)
<%= sanitize @evento.observacoes %>
```

**SQL Injection Protection**:
```ruby
# SEMPRE usar placeholders (?)
Evento.where('data >= ?', params[:data_inicial])

# NUNCA interpolar diretamente
Evento.where("data >= '#{params[:data_inicial]}'")  # ❌ PERIGOSO
```

### Senhas

**Algoritmo**: bcrypt (via Devise)
**Custo**: 12 rounds (padrão Devise)

**Política**:
```ruby
# config/initializers/devise.rb
config.password_length = 8..128
config.pepper = ENV['DEVISE_PEPPER']
```

### CSRF Protection

**Automático para formulários**:
```ruby
# application_controller.rb
protect_from_forgery with: :exception
```

**Token para AJAX**:
```typescript
// app/javascript/vue/lib/axios.ts
axios.defaults.headers.common['X-CSRF-Token'] =
  document.querySelector('meta[name="csrf-token"]')?.content
```

### Auditoria

**Histórico de Alterações**:
```sql
CREATE TABLE historicos (
  id serial PRIMARY KEY,
  usuario_id integer NOT NULL,
  model varchar(50) NOT NULL,
  registro_id integer NOT NULL,
  acao varchar(20) NOT NULL,  -- 'CREATE', 'UPDATE', 'DELETE'
  alteracoes jsonb,
  ip_address varchar(45),
  user_agent text,
  created_at timestamp DEFAULT now()
);
```

**Logs de Autenticação**:
```ruby
# Devise traceable
add_column :usuarios, :sign_in_count, :integer, default: 0
add_column :usuarios, :current_sign_in_at, :datetime
add_column :usuarios, :last_sign_in_at, :datetime
add_column :usuarios, :current_sign_in_ip, :string
add_column :usuarios, :last_sign_in_ip, :string
```

---

## RT008 - Performance e Cache

### Cache Strategy

| Dado | Estratégia | TTL | Storage |
|------|-----------|-----|---------|
| Configurações | Cache | 24h | Solid Cache |
| Lookups (dropdowns) | Cache | 1h | Solid Cache |
| Queries complexas | Cache | 30min | Solid Cache |
| Fragment caching | Cache | Varia | Solid Cache |

### Solid Cache (Rails 8)

**Configuração**:
```ruby
# config/environments/production.rb
config.cache_store = :solid_cache_store
```

**Uso**:
```ruby
# Cache de query
@acoes = Rails.cache.fetch('acoes/all', expires_in: 1.hour) do
  Acao.all.order(:nome).to_a
end

# Fragment cache (view)
<% cache @evento do %>
  <%= render @evento %>
<% end %>
```

### Otimizações de Query

**Eager Loading**:
```ruby
# ✅ BOM - 2 queries
@eventos = Evento.includes(:acao, :comunidade)

# ❌ RUIM - N+1 queries
@eventos = Evento.all
@eventos.each { |e| puts e.acao.nome }  # query por evento
```

**Select Específico**:
```ruby
# Apenas campos necessários
Evento.select(:id, :data, :status)
```

**Batch Processing**:
```ruby
# Para grandes volumes
Evento.find_each(batch_size: 1000) do |evento|
  # processar
end
```

### Paginação

**Biblioteca**: kaminari ou pagy (adicionar ao Gemfile)

**Exemplo**:
```ruby
@eventos = Evento.page(params[:page]).per(20)
```

### Database Pooling

**Configuração**:
```yaml
# config/database.yml
production:
  pool: <%= ENV.fetch("RAILS_MAX_THREADS", 5) %>
```

### Background Jobs (Solid Queue)

**Uso**:
```ruby
# app/jobs/envio_recibo_job.rb
class EnvioReciboJob < ApplicationJob
  queue_as :default

  def perform(reciclagem_id)
    reciclagem = Reciclagem.find(reciclagem_id)
    Recibos::EnvioReciboService.new(reciclagem).execute
  end
end

# Enfileirar
EnvioReciboJob.perform_later(reciclagem.id)
```

---

## RT009 - Frontend (Vue + Inertia.js)

### Arquitetura

```
app/javascript/
├── entrypoints/
│   └── application.ts       # Entry point Vite
├── vue/
│   ├── pages/               # Páginas Inertia (CamelCase)
│   │   ├── dashboard/
│   │   │   └── DashboardIndex.vue
│   │   ├── contratos/
│   │   │   ├── ContratosIndex.vue
│   │   │   └── ContratosForm.vue
│   │   └── eventos/
│   │       ├── EventosIndex.vue
│   │       └── EventosForm.vue
│   ├── components/          # Componentes reutilizáveis
│   │   ├── IInput/
│   │   ├── ISelect/
│   │   ├── IModal/
│   │   ├── DataTable/
│   │   └── ConfirmationModal/
│   ├── composables/         # Composables Vue
│   │   ├── useBranding.ts
│   │   ├── useNotifications.ts
│   │   └── useLoading.ts
│   ├── layouts/             # Layouts
│   │   └── AppLayout.vue
│   ├── lib/                 # Bibliotecas
│   │   └── axios.ts
│   ├── utils/               # Utilitários
│   │   ├── formatCpf.ts
│   │   ├── formatDate.ts
│   │   └── formatMoney.ts
│   └── types/               # Types TypeScript
│       └── index.ts
```

### Comunicação Backend ↔ Frontend

**Inertia.js (Web)**:
```ruby
# Controller
render inertia: 'eventos/EventosIndex', props: {
  eventos: @eventos.map { |e| evento_as_json(e) },
  usuario: usuario_info
}
```

```vue
<!-- Vue Component -->
<script setup lang="ts">
interface Props {
  eventos: Evento[]
  usuario: Usuario
}
const props = defineProps<Props>()
</script>
```

**Axios (AJAX dentro do Inertia)**:
```typescript
import api from '../../lib/axios'

const response = await api.post('/eventos/1/add_recurso', {
  reciclador_id: 1,
  vigencia_id: 2
})
```

### Componentes Principais

**IInput** - Input com formatação:
```vue
<IInput
  v-model="form.nome"
  label="Nome"
  required
  :error="errors.nome"
/>

<IInput
  v-model="form.cpf"
  type="cpf_cnpj"
  label="CPF/CNPJ"
/>
```

**ISelect** - Select com pesquisa:
```vue
<ISelect
  v-model="form.acao_id"
  label="Ação"
  :options="acaoOptions"
  searchable
  required
/>
```

**DataTable** - Tabela com filtros:
```vue
<DataTable
  :data="eventos"
  :columns="columns"
  :default-actions="{ edit: true, delete: true }"
  @edit="handleEdit"
  @delete="handleDelete"
/>
```

### Composables

**useBranding** - Acesso a branding:
```typescript
const { appName, primaryColor, logoUrl } = useBranding()
```

**useNotifications** - Toasts:
```typescript
const { success, error } = useNotifications()
success('Salvo com sucesso!')
```

**useLoading** - Loading global:
```typescript
const { show, hide } = useLoading()
show('Processando...')
// ...
hide()
```

### Build e Deploy

**Desenvolvimento**:
```bash
bin/dev  # Roda Rails + Vite simultaneamente
```

**Produção**:
```bash
# Build assets
npm run build

# Assets são servidos via Propshaft
```

---

## RT010 - Feature Flags (Flipper)

### Descrição
Sistema de feature toggles para habilitar/desabilitar funcionalidades sem deploy.

### Interface Web

**URL**: `/flipper` (apenas admins)

**Configuração**:
```ruby
# config/routes.rb
flipper_constraint = lambda { |request|
  usuario = request.env["warden"]&.user(:usuario)
  usuario&.perfil&.acesso_total?
}

constraints(flipper_constraint) do
  mount Flipper::UI.app(Flipper) => "/flipper"
end
```

### Uso no Código

**Controller**:
```ruby
def create
  if Flipper.enabled?(:nova_feature)
    # novo código
  else
    # código antigo
  end
end
```

**View**:
```ruby
<% if Flipper.enabled?(:mostrar_banner) %>
  <%= render 'shared/banner' %>
<% end %>
```

**Por Usuário**:
```ruby
Flipper.enable_actor(:recurso_x, current_usuario)
Flipper.enabled?(:recurso_x, current_usuario)
```

**Por Percentual**:
```ruby
# Habilitar para 25% dos usuários
Flipper.enable_percentage_of_actors(:nova_interface, 25)
```

### Storage

**Banco de Dados (ActiveRecord)**:
```ruby
# config/initializers/flipper.rb
Flipper.configure do |config|
  config.default do
    Flipper.new(Flipper::Adapters::ActiveRecord.new)
  end
end
```

### Tabelas
```sql
flipper_features (id, key, created_at, updated_at)
flipper_gates (id, feature_key, key, value, created_at, updated_at)
```

---

## RT011 - Relatórios

### Formatos Suportados

| Formato | Biblioteca | Uso |
|---------|-----------|-----|
| Excel (.xlsx) | caxlsx | Exportação de tabelas |
| PDF | grover (Chrome headless) | Relatórios formatados |
| CSV | Ruby CSV | Exportação simples |

### Excel (caxlsx)

**Template**:
```ruby
# app/views/relatorios/historico_eventos.xlsx.axlsx
wb = xlsx_package.workbook
wb.add_worksheet(name: "Histórico de Eventos") do |sheet|
  # Header
  sheet.add_row ['Data', 'Ação', 'Local', 'Participantes']

  # Dados
  @eventos.each do |evento|
    sheet.add_row [
      evento.data.strftime('%d/%m/%Y'),
      evento.acao.nome,
      evento.comunidade.nome,
      evento.participantes.count
    ]
  end
end
```

**Controller**:
```ruby
def historico_eventos_excel
  @eventos = Evento.includes(:acao, :comunidade)

  respond_to do |format|
    format.xlsx { render xlsx: 'historico_eventos' }
  end
end
```

### PDF (grover)

**HTML Template**:
```erb
<!-- app/views/relatorios/historico_eventos_pdf.html.erb -->
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial; }
    table { width: 100%; border-collapse: collapse; }
    th, td { border: 1px solid #ddd; padding: 8px; }
  </style>
</head>
<body>
  <h1>Histórico de Eventos</h1>
  <table>
    <thead>
      <tr>
        <th>Data</th>
        <th>Ação</th>
        <th>Local</th>
      </tr>
    </thead>
    <tbody>
      <% @eventos.each do |evento| %>
        <tr>
          <td><%= evento.data.strftime('%d/%m/%Y') %></td>
          <td><%= evento.acao.nome %></td>
          <td><%= evento.comunidade.nome %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</body>
</html>
```

**Controller**:
```ruby
def historico_eventos_pdf
  @eventos = Evento.includes(:acao, :comunidade)

  html = render_to_string(
    template: 'relatorios/historico_eventos_pdf',
    layout: false
  )

  pdf = Grover.new(html).to_pdf

  send_data pdf,
    filename: "historico_eventos_#{Date.today}.pdf",
    type: 'application/pdf',
    disposition: 'attachment'
end
```

### Endpoints de Relatórios

```
GET  /relatorios/historico_eventos
POST /relatorios/historico_eventos/data          # DataTable AJAX
GET  /relatorios/historico_eventos/excel
GET  /relatorios/historico_eventos/pdf

GET  /relatorios/historico_participacao
GET  /relatorios/historico_participacao/excel
GET  /relatorios/historico_participacao/pdf

GET  /relatorios/historico_residuos
GET  /relatorios/historico_residuos/excel
GET  /relatorios/historico_residuos/pdf
```

---

## RT012 - Branding Multi-App

### Descrição
Sistema de customização visual por aplicação (cores, logos, nome).

### Configuração via ENV

```env
# EcoEnel
APP_NAME=AVSI EcoEnel
PRIMARY_COLOR=#006cb6
SECONDARY_COLOR=#10B981
ACCENT_COLOR=#F59E0B
LOGO_URL=/images/logo-ecoenel.png

# Light
APP_NAME=AVSI Light Recicla
PRIMARY_COLOR=#008275
SECONDARY_COLOR=#34D399
ACCENT_COLOR=#FBBF24
LOGO_URL=/images/logo-light.png
```

### Backend (Service)

```ruby
# app/services/branding.rb
class Branding
  def self.config
    {
      app_name: ENV.fetch('APP_NAME', 'AVSI'),
      primary_color: ENV.fetch('PRIMARY_COLOR', '#006cb6'),
      secondary_color: ENV.fetch('SECONDARY_COLOR', '#10B981'),
      accent_color: ENV.fetch('ACCENT_COLOR', '#F59E0B'),
      logo_url: ENV.fetch('LOGO_URL', '/images/logo.png'),
      footer_text: ENV.fetch('FOOTER_TEXT', '© 2025 AVSI')
    }
  end
end
```

**Controller (Inertia)**:
```ruby
def inertia_share
  super.merge(
    branding: Branding.config
  )
end
```

### Frontend (Vue)

**Composable**:
```typescript
// app/javascript/vue/composables/useBranding.ts
import { computed } from 'vue'
import { usePage } from '@inertiajs/vue3'

export function useBranding() {
  const page = usePage()
  const branding = computed(() => page.props.branding)

  return {
    branding,
    appName: computed(() => branding.value.app_name),
    primaryColor: computed(() => branding.value.primary_color),
    logoUrl: computed(() => branding.value.logo_url)
  }
}
```

**Uso**:
```vue
<template>
  <header class="bg-brand-primary">
    <img :src="logoUrl" :alt="appName" />
    <h1>{{ appName }}</h1>
  </header>
</template>

<script setup lang="ts">
import { useBranding } from '../../composables/useBranding'
const { appName, logoUrl } = useBranding()
</script>
```

**Classes CSS**:
```css
/* Geradas dinamicamente via CSS variables */
.bg-brand-primary { background-color: var(--color-brand-primary); }
.text-brand-primary { color: var(--color-brand-primary); }
.border-brand-primary { border-color: var(--color-brand-primary); }
.hover\:bg-brand-primary:hover { background-color: var(--color-brand-primary); }
```

---

## RT013 - Mensageria (Email e SMS)

### Email (AWS SES)

**Configuração**:
```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :ses
config.action_mailer.default_url_options = {
  host: ENV.fetch('APP_HOST', 'app.avsi.com')
}
```

**Mailer**:
```ruby
# app/mailers/recibo_mailer.rb
class ReciboMailer < ApplicationMailer
  def enviar_recibo(reciclagem)
    @reciclagem = reciclagem
    pdf = gerar_pdf(reciclagem)

    attachments["recibo_#{reciclagem.id}.pdf"] = pdf

    mail(
      to: reciclagem.parceiro.email,
      subject: "Recibo de Reciclagem - #{reciclagem.evento.nome}"
    )
  end
end
```

**Service**:
```ruby
# app/services/messaging/email/aws_ses_adapter.rb
module Messaging
  module Email
    class AwsSesAdapter < BaseAdapter
      def send_message(to:, subject:, body:, attachments: [])
        ReciboMailer.enviar_recibo(reciclagem).deliver_later
      end
    end
  end
end
```

### SMS (Zenvia)

**Service**:
```ruby
# app/services/recibos/zenvia_sms_service.rb
module Recibos
  class ZenviaSmsService
    BASE_URL = 'https://api.zenvia.com/v2/channels/sms/messages'

    def initialize(token)
      @token = token
    end

    def enviar(telefone, mensagem)
      response = HTTParty.post(BASE_URL,
        headers: {
          'X-API-TOKEN' => @token,
          'Content-Type' => 'application/json'
        },
        body: {
          from: 'AVSI',
          to: telefone,
          contents: [{ type: 'text', text: mensagem }]
        }.to_json
      )

      response.success?
    end
  end
end
```

**ENV**:
```env
ZENVIA_API_TOKEN=seu_token_aqui
AWS_ACCESS_KEY_ID=sua_key_aqui
AWS_SECRET_ACCESS_KEY=seu_secret_aqui
AWS_REGION=us-east-1
```

---

## RT014 - Deploy (Kamal)

### Arquitetura de Deploy

```
┌────────────────────────────────────────┐
│          Servidor (VPS/Cloud)          │
│  ┌──────────────────────────────────┐ │
│  │         Docker Engine            │ │
│  │                                  │ │
│  │  ┌────────────┐  ┌────────────┐ │ │
│  │  │ Container  │  │ Container  │ │ │
│  │  │ Rails App  │  │ PostgreSQL │ │ │
│  │  │   (Puma)   │  │            │ │ │
│  │  └─────┬──────┘  └─────┬──────┘ │ │
│  └────────┼───────────────┼────────┘ │
│           │               │          │
│  ┌────────▼───────────────▼────────┐ │
│  │       Docker Network            │ │
│  └─────────────────────────────────┘ │
└────────────────────────────────────────┘
              ▲
              │ HTTPS
              │
         [Traefik/Nginx]
```

### Configuração (config/deploy.yml)

```yaml
service: avsi_ecoenel
image: avsi_ecoenel

servers:
  web:
    - 192.168.0.1

registry:
  server: ghcr.io
  username: seu-usuario

env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    SOLID_QUEUE_IN_PUMA: true
    DB_HOST: avsi_ecoenel-db

volumes:
  - "avsi_ecoenel_storage:/rails/storage"

accessories:
  db:
    image: postgres:15
    host: 192.168.0.1
    port: "127.0.0.1:5432:5432"
    env:
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
```

### Processo de Deploy

**1. Setup Inicial**:
```bash
# Configurar secrets
kamal setup

# Deploy pela primeira vez
kamal deploy
```

**2. Deploy de Atualização**:
```bash
# Build + Push + Deploy
kamal deploy

# Apenas rolling restart (sem build)
kamal app boot
```

**3. Rollback**:
```bash
# Voltar para versão anterior
kamal rollback
```

**4. Comandos Úteis**:
```bash
# Console Rails
kamal app exec -i "bin/rails console"

# Logs em tempo real
kamal app logs -f

# SSH no container
kamal app exec -i bash

# Database console
kamal app exec -i "bin/rails dbconsole"
```

### Ambientes

| Ambiente | Uso | Branch | Deploy |
|----------|-----|--------|--------|
| Development | Dev local | develop | Manual |
| Staging | Testes | staging | Auto (CI) |
| Production | Produção | main | Manual |

### CI/CD (GitHub Actions)

**.github/workflows/deploy.yml**:
```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3
          bundler-cache: true

      - name: Install Kamal
        run: gem install kamal

      - name: Deploy
        env:
          RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
        run: kamal deploy
```

### Backup

**Database**:
```bash
# Manual
docker exec avsi_ecoenel-db pg_dump -U postgres ecoenel > backup.sql

# Automatizado (cron)
0 2 * * * /usr/local/bin/backup-db.sh
```

**Storage**:
```bash
# Backup de arquivos
docker volume inspect avsi_ecoenel_storage
rsync -avz /var/lib/docker/volumes/avsi_ecoenel_storage/_data/ backup-server:/backups/
```

---

## RT015 - Integrações Futuras

### Track and Trace (Rastreamento de Resíduos)

**Descrição**: Rastreamento completo do ciclo de vida dos resíduos coletados.

**Endpoints Planejados**:
```
POST /api/v1/track/coleta
POST /api/v1/track/triagem
POST /api/v1/track/destinacao
GET  /api/v1/track/:codigo/historico
```

**Payload Exemplo**:
```json
{
  "codigo": "RES-20250115-001",
  "tipo_residuo_id": 5,
  "peso": 150.5,
  "origem": {
    "evento_id": 123,
    "latitude": -23.550520,
    "longitude": -46.633308
  },
  "destino": {
    "parceiro_id": 45,
    "latitude": -23.561414,
    "longitude": -46.656178
  },
  "data": "2025-01-15T14:30:00Z",
  "status": "em_transporte"
}
```

**Tecnologias Sugeridas**:
- Blockchain para imutabilidade (Hyperledger Fabric)
- MQTT para IoT (sensores em caminhões)
- GraphQL para queries complexas de rastreamento

### Câmbio (Cotação de Créditos de Carbono)

**Descrição**: Integração com APIs de mercado de carbono para valoração de créditos.

**APIs Sugeridas**:
- Climate Trade API
- Gold Standard API
- Verra Registry API

**Endpoints Planejados**:
```
GET  /api/v1/cambio/cotacao_carbono
POST /api/v1/cambio/calcular_creditos
GET  /api/v1/cambio/historico
```

**Payload Exemplo**:
```json
{
  "toneladas_co2": 15.5,
  "origem": "reciclagem",
  "reciclagem_id": 456,
  "creditos_estimados": 31,
  "valor_unitario": 12.50,
  "moeda": "USD",
  "timestamp": "2025-01-15T15:00:00Z"
}
```

### Business Intelligence (BI)

**Descrição**: Dashboards avançados e análises preditivas.

**Ferramentas Sugeridas**:
- Metabase (open source)
- Superset (Apache)
- Tableau / Power BI (comercial)

**Métricas Principais**:
- Taxa de reciclagem por região
- Projeção de coleta mensal
- Impacto ambiental (CO2 evitado)
- Performance de parceiros
- Eficiência de eventos

### Notificações Push (Mobile)

**Tecnologias**:
- Firebase Cloud Messaging (FCM)
- OneSignal

**Eventos**:
- Novo evento disponível
- Reciclagem aprovada
- Recibo disponível
- Meta mensal atingida

**Implementação**:
```ruby
# app/jobs/push_notification_job.rb
class PushNotificationJob < ApplicationJob
  def perform(usuario_id, mensagem)
    usuario = Usuario.find(usuario_id)
    return unless usuario.device_token.present?

    fcm = FCM.new(ENV['FCM_SERVER_KEY'])
    fcm.send(
      [usuario.device_token],
      notification: {
        title: 'AVSI',
        body: mensagem
      }
    )
  end
end
```

### Geolocalização Avançada

**Funcionalidades Futuras**:
- Mapas de calor de coletas
- Otimização de rotas de coleta
- Geofencing para eventos
- Análise de cobertura territorial

**Bibliotecas**:
- Leaflet.js (mapas interativos - **já usado**)
- PostGIS (queries geográficas no PostgreSQL)
- Google Maps API / Mapbox API

---

## RT016 - Monitoramento e Logs

### Logs de Aplicação

**Níveis**:
```ruby
# config/environments/production.rb
config.log_level = :info
config.log_tags = [:request_id, :remote_ip]
```

**Formato**:
```
[2025-01-15 14:30:45] INFO [abc123] [192.168.1.1] Evento#create: Evento criado com sucesso (id: 456)
```

### Métricas Sugeridas

| Métrica | Ferramenta | Uso |
|---------|-----------|-----|
| APM | New Relic / Scout | Performance da app |
| Logs | Papertrail / Loggly | Centralização de logs |
| Uptime | UptimeRobot / Pingdom | Monitoramento de disponibilidade |
| Errors | Sentry / Rollbar | Rastreamento de erros |

### Healthcheck

**Endpoint**:
```
GET /up
```

**Response**:
```json
{
  "status": "ok",
  "database": "connected",
  "cache": "connected",
  "timestamp": "2025-01-15T14:30:00Z"
}
```

### Alertas

**Eventos para Alertar**:
- CPU > 80% por 5 minutos
- Memória > 90%
- Response time > 3s (p95)
- Error rate > 5%
- Database connections > 80% do pool
- Disco > 85% usado

---

## RT017 - Documentação de Código

### YARD (Ruby)

**Configuração**: `.yardopts`
```
--markup markdown
--output-dir doc/yard
app/**/*.rb
lib/**/*.rb
```

**Exemplo**:
```ruby
# @!group Gestão de Eventos

# Cria um novo evento no sistema
#
# @param evento_params [Hash] Parâmetros do evento
# @option evento_params [Date] :data Data do evento
# @option evento_params [Integer] :acao_id ID da ação
# @return [Evento, nil] Evento criado ou nil se falhar
# @raise [ActiveRecord::RecordInvalid] Se validações falharem
def criar_evento(evento_params)
  # ...
end
```

**Gerar documentação**:
```bash
bundle exec yard doc
```

### JSDoc (TypeScript)

**Exemplo**:
```typescript
/**
 * Formata CPF para o padrão 000.000.000-00
 *
 * @param {string | null} cpf - CPF sem formatação
 * @returns {string} CPF formatado ou string vazia
 *
 * @example
 * formatCpf('12345678900')
 * // => '123.456.789-00'
 */
export function formatCpf(cpf: string | null): string {
  // ...
}
```

---

## RT018 - Testes (Futuro)

### Stack de Testes Sugerida

| Camada | Framework | Tipo |
|--------|-----------|------|
| Models | RSpec | Unitário |
| Controllers | RSpec | Integração |
| Services | RSpec | Unitário |
| Frontend | Vitest | Unitário |
| E2E | Playwright | E2E |

### Exemplo (RSpec)

```ruby
# spec/models/evento_spec.rb
RSpec.describe Evento, type: :model do
  describe 'validações' do
    it { should validate_presence_of(:data) }
    it { should validate_presence_of(:acao_id) }
  end

  describe 'relacionamentos' do
    it { should belong_to(:acao) }
    it { should belong_to(:comunidade) }
  end

  describe '#status' do
    it 'inicia como aberto' do
      evento = build(:evento)
      expect(evento.status).to eq('aberto')
    end
  end
end
```

### Cobertura de Testes (Meta)

| Camada | Meta de Cobertura |
|--------|-------------------|
| Models | 90%+ |
| Controllers | 80%+ |
| Services | 85%+ |
| Frontend | 70%+ |
| E2E | Fluxos críticos |

---

## Dependências Externas

| Serviço | Uso | Criticidade | Fallback |
|---------|-----|-------------|----------|
| AWS SES | Envio de emails | Alta | Fila + retry |
| Zenvia | Envio de SMS | Média | Notificar admin |
| PostgreSQL | Banco de dados | **Crítica** | Backup diário |
| AWS S3 | Armazenamento de arquivos | Média | Storage local temporário |
| GitHub | Repositório + CI/CD | Alta | Deploy manual |

---

## Próximos Passos

### Prioridades para Q1 2025

1. **Completar API Mobile**
   - [ ] Autenticação JWT completa
   - [ ] Endpoints de reciclagem
   - [ ] Sincronização offline

2. **Relatórios**
   - [ ] Excel para todos relatórios
   - [ ] PDF com charts
   - [ ] Agendamento de relatórios

3. **Performance**
   - [ ] Implementar cache agressivo
   - [ ] Otimizar queries N+1
   - [ ] Index tuning

4. **Testes**
   - [ ] Setup RSpec
   - [ ] Testes de Models
   - [ ] Testes de API

### Roadmap 2025

| Q1 | Q2 | Q3 | Q4 |
|----|----|----|-----|
| API Mobile | Track & Trace | BI Avançado | Blockchain |
| Relatórios | Notificações Push | Geolocalização | Créditos de Carbono |
| Testes | Monitoramento | - | - |

---

## Glossário

| Termo | Definição |
|-------|-----------|
| **Ação** | Tipo de evento de coleta (ex: Coleta Seletiva, Doação) |
| **Contrato** | Unidade consumidora vinculada a cliente |
| **Evento** | Instância de uma ação em local e data específicos |
| **Parceiro** | Entidade que recebe resíduos (cooperativas, empresas) |
| **Reciclador** | Pessoa física que coleta resíduos |
| **Reciclagem** | Registro de coleta de resíduo em evento |
| **Recurso** | Tipo de resíduo coletado (PET, papel, vidro) |
| **Tenant** | Banco de dados em arquitetura multi-tenant |
| **Vigência** | Período de validade de relação reciclador-evento |

---

**Versão**: 1.0
**Data**: 2025-01-15
**Responsável**: Equipe Técnica AVSI
**Revisão**: Anual ou sob demanda
