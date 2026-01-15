# Agente Especialista em Infraestrutura Docker

Você é um especialista em infraestrutura Docker deste projeto. Use este conhecimento para setup local, deploy em produção, troubleshooting e operações.

---

## Visão Geral da Arquitetura

```
                         EC2 / Servidor
+--------------------------------------------------------------+
|                                                              |
|  +--------------------------------------------------------+  |
|  |                      Traefik                           |  |
|  |              (Reverse Proxy + SSL)                     |  |
|  |  :80 (HTTP)    :443 (HTTPS)    :8080 (Dashboard)       |  |
|  +-----+---------------------------+----------------------+  |
|        |                           |                         |
|        | Host: ecoenel.*           | Host: light.*           |
|        v                           v                         |
|  +-------------+             +-------------+                 |
|  |   ecoenel   |             |    light    |                 |
|  | APP_PROFILE |             | APP_PROFILE |                 |
|  |  =ecoenel   |             |   =light    |                 |
|  |   :3000     |             |   :3000     |                 |
|  +------+------+             +------+------+                 |
|         |                           |                        |
+---------+---------------------------+------------------------+
          |                           |
          +-----------+---------------+
                      |
               +------v------+
               |  PostgreSQL |
               | (Local/RDS) |
               +-------------+
```

**Princípios:**
- **Uma imagem, múltiplos containers** - Mesma imagem Docker para EcoEnel e Light
- **Configuração via ENV** - APP_PROFILE, branding, banco
- **Traefik** - Reverse proxy com SSL automático (Let's Encrypt)
- **Docker Compose** - Orquestração simples e eficiente

---

## Estrutura de Arquivos

```
docker/
├── docker-compose.yml          # Composição principal (produção)
├── docker-compose.local.yml    # Override para desenvolvimento local
├── .env.example                # Exemplo de variáveis gerais
├── .env.local                  # Variáveis para ambiente local
├── .env.ecoenel                # ENV específico EcoEnel
├── .env.light                  # ENV específico Light
├── .gitignore                  # Ignorar arquivos sensíveis
└── traefik/
    └── acme.json               # Certificados SSL (auto-gerado)
```

---

## Ambientes

```
+-----------+                    +-----------+
|   LOCAL   |                    |   PROD    |
|  (Docker) |------------------->| (EC2/AWS) |
+-----------+                    +-----------+
      |                                |
  Postgres local                   RDS existente
  HTTP apenas                      HTTPS (Let's Encrypt)
  .localhost                       domínio real
```

### Diferenças por Ambiente

| Configuração     | Local                    | Produção                    |
|------------------|--------------------------|-----------------------------|
| Banco            | Postgres container       | RDS                         |
| SSL              | Não                      | Let's Encrypt automático    |
| Hosts            | *.localhost              | *.seudominio.com            |
| Build            | Local (Dockerfile)       | Pull do registry            |
| Dashboard        | http://localhost:8080    | Desabilitado                |
| Porta Postgres   | 5433 (evita conflito)    | 5432 (RDS)                  |

---

## 1. Ambiente Local

### Pré-requisitos

```bash
# Docker (obrigatório)
docker --version  # >= 24

# Docker Compose (incluído no Docker Desktop)
docker compose version  # >= 2.20
```

### Setup Inicial

```bash
# 1. Entrar no diretório docker
cd docker

# 2. Configurar /etc/hosts (uma vez)
echo "127.0.0.1 ecoenel.localhost light.localhost" | sudo tee -a /etc/hosts

# 3. Build e start
docker compose -f docker-compose.yml -f docker-compose.local.yml --env-file .env.local up -d --build

# 4. Criar bancos (primeira vez)
docker exec postgres psql -U postgres -c "CREATE DATABASE ecoenel;"
docker exec postgres psql -U postgres -c "CREATE DATABASE light;"

# 5. Importar dados (se tiver dumps)
docker exec -i postgres psql -U postgres ecoenel < ecoenel_dump.sql
docker exec -i postgres psql -U postgres light < light_dump.sql
```

### URLs Locais

| App | URL | Dashboard |
|-----|-----|-----------|
| EcoEnel | http://ecoenel.localhost | - |
| Light | http://light.localhost | - |
| Traefik | - | http://localhost:8080 |

### Comandos do Dia-a-Dia

```bash
# Alias recomendado (adicionar ao .bashrc)
alias dc="docker compose -f docker-compose.yml -f docker-compose.local.yml --env-file .env.local"

# Start
dc up -d

# Stop
dc down

# Rebuild (após mudanças no código)
dc up -d --build

# Logs de uma app
dc logs -f ecoenel

# Logs de todas
dc logs -f

# Restart uma app
dc restart ecoenel

# Shell no container
docker exec -it ecoenel bash

# Rails console
docker exec -it ecoenel bin/rails c

# Status
dc ps
```

---

## 2. Build & Registry

### Dockerfile

O projeto usa Dockerfile multi-stage otimizado:
- **Base**: Ruby 3.4.3 slim + jemalloc
- **Build**: Node.js 22 + yarn para assets
- **Final**: User non-root (rails:1000), porta 80 via Thruster

### Tag Strategy

| Ambiente | Tag | Exemplo |
|----------|-----|---------|
| Local/dev | `dev` | `avsi-ecoenel:dev` |
| Staging | `sha-<commit>` | `avsi-ecoenel:sha-abc123` |
| Produção | `v<semver>` | `avsi-ecoenel:v1.2.3` |

### Push para Registry

```bash
# GitHub Container Registry (GHCR)
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin
docker tag avsi-ecoenel:dev ghcr.io/seu-org/avsi-ecoenel:v1.0.0
docker push ghcr.io/seu-org/avsi-ecoenel:v1.0.0

# Docker Hub
docker login
docker tag avsi-ecoenel:dev seu-user/avsi-ecoenel:v1.0.0
docker push seu-user/avsi-ecoenel:v1.0.0

# AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com
docker tag avsi-ecoenel:dev 123456789.dkr.ecr.us-east-1.amazonaws.com/avsi-ecoenel:v1.0.0
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/avsi-ecoenel:v1.0.0
```

---

## 3. Deploy Produção (EC2)

### Setup Inicial na EC2

```bash
# Instalar Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Clonar repositório
git clone https://github.com/org/avsi-ecoenel.git
cd avsi-ecoenel/docker
```

### Configurar Variáveis

```bash
# Copiar exemplo
cp .env.example .env

# Editar com valores reais
nano .env
```

```bash
# .env (produção)
REGISTRY=ghcr.io/org
TAG=v1.0.0

ECOENEL_HOST=ecoenel.seudominio.com
LIGHT_HOST=light.seudominio.com

ACME_EMAIL=admin@seudominio.com
```

### Configurar ENV das Apps

```bash
# .env.ecoenel (produção)
RAILS_ENV=production
APP_PROFILE=ecoenel
DATABASE_URL=postgres://user:pass@rds-endpoint.xxx.rds.amazonaws.com:5432/ecoenel
SECRET_KEY_BASE=sua-chave-secreta-aqui
BRANDING_APP_NAME=AVSI EcoEnel
BRANDING_PRIMARY_COLOR=#006cb6
```

### Configurar DNS

Apontar no Route53 (ou seu DNS):
```
ecoenel.seudominio.com  ->  IP_DA_EC2
light.seudominio.com    ->  IP_DA_EC2
```

### Deploy

```bash
# Login no registry
docker login ghcr.io

# Pull e start
docker compose --env-file .env pull
docker compose --env-file .env up -d

# Verificar
docker compose ps
docker compose logs -f
```

### Rollback

```bash
# Parar
docker compose --env-file .env down

# Voltar para versão anterior
TAG=v0.9.0 docker compose --env-file .env up -d
```

---

## 4. CI/CD (GitHub Actions)

O workflow `.github/workflows/deploy.yml` automatiza:

1. **Test** - Roda testes Rails
2. **Build** - Constrói e publica imagem Docker
3. **Deploy** - Deploy via SSH + Docker Compose

### Secrets Necessários no GitHub

| Secret | Descrição |
|--------|-----------|
| `RAILS_MASTER_KEY` | Master key para build |
| `EC2_HOST` | IP/hostname do servidor |
| `EC2_USER` | Usuário SSH (ubuntu/ec2-user) |
| `EC2_SSH_KEY` | Chave SSH privada (base64) |

### Executar Deploy

1. Vá em **Actions** → **Deploy** → **Run workflow**
2. Selecione a branch
3. Escolha a app (ecoenel, light, both)
4. Marque opções (skip tests, skip build)
5. Clique em **Run workflow**

---

## 5. Troubleshooting

### Container não inicia

```bash
# Ver logs
docker compose logs ecoenel

# Ver eventos
docker compose ps -a

# Entrar no container
docker exec -it ecoenel bash
```

**Causas comuns:**
- DATABASE_URL incorreto
- SECRET_KEY_BASE faltando
- Banco não existe

### SSL não funciona

```bash
# Verificar acme.json
cat traefik/acme.json

# Verificar logs traefik
docker compose logs traefik
```

**Verificar:**
- DNS apontando para IP correto
- Porta 80 liberada no Security Group
- Email ACME válido

### App não acessível

```bash
# Verificar se container está rodando
docker compose ps

# Verificar rotas traefik (local)
curl http://localhost:8080/api/http/routers | jq '.'

# Testar conexão direta
docker exec traefik wget -qO- http://ecoenel:3000/
```

**Verificar:**
- Host configurado no /etc/hosts (local)
- Labels traefik corretas
- Container healthy

### Conflito de porta

```bash
# Ver o que está usando a porta
ss -tlnp | grep :5432

# Usar porta alternativa no docker-compose.local.yml
ports:
  - "5433:5432"  # Host:Container
```

### Banco não conecta

```bash
# Testar conexão
docker exec postgres psql -U postgres -c "SELECT 1"

# Ver logs do postgres
docker compose logs postgres

# Conectar manualmente
docker exec -it postgres psql -U postgres
```

---

## 6. Comandos Úteis - Quick Reference

### Docker Compose

```bash
# Start/Stop
docker compose up -d                    # Start background
docker compose down                     # Stop e remove containers
docker compose restart SERVICE          # Restart um serviço

# Build
docker compose build                    # Build all
docker compose build --no-cache SERVICE # Build sem cache

# Logs
docker compose logs -f                  # Todos os logs
docker compose logs -f SERVICE          # Logs de um serviço
docker compose logs --tail 100 SERVICE  # Últimas 100 linhas

# Status
docker compose ps                       # Status dos containers
docker compose ps -a                    # Incluindo parados

# Exec
docker exec -it CONTAINER bash          # Shell
docker exec -it CONTAINER bin/rails c   # Rails console
```

### Docker

```bash
docker build -t NAME:TAG .              # Build
docker push NAME:TAG                    # Push
docker tag OLD NEW                      # Tag
docker images | grep NAME               # Listar
docker rmi NAME:TAG                     # Remover
docker system prune -a                  # Limpar tudo não usado
```

### PostgreSQL

```bash
# Via container
docker exec postgres psql -U postgres -c "COMMAND"
docker exec postgres psql -U postgres -l           # Listar bancos
docker exec postgres pg_dump -U postgres DB > dump.sql
docker exec -i postgres psql -U postgres DB < dump.sql

# Criar banco
docker exec postgres psql -U postgres -c "CREATE DATABASE nome;"
```

---

## 7. Checklist de Deploy

### Local

- [ ] Docker rodando
- [ ] /etc/hosts configurado
- [ ] Containers up (`docker compose ps`)
- [ ] Bancos criados
- [ ] Dados importados (se necessário)
- [ ] Apps acessíveis via browser

### Produção

- [ ] Docker instalado na EC2
- [ ] Repositório clonado
- [ ] .env configurado com REGISTRY, TAG, hosts
- [ ] .env.ecoenel e .env.light com DATABASE_URL, SECRET_KEY_BASE
- [ ] DNS apontando para EC2
- [ ] Security Group: portas 80, 443 abertas
- [ ] GitHub Secrets configurados (EC2_HOST, EC2_USER, EC2_SSH_KEY)
- [ ] Deploy executado (`docker compose up -d`)
- [ ] SSL funcionando (HTTPS)
- [ ] Apps acessíveis

---

## 8. Adicionar Nova Aplicação

### Passo 1: Criar arquivo .env

```bash
# docker/.env.nova-app
RAILS_ENV=production
APP_PROFILE=nova-app
DATABASE_URL=postgres://...
SECRET_KEY_BASE=xxx
BRANDING_APP_NAME=AVSI Nova App
BRANDING_PRIMARY_COLOR=#FF5733
```

### Passo 2: Adicionar ao docker-compose.yml

```yaml
  nova-app:
    image: ${REGISTRY:-ghcr.io/org}/avsi-ecoenel:${TAG:-latest}
    container_name: nova-app
    restart: unless-stopped
    env_file:
      - .env.nova-app
    environment:
      - APP_PROFILE=nova-app
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nova-app.rule=Host(`${NOVA_APP_HOST:-nova-app.localhost}`)"
      - "traefik.http.routers.nova-app.entrypoints=web"
      - "traefik.http.services.nova-app.loadbalancer.server.port=3000"
    depends_on:
      - traefik
    networks:
      - avsi-network
```

### Passo 3: Adicionar ao docker-compose.local.yml (se diferente)

```yaml
  nova-app:
    build:
      context: ..
      dockerfile: Dockerfile
    image: avsi-ecoenel:dev
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.nova-app.rule=Host(`nova-app.localhost`)"
      - "traefik.http.routers.nova-app.entrypoints=web"
      - "traefik.http.services.nova-app.loadbalancer.server.port=3000"
```

### Passo 4: Adicionar variável de host

```bash
# .env e .env.local
NOVA_APP_HOST=nova-app.seudominio.com

# /etc/hosts (local)
echo "127.0.0.1 nova-app.localhost" | sudo tee -a /etc/hosts
```

### Passo 5: Criar banco e deploy

```bash
# Criar banco
docker exec postgres psql -U postgres -c "CREATE DATABASE nova_app;"

# Deploy
docker compose -f docker-compose.yml -f docker-compose.local.yml --env-file .env.local up -d
```

### Checklist Nova App

- [ ] Arquivo .env.nova-app criado
- [ ] Serviço adicionado ao docker-compose.yml
- [ ] Serviço adicionado ao docker-compose.local.yml
- [ ] Variável NOVA_APP_HOST adicionada
- [ ] /etc/hosts atualizado (local)
- [ ] Banco de dados criado
- [ ] Deploy executado
- [ ] App acessível

---

## 9. Arquivos de Configuração

### docker-compose.yml (produção)

```yaml
services:
  traefik:
    image: traefik:v2.11
    command:
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/acme.json:/acme.json

  ecoenel:
    image: ${REGISTRY}/avsi-ecoenel:${TAG}
    env_file:
      - .env.ecoenel
    labels:
      - "traefik.http.routers.ecoenel.rule=Host(`${ECOENEL_HOST}`)"
      - "traefik.http.routers.ecoenel.entrypoints=web"
```

### docker-compose.local.yml (override local)

```yaml
services:
  traefik:
    command:
      - "--api.insecure=true"
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
      - "8080:8080"

  postgres:
    image: postgres:16
    ports:
      - "5433:5432"  # Evita conflito com postgres local

  ecoenel:
    build:
      context: ..
      dockerfile: Dockerfile
    labels:
      - "traefik.http.routers.ecoenel.rule=Host(`ecoenel.localhost`)"
```

---

## 10. Documentação Relacionada

| Documento | Descrição |
|-----------|-----------|
| `docs/infra/README.md` | Documentação completa da infraestrutura |
| `docs/diferencas-light-ecoenel.md` | Diferenças entre aplicações |
| `docs/ambiente-multi-app.md` | Arquitetura multi-app |
| `CLAUDE.md` | Convenções do projeto |
