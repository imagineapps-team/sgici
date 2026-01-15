# Migrations específicas: LIGHT

Esta pasta contém migrations que rodam **apenas** quando `APP_PROFILE=light`.

## Como usar

```bash
# Rodar migrations (compartilhadas + light)
APP_PROFILE=light rails db:migrate

# Gerar nova migration para light
rails db:multiapp:generate[light,NomeDaMigration]
```

## Quando usar

- Tabelas que existem APENAS neste app
- Alterações de schema específicas deste app
- Seeds/dados específicos deste app

## Quando NÃO usar

- Tabelas compartilhadas entre apps (usar db/migrate/)
- Features temporárias (usar Flipper)
- Regras de negócio variáveis (usar Business Policies)
