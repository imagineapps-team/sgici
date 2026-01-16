# SGICI - Convenções e Contexto do Projeto

## Sistema de Gestão de Importações, Custos e Indicadores

Sistema web para gestão completa de processos de importação, controle de custos e análise de indicadores.

---

## REFERÊNCIA OBRIGATÓRIA: avsi-multiapp

**IMPORTANTE**: O projeto `~/code/avsi-multiapp` é a REFERÊNCIA FUNCIONAL para todo o desenvolvimento do SGICI.

### Regras de Desenvolvimento

1. **SEMPRE consultar avsi-multiapp antes de criar/modificar código**
2. **Copiar padrões, NÃO inventar novos** - A arquitetura já está validada
3. **Manter consistência** - Controllers, pages Vue, composables devem seguir os mesmos padrões

### Arquivos de Referência por Tipo

| Tipo | Arquivo Referência em avsi-multiapp |
|------|-------------------------------------|
| **Controller CRUD Completo** | `app/controllers/reciclagens_controller.rb` |
| **Controller CRUD Simples** | `app/controllers/usuarios_controller.rb` |
| **Controller Eventos (nested)** | `app/controllers/eventos_controller.rb` |
| **Page Index DataTable** | `app/javascript/vue/pages/usuarios/UsuariosIndex.vue` |
| **Page Index Avançada** | `app/javascript/vue/pages/reciclagens/ReciclagensIndex.vue` |
| **Page Form Simples** | `app/javascript/vue/pages/usuarios/UsuariosForm.vue` |
| **Page Form Complexo** | `app/javascript/vue/pages/reciclagens/ReciclagensForm.vue` |
| **Page Show/Detalhes** | `app/javascript/vue/pages/reciclagens/ReciclagensShow.vue` |
| **Dashboard** | `app/javascript/vue/pages/dashboard/DashboardIndex.vue` |
| **Relatórios** | `app/controllers/relatorios_controller.rb` |
| **Types TypeScript** | `app/javascript/vue/types/` |
| **Composables** | `app/javascript/vue/composables/` |

### Comando Rápido para Consulta

```bash
# Ver controller de referência
cat ~/code/avsi-multiapp/app/controllers/reciclagens_controller.rb

# Ver page de referência
cat ~/code/avsi-multiapp/app/javascript/vue/pages/reciclagens/ReciclagensIndex.vue

# Buscar padrão específico
grep -r "def show" ~/code/avsi-multiapp/app/controllers/
```

### Checklist Antes de Criar Código

- [ ] Consultei o arquivo de referência correspondente em avsi-multiapp?
- [ ] Estou seguindo o mesmo padrão de nomenclatura?
- [ ] As props do Inertia estão em camelCase?
- [ ] Os métodos JSON seguem o padrão `*_list_json`, `*_form_json`, `*_detail_json`?
- [ ] O controller herda de `InertiaController`?

---

## Documentação

| Documento | Descrição |
|-----------|-----------|
| `docs/rn.md` | Regras de Negócio |
| `docs/rf.md` | Requisitos Funcionais |
| `docs/rt.md` | Requisitos Técnicos |
| `docs/gaps-oportunidades.md` | Análise de Mercado |

## Arquitetura

### Feature Flags

| Situação | Solução |
|----------|---------|
| Feature temporária / kill switch | **Flipper** |
| Regra de negócio permanente | **Business Policy** (`app/policies/business/`) |
| Identidade / branding | **ENV** |

### Infraestrutura

| Ambiente | Ferramenta | Comando |
|----------|------------|---------|
| Dev local | docker-compose | `docker compose up` |
| Produção | Kamal | Deploy via Docker |

---

## Contexto do Projeto

Este projeto é o **SGICI - Sistema de Gestão de Importações, Custos e Indicadores**.

### Banco de Dados

- Criar migrations para novas tabelas do SGICI
- Usar convenções Rails para nomenclatura
- Verificar estrutura existente antes de qualquer alteração

```ruby
# Exemplo de Model para tabela existente
class Contrato < ApplicationRecord
  self.table_name = 'contratos'  # se necessário

  belongs_to :contrato_tipo, foreign_key: 'contrato_tipo_id'
  belongs_to :cliente, optional: true
end
```

## Stack

- **Backend**: Ruby on Rails 7.1
- **Frontend**: Vue 3 + TypeScript + Inertia.js
- **Estilização**: Tailwind CSS
- **Banco de dados**: PostgreSQL (tabelas legadas do CakePHP)
- **Ícones**: @heroicons/vue

## Convenções de Nomenclatura

### Páginas Vue (Inertia)

Usar **CamelCase** para nomes de arquivos de páginas:

```
app/javascript/vue/pages/
├── contratos/
│   ├── ContratosIndex.vue    ✅ (não usar index.vue)
│   └── ContratosForm.vue     ✅ (não usar form.vue)
├── clientes/
│   ├── ClientesIndex.vue
│   └── ClientesForm.vue
└── dashboard/
    └── DashboardIndex.vue
```

### Componentes

Componentes genéricos usam prefixo **I** (Interface):

```
app/javascript/vue/components/
├── IInput/
├── ISelect/
├── IModal/
├── ConfirmationModal/
└── DataTable/
```

### Props do Inertia (Rails → Vue)

**IMPORTANTE**: O Inertia.js **NÃO converte automaticamente** os nomes das props de `snake_case` (Ruby) para `camelCase` (JavaScript). Os nomes devem ser idênticos em ambos os lados.

**Convenção**: Usar **camelCase** nas props do controller Rails para corresponder ao Vue.

```ruby
# Controller Rails - CORRETO
render inertia: 'exemplo/ExemploIndex', props: {
  usuario: current_usuario.as_json,
  tipoVeiculos: tipo_veiculos_options,    # camelCase
  statusOptions: status_options            # camelCase
}

# Controller Rails - INCORRETO (Vue não vai receber)
render inertia: 'exemplo/ExemploIndex', props: {
  usuario: current_usuario.as_json,
  tipo_veiculos: tipo_veiculos_options,   # snake_case - NÃO FUNCIONA
  status_options: status_options           # snake_case - NÃO FUNCIONA
}
```

```typescript
// Vue - Props devem corresponder exatamente
interface Props {
  usuario: UserInfo
  tipoVeiculos: SelectOption[]    // deve ser igual ao Rails
  statusOptions: SelectOption[]   // deve ser igual ao Rails
}
```

---

## Diretivas Customizadas

### v-click-outside

Detecta cliques fora de um elemento. Registrada globalmente em `inertia.ts`.

```vue
<div v-click-outside="handleClose">
  <!-- conteúdo -->
</div>
```

**Arquivo**: `app/javascript/vue/directives/v-click-outside.ts`

---

## Componentes Genéricos

### IInput

Input com suporte a múltiplos tipos e formatação automática.

**Import**:
```typescript
import { IInput } from '../../components/IInput'
```

**Props**:
| Prop | Tipo | Default | Descrição |
|------|------|---------|-----------|
| modelValue | `string \| number \| null` | - | Valor (v-model) |
| type | `'text' \| 'number' \| 'date' \| 'money' \| 'cpf_cnpj' \| 'email' \| 'password' \| 'tel'` | `'text'` | Tipo do input |
| label | `string` | - | Label do campo |
| placeholder | `string` | - | Placeholder |
| required | `boolean` | `false` | Campo obrigatório |
| disabled | `boolean` | `false` | Campo desabilitado |
| error | `string` | - | Mensagem de erro |
| maxlength | `number` | - | Máximo de caracteres |

**Exemplo**:
```vue
<IInput
  v-model="form.nome"
  label="Nome"
  placeholder="Digite o nome"
  required
  :error="errors.nome"
/>

<IInput
  v-model="form.cpf"
  type="cpf_cnpj"
  label="CPF/CNPJ"
/>

<IInput
  v-model="form.valor"
  type="money"
  label="Valor"
/>
```

---

### ISelect

Select com suporte a modo single/multiple e pesquisa.

**Import**:
```typescript
import { ISelect } from '../../components/ISelect'
import type { SelectOption } from '../../components/ISelect/types'
```

**Props**:
| Prop | Tipo | Default | Descrição |
|------|------|---------|-----------|
| modelValue | `string \| number \| null \| (string \| number)[]` | - | Valor (v-model) |
| options | `SelectOption[]` | - | Lista de opções |
| mode | `'single' \| 'multiple'` | `'single'` | Modo de seleção |
| label | `string` | - | Label do campo |
| placeholder | `string` | `'Selecione...'` | Placeholder |
| required | `boolean` | `false` | Campo obrigatório |
| disabled | `boolean` | `false` | Campo desabilitado |
| error | `string` | - | Mensagem de erro |
| searchable | `boolean` | `false` | Habilita pesquisa |
| emptyText | `string` | `'Nenhuma opção encontrada'` | Texto quando vazio |

**SelectOption**:
```typescript
interface SelectOption {
  value: string | number
  label: string
  disabled?: boolean
}
```

**Exemplo**:
```vue
<ISelect
  v-model="form.tipo_id"
  label="Tipo"
  :options="tipoOptions"
  placeholder="Selecione um tipo"
  required
  searchable
  :error="errors.tipo_id"
/>
```

---

### IModal

Modal genérico com suporte a slots.

**Import**:
```typescript
import IModal from '../../components/IModal/IModal.vue'
```

**Props**:
| Prop | Tipo | Default | Descrição |
|------|------|---------|-----------|
| modelValue | `boolean` | - | Controla visibilidade (v-model) |
| title | `string` | - | Título do modal |
| size | `'sm' \| 'md' \| 'lg' \| 'xl' \| 'full'` | `'md'` | Tamanho |
| closeOnClickOutside | `boolean` | `true` | Fecha ao clicar fora |
| closeOnEscape | `boolean` | `true` | Fecha com ESC |
| showCloseButton | `boolean` | `true` | Mostra botão X |
| persistent | `boolean` | `false` | Impede fechamento |
| zIndex | `number` | `50` | Z-index |

**Slots**:
- `default`: Conteúdo do modal
- `header`: Header customizado
- `footer`: Footer com botões

**Exemplo**:
```vue
<IModal v-model="modalOpen" title="Meu Modal" size="lg">
  <p>Conteúdo do modal</p>

  <template #footer>
    <button @click="modalOpen = false">Cancelar</button>
    <button @click="salvar">Salvar</button>
  </template>
</IModal>
```

---

### ConfirmationModal

Modal de confirmação para ações destrutivas.

**Import**:
```typescript
import ConfirmationModal from '../../components/ConfirmationModal/ConfirmationModal.vue'
```

**Props**:
| Prop | Tipo | Default | Descrição |
|------|------|---------|-----------|
| modelValue | `boolean` | - | Controla visibilidade (v-model) |
| title | `string` | - | Título |
| message | `string` | - | Mensagem principal |
| confirmText | `string` | `'Confirmar'` | Texto do botão confirmar |
| cancelText | `string` | `'Cancelar'` | Texto do botão cancelar |
| type | `'info' \| 'success' \| 'warning' \| 'danger'` | `'info'` | Tipo visual |
| showIcon | `boolean` | `true` | Mostra ícone |
| zIndex | `number` | `60` | Z-index |

**Eventos**:
- `@confirm`: Emitido ao confirmar
- `@cancel`: Emitido ao cancelar

**Exemplo**:
```vue
<ConfirmationModal
  v-model="confirmOpen"
  title="Remover Item"
  message="Tem certeza que deseja remover este item?"
  confirm-text="Remover"
  type="danger"
  @confirm="handleRemove"
/>
```

---

### DataTable

Tabela com paginação, filtros e ações.

**Import**:
```typescript
import { DataTable } from '../../components/DataTable'
import type { DataTableColumn, DataTableFilter, PaginationConfig } from '../../types/datatable'
```

**Exemplo**:
```vue
<DataTable
  :data="items"
  :columns="columns"
  row-key="id"
  :default-actions="{ edit: true, delete: true }"
  :filters="tableFilters"
  :pagination="pagination"
  :loading="loading"
  @edit="handleEdit"
  @delete="handleDelete"
  @filter="handleFilter"
  @page-change="handlePageChange"
/>
```

---

## Sistema de Branding

O projeto utiliza um sistema de branding dinâmico baseado em **CSS Custom Properties** que permite customização visual por aplicação (EcoEnel, Light, etc.).

### Como Funciona

1. O backend envia configurações de branding via Inertia props (`page.props.branding`)
2. O `BrandingProvider.vue` injeta as CSS variables no `:root`
3. Classes utilitárias de branding aplicam as cores dinamicamente

### Classes de Branding Disponíveis

Use estas classes ao invés de cores fixas:

```css
/* Backgrounds */
.bg-brand-primary        /* Cor primária */
.bg-brand-primary-dark   /* Cor primária escurecida */
.bg-brand-primary-light  /* Cor primária clareada */
.bg-brand-secondary      /* Cor secundária */
.bg-brand-accent         /* Cor de destaque */
.bg-brand-primary\/10    /* Primária com 10% opacidade */
.bg-brand-primary\/20    /* Primária com 20% opacidade */

/* Textos */
.text-brand-primary
.text-brand-primary-dark
.text-brand-secondary
.text-brand-accent

/* Bordas */
.border-brand-primary
.border-brand-secondary

/* Focus/Ring */
.ring-brand-primary
.focus\:ring-brand-primary:focus

/* Hover */
.hover\:bg-brand-primary:hover
.hover\:bg-brand-primary-dark:hover
.hover\:text-brand-primary:hover

/* Accent (checkboxes, radio) */
.accent-brand-primary
```

### Composable useBranding

**Import**:
```typescript
import { useBranding } from '../../composables/useBranding'
```

**Uso**:
```typescript
const { branding, appName, logoUrl, primaryColor, footerText } = useBranding()

// Acessar valores
console.log(appName.value)        // 'AVSI EcoEnel' ou 'AVSI Light'
console.log(primaryColor.value)   // '#006cb6' ou '#008275'
```

### Configuração no Backend

As cores são definidas via ENV no Rails:

```ruby
# config/application.rb ou .env
APP_NAME=AVSI EcoEnel
PRIMARY_COLOR=#006cb6
SECONDARY_COLOR=#10B981
ACCENT_COLOR=#F59E0B
```

### Exemplo de Uso

```vue
<template>
  <!-- Header com cor primária -->
  <header class="bg-brand-primary text-white">
    <h1>{{ appName }}</h1>
  </header>

  <!-- Botão com hover -->
  <button class="bg-brand-primary hover:bg-brand-primary-dark text-white">
    Salvar
  </button>

  <!-- Sidebar -->
  <aside class="bg-brand-primary-dark">
    <nav class="text-white/70 hover:text-white">
      <!-- itens de menu -->
    </nav>
  </aside>

  <!-- Badge de destaque -->
  <span class="bg-brand-accent text-white">Novo</span>
</template>

<script setup>
import { useBranding } from '../../composables/useBranding'
const { appName } = useBranding()
</script>
```

### Arquivos Relacionados

| Arquivo | Descrição |
|---------|-----------|
| `app/javascript/entrypoints/application.css` | CSS variables e classes utilitárias |
| `app/javascript/vue/components/BrandingProvider.vue` | Injeta CSS variables dinamicamente |
| `app/javascript/vue/composables/useBranding.ts` | Composable para acessar branding |

---

## Composables

### useNotifications

Sistema de notificações toast.

**Import**:
```typescript
import { useNotifications } from '../../composables/useNotification'
```

**Uso**:
```typescript
const { success, error, warning, notice } = useNotifications()

// Exibir notificações
success('Operação realizada com sucesso!')
error('Erro ao processar operação')
warning('Atenção: verifique os dados')
notice('Informação importante')

// Com duração customizada (ms)
success('Salvo!', 3000)
```

---

### useOverlay

Gerencia comportamento de overlays (modais, drawers).

**Arquivo**: `app/javascript/vue/composables/useOverlay.ts`

---

### useConfirmation

Hook para confirmações programáticas.

**Arquivo**: `app/javascript/vue/composables/useConfirmation.ts`

---

### useLoading

Loading global com overlay. Já está integrado no `AppLayout`.

**Import**:
```typescript
import { useLoading } from '../../composables/useLoading'
```

**Uso**:
```typescript
const { show, hide, withLoading } = useLoading()

// Mostrar/esconder manualmente
show('Carregando...')
// ... fazer algo
hide()

// Ou usar withLoading para automatizar
await withLoading(async () => {
  await fetchData()
}, 'Buscando dados...')
```

**Exemplo prático (busca de CEP)**:
```typescript
const { show: showLoading, hide: hideLoading } = useLoading()

async function buscarCep() {
  const cep = form.value.cep?.replace(/\D/g, '')
  if (!cep || cep.length !== 8) return

  showLoading('Buscando endereço...')
  try {
    const response = await fetch(`https://viacep.com.br/ws/${cep}/json/`)
    const data = await response.json()
    // preencher campos...
  } finally {
    hideLoading()
  }
}
```

---

## HTTP Client (Axios)

Instância do Axios configurada com CSRF token para requisições AJAX fora do Inertia.

**Arquivo**: `app/javascript/vue/lib/axios.ts`

**Import**:
```typescript
import api from '../../lib/axios'
```

**Uso**:
```typescript
// GET
const response = await api.get('/api/endpoint')

// POST
const response = await api.post('/eventos/1/add_recurso', {
  reciclador_id: 1,
  vigencia_id: 2
})

// DELETE
await api.delete('/eventos/1/remove_recurso', {
  params: { erv_id: 123 }
})
```

O CSRF token é adicionado automaticamente via interceptor.

---

## Funções Utilitárias (utils)

Funções de formatação localizadas em `app/javascript/vue/utils/`. Cada função está em seu próprio arquivo.

**Import**:
```typescript
import { formatCpf, formatCnpj, formatCpfCnpj, formatDate, formatDateTime, formatDateLong, formatPhone, formatMoney, parseMoney } from '../../utils'
```

### formatCpf

Formata CPF para o padrão `000.000.000-00`.

```typescript
formatCpf('12345678900')  // '123.456.789-00'
formatCpf(null)           // ''
```

### formatCnpj

Formata CNPJ para o padrão `00.000.000/0000-00`.

```typescript
formatCnpj('12345678000190')  // '12.345.678/0001-90'
```

### formatCpfCnpj

Detecta automaticamente e formata CPF ou CNPJ.

```typescript
formatCpfCnpj('12345678900')      // '123.456.789-00' (CPF)
formatCpfCnpj('12345678000190')   // '12.345.678/0001-90' (CNPJ)
```

### formatDate / formatDateTime / formatDateLong

Formatação de datas usando **date-fns** com locale pt-BR.

```typescript
formatDate('2025-01-15')           // '15/01/2025'
formatDate(new Date())             // '15/01/2025'
formatDateTime('2025-01-15T14:30') // '15/01/2025 14:30'
formatDateLong('2025-01-15')       // '15 de janeiro de 2025'
```

### formatPhone

Formata telefone para padrão brasileiro.

```typescript
formatPhone('1134567890')   // '(11) 3456-7890'
formatPhone('11987654321')  // '(11) 98765-4321'
```

### formatMoney / parseMoney

Formata e converte valores monetários.

```typescript
formatMoney(1234.56)              // 'R$ 1.234,56'
formatMoney(1234.56, false)       // '1.234,56'
parseMoney('R$ 1.234,56')         // 1234.56
```

---

## Estrutura de Páginas (CRUD)

### Controller Rails

```ruby
class ContratosController < ApplicationController
  before_action :set_contrato, only: [:edit, :update, :destroy]

  def index
    @contratos = Contrato.includes(:contrato_tipo, :cliente)
    render inertia: 'contratos/ContratosIndex', props: {
      contratos: @contratos.map { |c| contrato_as_json(c) },
      # ...
    }
  end

  def new
    render inertia: 'contratos/ContratosForm', props: {
      contrato: nil,
      # ...
    }
  end

  def edit
    render inertia: 'contratos/ContratosForm', props: {
      contrato: contrato_as_json(@contrato),
      # ...
    }
  end

  # ...
end
```

### Página Index (Vue)

```vue
<template>
  <Head title="Contratos" />
  <AppLayout :usuario="usuario">
    <DataTable ... />
    <ConfirmationModal ... />
  </AppLayout>
</template>

<script setup lang="ts">
import { Head, Link, router } from '@inertiajs/vue3'
import AppLayout from '../../layouts/AppLayout.vue'
import { DataTable } from '../../components/DataTable'
import ConfirmationModal from '../../components/ConfirmationModal/ConfirmationModal.vue'
// ...
</script>
```

### Página Form (Vue)

```vue
<template>
  <Head :title="isEditing ? 'Editar' : 'Novo'" />
  <AppLayout :usuario="usuario">
    <form @submit.prevent="handleSubmit">
      <IInput v-model="form.campo" label="Campo" />
      <ISelect v-model="form.tipo_id" :options="options" />
      <!-- ... -->
    </form>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { Head, Link, router } from '@inertiajs/vue3'
import AppLayout from '../../layouts/AppLayout.vue'
import { IInput } from '../../components/IInput'
import { ISelect } from '../../components/ISelect'
// ...
</script>
```

---

## Checklist para Novos CRUDs

1. [ ] Criar/verificar Model Rails
2. [ ] Criar Controller com actions: index, new, create, edit, update, destroy
3. [ ] Adicionar rotas em `config/routes.rb`
4. [ ] Criar página `{Entity}Index.vue` (CamelCase!)
5. [ ] Criar página `{Entity}Form.vue` (CamelCase!)
6. [ ] Usar componentes genéricos: IInput, ISelect, DataTable, ConfirmationModal
7. [ ] Usar useNotifications para feedback ao usuário
