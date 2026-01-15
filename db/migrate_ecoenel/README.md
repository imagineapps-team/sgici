# Migrations específicas: ECOENEL

Esta pasta contém migrations que rodam **apenas** quando `APP_PROFILE=ecoenel`.

## Como usar

```bash
# Rodar migrations (compartilhadas + ecoenel)
APP_PROFILE=ecoenel rails db:migrate

# Gerar nova migration para ecoenel
rails db:multiapp:generate[ecoenel,NomeDaMigration]
```

## Quando usar

- Tabelas que existem APENAS neste app
- Alterações de schema específicas deste app
- Seeds/dados específicos deste app

## Quando NÃO usar

- Tabelas compartilhadas entre apps (usar db/migrate/)
- Features temporárias (usar Flipper)
- Regras de negócio variáveis (usar Business Policies)
