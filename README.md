# SGICI - Sistema de Gestão de Importações, Custos e Indicadores

Sistema web para gestão completa de processos de importação, controle de custos, análise de indicadores e suporte à tomada de decisão.

## Visão Geral

O SGICI permite:
- Registrar e acompanhar processos de importação
- Controlar custos previstos e realizados
- Consolidar dados financeiros por operação
- Visualizar indicadores, gráficos e projeções
- Substituir planilhas Excel manuais
- Suportar crescimento acelerado da operação

## Stack Tecnológico

| Camada | Tecnologia |
|--------|------------|
| Backend | Ruby on Rails 8.1 |
| Frontend | Vue 3 + TypeScript |
| SSR Framework | Inertia.js |
| CSS | Tailwind CSS |
| Database | PostgreSQL |
| Autenticação | Devise + JWT (API) |
| Autorização | Pundit |
| Feature Flags | Flipper |
| Relatórios | caxlsx (Excel), grover (PDF) |
| Deploy | Kamal (Docker) |

## Documentação

| Documento | Descrição |
|-----------|-----------|
| [docs/rn.md](docs/rn.md) | Regras de Negócio |
| [docs/rf.md](docs/rf.md) | Requisitos Funcionais |
| [docs/rt.md](docs/rt.md) | Requisitos Técnicos |
| [docs/gaps-oportunidades.md](docs/gaps-oportunidades.md) | Análise de Mercado |

## Quick Start

### Pré-requisitos

- Ruby 3.3+
- Node.js 20+
- PostgreSQL 12+
- Yarn

### Instalação

```bash
# Clone o repositório
git clone git@github.com:imagineapps-team/sgici.git
cd sgici

# Instale dependências Ruby
bundle install

# Instale dependências JavaScript
yarn install

# Configure o banco de dados
cp .env.example .env
# Edite .env com suas configurações

# Crie o banco
rails db:create db:migrate db:seed

# Inicie o servidor de desenvolvimento
bin/dev
```

### Docker

```bash
# Subir containers
docker compose up -d

# Acessar: http://localhost:3000
```

## Perfis de Usuário

| Perfil | Descrição |
|--------|-----------|
| **Administrador** | Gerencia usuários, parâmetros e permissões |
| **Operacional** | Cadastra processos, custos e eventos |
| **Gestor** | Analisa indicadores, custos e relatórios |

## Fluxo do Processo de Importação

```
Planejado → Aprovado → Em Trânsito → Desembaraçado → Finalizado
```

## Módulos

### MVP (Fase 1)
- [x] Infraestrutura base (Rails + Vue + Inertia)
- [ ] Cadastro de processos de importação
- [ ] Gestão de custos previsto × real
- [ ] Dashboard financeiro básico
- [ ] Exportação para Excel

### Futuro
- [ ] Simulador de cenários
- [ ] Score de fornecedor
- [ ] Portal do fornecedor
- [ ] Integração WhatsApp
- [ ] Previsão de custos com IA

## Estrutura de Diretórios

```
sgici/
├── app/
│   ├── controllers/     # Controllers Rails
│   ├── models/          # Models ActiveRecord
│   ├── services/        # Service Objects
│   ├── policies/        # Pundit Policies
│   └── javascript/
│       └── vue/
│           ├── pages/       # Páginas Inertia
│           ├── components/  # Componentes Vue
│           └── composables/ # Composables Vue
├── config/
├── db/
│   ├── migrate/         # Migrations
│   └── seeds/           # Dados iniciais
└── docs/                # Documentação
```

## Convenções

Veja `CLAUDE.md` para convenções de código, componentes e padrões do projeto.

## Licença

Propriedade de ImagineApps Team. Todos os direitos reservados.
