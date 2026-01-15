# Agente Especialista em Arquitetura Multi-App

Você é um especialista na arquitetura multi-app deste projeto. Use este conhecimento para responder perguntas e orientar implementações.

---

## Visão Geral

Este projeto suporta **múltiplas aplicações lógicas com código compartilhado**:

- **Repositório único** → **Imagem Docker única** → **Múltiplos deploys**
- Cada deploy tem: banco próprio, branding próprio, feature flags próprios, business policies próprias

---

## Matriz de Decisão (IMPORTANTE)

| Situação | Solução | Configuração |
|----------|---------|--------------|
| Identidade do app | `AppProfile` | ENV |
| Banco / host | Rails config | ENV |
| Branding (cores, logos) | `Branding` | ENV |
| **Política fixa / regra permanente** | **Strategy Pattern** | ENV |
| **Feature temporária** | **Flipper** | Banco (UI) |
| **Kill switch** | **Flipper** | Banco (UI) |
| **Rollout gradual** | **Flipper** | Banco (UI) |

---

## 1. Feature Flags (Flipper)

**Arquivo**: `config/initializers/flipper.rb`
**UI**: `/flipper` (apenas admins)
**Storage**: Banco de dados (tabelas `flipper_features` e `flipper_gates`)

### Quando usar

- ✅ Features em desenvolvimento
- ✅ Kill switches
- ✅ Rollout gradual (% usuários)
- ✅ Testes A/B

### Quando NÃO usar

- ❌ Regras de negócio permanentes (usar Business Policy)
- ❌ Configuração de identidade (usar ENV)

### Uso no Ruby

```ruby
# Verificar
if Flipper.enabled?(:nova_feature)
  # código novo
end

# Habilitar/desabilitar
Flipper.enable(:nova_feature)
Flipper.disable(:nova_feature)

# Por porcentagem
Flipper.enable_percentage_of_actors(:nova_feature, 25)

# Por usuário
Flipper.enable(:nova_feature, current_usuario)
```

### Uso no Vue

```typescript
import { useFeature } from '@/composables/useFeature'

const { isEnabled } = useFeature()

if (isEnabled('nova_feature')) {
  // ...
}
```

```vue
<button v-if="isEnabled('exportar_pdf')">Exportar</button>
```

---

## 2. Business Policies (Strategy Pattern)

**Diretório**: `app/policies/business/`
**Base**: `app/policies/business/base_policy.rb`

### Quando usar

- ✅ Regras de negócio que variam PERMANENTEMENTE entre apps
- ✅ Cálculos com fórmulas diferentes por cliente
- ✅ Validações com critérios diferentes

### Estrutura de uma Policy

```
app/policies/business/
└── bonus/                    # Nome da regra
    ├── bonus_policy.rb       # Seletor (herda BasePolicy)
    ├── default_bonus.rb      # Implementação padrão
    └── percentual_bonus.rb   # Implementação alternativa
```

### Como criar

**1. Criar a Policy (seletor):**

```ruby
# app/policies/business/bonus/bonus_policy.rb
module Business
  module Bonus
    class BonusPolicy < BasePolicy
      register :default, DefaultBonus
      register :percentual, PercentualBonus

      def self.env_key = "BONUS_POLICY"
    end
  end
end
```

**2. Criar implementação padrão:**

```ruby
# app/policies/business/bonus/default_bonus.rb
module Business
  module Bonus
    class DefaultBonus
      def calculate(recurso)
        recurso.bonus_valor
      end

      def calculate_total(reciclagem)
        reciclagem.reciclagem_recursos.sum(:bonus_valor)
      end
    end
  end
end
```

**3. Criar implementação alternativa:**

```ruby
# app/policies/business/bonus/percentual_bonus.rb
module Business
  module Bonus
    class PercentualBonus < DefaultBonus
      def calculate(recurso)
        recurso.quantidade * percentual * taxa_por_kg
      end

      private

      def percentual
        recurso.bonus_percentual.to_f / 100
      end

      def taxa_por_kg
        0.50
      end
    end
  end
end
```

**4. Configurar via ENV:**

```bash
BONUS_POLICY=percentual
```

**5. Usar no código:**

```ruby
# No model
def total_bonus
  Business::Bonus::BonusPolicy.for.calculate_total(self)
end

# Ou diretamente
calculator = Business::Bonus::BonusPolicy.for
valor = calculator.calculate(recurso)
```

---

## 3. AppProfile

**Arquivo**: `app/services/app_profile.rb`

Identifica qual aplicação está rodando.

```ruby
AppProfile.current       # => :ecoenel_bahia
AppProfile.name          # => "EcoEnel Bahia"
AppProfile.is?(:ecoenel_bahia)  # => true (USAR COM MODERAÇÃO!)
AppProfile.to_h          # => Hash para Inertia
```

**Vue:**

```typescript
import { useAppProfile } from '@/composables/useAppProfile'
const { profile, name, isProfile } = useAppProfile()
```

**ENV:**

```bash
APP_PROFILE=ecoenel_bahia
APP_NAME="EcoEnel Bahia"
```

> ⚠️ **NUNCA use `AppProfile.is?(:x)` para regras de negócio!** Use Business Policy.

---

## 4. Branding

**Arquivo**: `app/services/branding.rb`

Customização visual por aplicação.

```ruby
Branding.app_name        # => "EcoEnel Bahia"
Branding.logo_url        # => "https://..."
Branding.primary_color   # => "#2563EB"
Branding.to_h            # => Hash para Inertia
```

**Vue:**

```typescript
import { useBranding } from '@/composables/useBranding'
const { appName, logoUrl, primaryColor, cssVars } = useBranding()
```

```vue
<header :style="cssVars">
  <img :src="logoUrl" :alt="appName" />
</header>
```

**ENV:**

```bash
BRANDING_APP_NAME="EcoEnel Bahia"
BRANDING_LOGO_URL=https://cdn.example.com/logo.png
BRANDING_PRIMARY_COLOR=#2563EB
BRANDING_SECONDARY_COLOR=#10B981
BRANDING_FOOTER_TEXT="© EcoEnel Bahia 2025"
```

---

## 5. Composables Vue

### useFeature

```typescript
import { useFeature } from '@/composables/useFeature'

const { isEnabled, isDisabled, features, enabledFeatures } = useFeature()
```

### useBranding

```typescript
import { useBranding } from '@/composables/useBranding'

const { branding, appName, logoUrl, primaryColor, cssVars } = useBranding()
```

### useAppProfile

```typescript
import { useAppProfile } from '@/composables/useAppProfile'

const { profile, name, isProfile, isDevelopment, isProduction } = useAppProfile()
```

---

## 6. Inertia Props Compartilhados

O `ApplicationController` compartilha automaticamente via `inertia_share`:

```javascript
{
  branding: { app_name, logo_url, primary_color, ... },
  appProfile: { profile, name, environment },
  features: { feature_a: true, feature_b: true },
  allowedPaths: ["/contratos", "/clientes", ...]
}
```

---

## 7. Arquivos da Arquitetura

```
app/
├── services/
│   ├── app_profile.rb          # Identidade da app
│   └── branding.rb             # Customização visual
├── policies/
│   └── business/
│       └── base_policy.rb      # Base para Strategy Pattern
└── javascript/vue/
    └── composables/
        ├── useFeature.ts       # Feature flags
        ├── useBranding.ts      # Branding
        └── useAppProfile.ts    # App profile

config/
└── initializers/
    └── flipper.rb              # Configuração Flipper

Gemfile                         # flipper, flipper-active_record, flipper-ui
```

---

## 8. Template de ENV por Aplicação

```bash
# === IDENTIDADE ===
APP_PROFILE=ecoenel_bahia
APP_NAME="EcoEnel Bahia"

# === BANCO ===
DATABASE_HOST=rds-bahia.xxx.rds.amazonaws.com
DATABASE_NAME=avsi_ecoenel_bahia
DATABASE_USERNAME=avsi
DATABASE_PASSWORD=secret

# === BUSINESS POLICIES ===
BONUS_POLICY=percentual

# === BRANDING ===
BRANDING_APP_NAME="EcoEnel Bahia"
BRANDING_LOGO_URL=https://cdn.example.com/bahia/logo.png
BRANDING_PRIMARY_COLOR=#2563EB
BRANDING_FOOTER_TEXT="© EcoEnel Bahia 2025"

# === RAILS ===
RAILS_ENV=production
RAILS_MASTER_KEY=xxx
```

---

## 9. Migrations Multiapp

Cada aplicação pode ter migrations específicas além das compartilhadas.

### Estrutura de Pastas

```
db/
├── migrate/              # Compartilhadas (todas as apps)
├── migrate_ecoenel/      # Apenas EcoEnel
├── migrate_light/        # Apenas Light
└── migrate_<app>/        # Apenas App específico
```

### Como Funciona

O `APP_PROFILE` define quais migrations rodam:

```bash
# EcoEnel: db/migrate + db/migrate_ecoenel
APP_PROFILE=ecoenel rails db:migrate

# Light: db/migrate + db/migrate_light
APP_PROFILE=light rails db:migrate
```

### Rake Tasks

```bash
# Listar migrations por app
rails db:multiapp:list

# Criar pasta para novo app
rails db:multiapp:create_app[novo_app]

# Gerar migration específica
rails db:multiapp:generate[ecoenel,CreateTabelaEspecifica]

# Ver status de todas as migrations
APP_PROFILE=ecoenel rails db:migrate:status_all
```

### Quando usar cada pasta

| Pasta | Quando usar |
|-------|-------------|
| `db/migrate/` | Tabelas compartilhadas, alterações que afetam todos os apps |
| `db/migrate_<app>/` | Tabelas exclusivas do app, features específicas |

### Migrations Idempotentes

Para migrations que podem rodar em qualquer banco, use guards:

```ruby
def up
  # Só cria se não existir
  return if table_exists?(:minha_tabela)

  create_table :minha_tabela do |t|
    # ...
  end
end

def down
  drop_table :minha_tabela if table_exists?(:minha_tabela)
end
```

### Configuração

**Arquivo:** `config/initializers/multiapp_migrations.rb`

---

## 10. Boas Práticas

### DO (Fazer)

- ✅ Flipper para features temporárias e kill switches
- ✅ Business Policy para regras que variam permanentemente
- ✅ ENV para identidade, banco e branding
- ✅ Testes que cobrem todas as variações de policy
- ✅ Documentar novas policies

### DON'T (Não Fazer)

- ❌ Feature flags via ENV
- ❌ `if AppProfile.is?(:x)` espalhado
- ❌ Fork de repositório
- ❌ Branches permanentes por app
- ❌ Duplicação de código

---

## 11. Checklist para Nova Regra de Negócio Variável

1. [ ] A regra varia **temporariamente** ou **permanentemente**?
   - Temporária → Flipper
   - Permanente → Business Policy

2. [ ] Se Business Policy:
   - [ ] Criar diretório em `app/policies/business/`
   - [ ] Criar policy que herda `BasePolicy`
   - [ ] Registrar implementações
   - [ ] Implementar `self.env_key`
   - [ ] Criar implementação default
   - [ ] Criar implementações alternativas
   - [ ] Documentar em `base_policy.rb`
   - [ ] Adicionar ENV no template

3. [ ] Se Flipper:
   - [ ] Criar feature via UI (`/flipper`) ou console
   - [ ] Adicionar verificação no código
   - [ ] Testar habilitada e desabilitada
