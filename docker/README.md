# Docker - Producao (EC2)

Este diretorio contem a configuracao Docker para deploy em **producao** na EC2.

## Arquitetura

```
                              EC2
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                     Nginx (existente)                       │ │
│  │                      :80 / :443                             │ │
│  └────┬────────┬────────┬────────┬────────┬────────┬──────────┘ │
│       │        │        │        │        │        │            │
│       ▼        ▼        ▼        ▼        ▼        ▼            │
│  ┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐  │
│  │ecoenel ││ecoenel ││ecoenel ││ light  ││ light  ││ light  │  │
│  │  dev   ││ stage  ││  prod  ││  dev   ││ stage  ││  prod  │  │
│  │ :3010  ││ :3011  ││ :3012  ││ :3020  ││ :3021  ││ :3022  │  │
│  └────────┘└────────┘└────────┘└────────┘└────────┘└────────┘  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Mapeamento de Portas

| App      | Ambiente | Porta | Host (exemplo)              |
|----------|----------|-------|-----------------------------|
| EcoEnel  | dev      | 3010  | ecoenel-dev.seudominio.com  |
| EcoEnel  | stage    | 3011  | ecoenel-stage.seudominio.com|
| EcoEnel  | prod     | 3012  | ecoenel.seudominio.com      |
| Light    | dev      | 3020  | light-dev.seudominio.com    |
| Light    | stage    | 3021  | light-stage.seudominio.com  |
| Light    | prod     | 3022  | light.seudominio.com        |

## Estrutura de Arquivos

```
docker/
├── docker-compose.prod.yml     # Compose para producao
├── .env.example                # Exemplo de variaveis globais
├── .gitignore
└── envs/                       # Variaveis por app/ambiente
    ├── ecoenel.dev.env.example
    ├── ecoenel.stage.env.example
    ├── ecoenel.prod.env.example
    ├── light.dev.env.example
    ├── light.stage.env.example
    └── light.prod.env.example
```

## Desenvolvimento Local

Para desenvolvimento local, use o `docker-compose.yml` na **raiz do projeto**:

```bash
# Na raiz do projeto (NAO em docker/)
docker compose up -d

# Acessar:
# EcoEnel: http://localhost:3000
# Light:   http://localhost:3001
```

## Deploy em Producao

O deploy e feito via **GitHub Actions** (workflow manual):

1. Acesse: Actions → Deploy DEV/STAGE/PROD
2. Clique em "Run workflow"
3. Selecione app (ecoenel/light/both)
4. Execute

### Secrets Necessarios no GitHub

| Secret           | Descricao                                    |
|------------------|----------------------------------------------|
| `EC2_HOST`       | IP ou hostname da EC2                        |
| `EC2_USER`       | Usuario SSH (ex: ubuntu, ec2-user)           |
| `EC2_SSH_KEY`    | Chave SSH privada (base64 encoded)           |
| `RAILS_MASTER_KEY` | Master key do Rails                        |

### Configurar SSH Key

```bash
# Gerar base64 da chave
cat ~/.ssh/sua-chave.pem | base64 -w 0

# Adicionar como secret EC2_SSH_KEY no GitHub
```

## Setup Inicial na EC2

```bash
# 1. Instalar Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 2. Criar diretorio
sudo mkdir -p /opt/avsi/docker
sudo chown -R $USER:$USER /opt/avsi

# 3. Clonar/copiar arquivos
cd /opt/avsi/docker
# Copiar docker-compose.prod.yml, .env e envs/

# 4. Configurar arquivos .env
cp .env.example .env
nano .env  # Ajustar REGISTRY

# 5. Configurar envs por ambiente
cd envs
cp ecoenel.dev.env.example ecoenel.dev.env
cp ecoenel.stage.env.example ecoenel.stage.env
cp ecoenel.prod.env.example ecoenel.prod.env
cp light.dev.env.example light.dev.env
cp light.stage.env.example light.stage.env
cp light.prod.env.example light.prod.env
# Editar cada arquivo com DATABASE_URL e SECRET_KEY_BASE

# 6. Primeiro deploy (ou usar GitHub Actions)
docker compose -f docker-compose.prod.yml --env-file .env up -d ecoenel-prod light-prod
```

## Configurar Nginx

Adicione ao Nginx existente:

```nginx
# /etc/nginx/sites-available/avsi

# EcoEnel DEV
server {
    listen 80;
    server_name ecoenel-dev.seudominio.com;

    location / {
        proxy_pass http://127.0.0.1:3010;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# EcoEnel STAGE
server {
    listen 80;
    server_name ecoenel-stage.seudominio.com;

    location / {
        proxy_pass http://127.0.0.1:3011;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# EcoEnel PROD
server {
    listen 80;
    server_name ecoenel.seudominio.com;

    location / {
        proxy_pass http://127.0.0.1:3012;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Light DEV
server {
    listen 80;
    server_name light-dev.seudominio.com;

    location / {
        proxy_pass http://127.0.0.1:3020;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Light STAGE
server {
    listen 80;
    server_name light-stage.seudominio.com;

    location / {
        proxy_pass http://127.0.0.1:3021;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Light PROD
server {
    listen 80;
    server_name light.seudominio.com;

    location / {
        proxy_pass http://127.0.0.1:3022;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Ativar e recarregar
sudo ln -s /etc/nginx/sites-available/avsi /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Para SSL, use certbot:
sudo certbot --nginx -d ecoenel.seudominio.com -d light.seudominio.com
```

## Comandos Uteis

```bash
cd /opt/avsi/docker

# Ver status
docker compose -f docker-compose.prod.yml ps

# Logs de um container
docker compose -f docker-compose.prod.yml logs -f ecoenel-prod

# Restart de um container
docker compose -f docker-compose.prod.yml restart ecoenel-prod

# Rails console
docker compose -f docker-compose.prod.yml exec ecoenel-prod bin/rails c

# Migrations manuais
docker compose -f docker-compose.prod.yml exec ecoenel-prod bin/rails db:migrate

# Parar tudo
docker compose -f docker-compose.prod.yml down
```

## Troubleshooting

### Container nao inicia

```bash
docker compose -f docker-compose.prod.yml logs ecoenel-prod
```

**Causas comuns**:
- DATABASE_URL incorreto no .env
- SECRET_KEY_BASE faltando
- Banco nao existe no RDS

### App nao acessivel

1. Verificar se container esta rodando: `docker compose ps`
2. Verificar Nginx: `sudo nginx -t`
3. Verificar porta: `curl http://localhost:3012/up`
