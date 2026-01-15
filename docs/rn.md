# SGICI - Regras de Negócio
## Sistema de Gestão de Importações, Custos e Indicadores

---

## Introdução: A Jornada da Importação

Imagine uma empresa que precisa trazer produtos da China ou dos Estados Unidos. Esse processo não é simples como uma compra no e-commerce: envolve negociação com fornecedores estrangeiros, contratação de frete internacional, seguro da carga, desembaraço aduaneiro, impostos federais e estaduais, armazenagem, transporte nacional... e cada etapa tem seu custo e seu prazo.

Hoje, muitas empresas gerenciam isso em **planilhas Excel espalhadas**, perdendo o histórico, sem visão consolidada dos custos reais versus previstos, e sem indicadores para saber se estão tomando as melhores decisões.

O **SGICI** funciona como um **"diário de bordo digital"** para cada processo de importação: desde o momento em que você planeja trazer uma carga até o momento em que ela chega ao seu armazém e você fecha as contas. Cada processo tem seu número único, seus custos previstos e reais, suas datas planejadas e efetivas, e o sistema calcula automaticamente os indicadores que mostram se você está no caminho certo.

---

## Os Personagens da História

### O Administrador
> "O guardião do sistema"

O Administrador é quem configura e governa o SGICI. Ele gerencia quem tem acesso, quais permissões cada usuário possui, e mantém os parâmetros do sistema atualizados (como taxas de câmbio, alíquotas de impostos, cadastros de fornecedores e prestadores).

**Responsabilidades:**
- Cadastrar e gerenciar usuários do sistema
- Definir perfis de acesso (quem vê o quê, quem pode editar)
- Manter cadastro de fornecedores internacionais
- Manter cadastro de prestadores de serviço (freight forwarders, despachantes, seguradoras, transportadoras, armazéns)
- Configurar parâmetros do sistema (taxas, alíquotas, moedas)
- Auditar quem fez a última modificação em cada módulo

**Regras:**
1. Apenas o Administrador pode criar novos usuários
2. Apenas o Administrador pode alterar perfis de acesso
3. Cadastros de fornecedores/prestadores devem ter CNPJ ou identificação fiscal do país de origem
4. Toda alteração de parâmetros críticos (taxas, alíquotas) deve ser registrada com data e responsável

---

### O Operacional
> "O piloto do processo"

O Operacional é quem está no dia a dia das importações. Ele cria os processos, registra os custos (previstos e reais), atualiza as datas e eventos logísticos, e mantém o processo vivo e atualizado do início ao fim.

**Responsabilidades:**
- Criar novos processos de importação
- Cadastrar custos previstos (orçamentos)
- Registrar custos reais conforme faturas chegam
- Atualizar eventos logísticos (embarque, chegada, desembaraço)
- Alterar status do processo conforme ele avança
- Lançar ocorrências e observações

**Regras:**
1. Todo processo deve ter no mínimo: número único, fornecedor, país de origem, modal de transporte, incoterm
2. Não pode avançar o status de um processo sem preencher dados obrigatórios da etapa anterior
3. Custos reais só podem ser lançados após o processo estar em status "Em Trânsito" ou superior
4. Eventos logísticos devem seguir a ordem cronológica (data de embarque < data de chegada)
5. Registra-se automaticamente **quem** e **quando** cada modificação foi feita

---

### O Gestor
> "O estrategista"

O Gestor não fica no operacional, mas precisa de visão consolidada. Ele analisa indicadores, compara custos previstos versus reais, avalia desempenho de fornecedores e rotas, e toma decisões estratégicas baseadas em dados históricos confiáveis.

**Responsabilidades:**
- Consultar dashboard de indicadores (KPIs)
- Analisar desvios de custo e prazo
- Comparar rotas e modais (qual é mais econômico?)
- Avaliar fornecedores (quem cumpre prazos? quem tem menor custo total?)
- Exportar relatórios gerenciais
- Aprovar processos planejados (se houver fluxo de aprovação)

**Regras:**
1. Gestor tem acesso read-only aos processos (não edita dados operacionais diretamente)
2. Gestor pode exportar dados para análises externas
3. Gestor pode aprovar ou rejeitar processos em status "Planejado" (se fluxo de aprovação estiver ativo)
4. Dashboard mostra apenas processos finalizados e em andamento (não mostra rascunhos)

---

## Os Documentos/Entidades

### Processo de Importação - PI
> "O personagem principal da história"

Um Processo de Importação (PI) representa uma carga que está sendo trazida do exterior. Cada PI tem um **número único**, e esse número o acompanha do início ao fim, como um passaporte.

**Ciclo de Vida:**

```
┌─────────────┐
│  PLANEJADO  │  ← Processo criado, aguardando validação/aprovação
└──────┬──────┘
       │ [aprovar]
       ▼
┌─────────────┐
│  APROVADO   │  ← Processo validado, pode iniciar operação
└──────┬──────┘
       │ [embarcar carga]
       ▼
┌─────────────┐
│ EM TRÂNSITO │  ← Carga embarcada, em viagem
└──────┬──────┘
       │ [desembaraçar]
       ▼
┌─────────────┐
│DESEMBARAÇADO│  ← Liberado pela Receita Federal
└──────┬──────┘
       │ [entregar + fechar custos]
       ▼
┌─────────────┐
│ FINALIZADO  │  ← Processo concluído, custos finais apurados
└─────────────┘
```

**Status Explicados:**
- **Planejado**: Processo criado, ainda não começou. Pode ser editado livremente. Custos são apenas previsões.
- **Aprovado**: Processo validado pelo gestor (se houver fluxo de aprovação). Pronto para iniciar operação.
- **Em Trânsito**: Carga embarcada e a caminho. Eventos logísticos começam a ser registrados. Custos reais começam a ser lançados.
- **Desembaraçado**: Carga liberada pela aduana. Impostos de importação já foram pagos. Falta apenas transporte nacional e entrega final.
- **Finalizado**: Processo concluído. Todos os custos reais foram lançados. Não pode mais ser editado (apenas consulta). Entra nos indicadores históricos.

**Campos Importantes:**

| Campo | Descrição | Regra |
|-------|-----------|-------|
| numero | Número único do processo | Obrigatório, único no sistema |
| fornecedor_id | Fornecedor internacional | Obrigatório |
| pais_origem | País de origem da carga | Obrigatório |
| porto_origem / aeroporto_origem | Local de embarque | Obrigatório conforme modal |
| porto_destino / aeroporto_destino | Local de chegada no Brasil | Obrigatório conforme modal |
| modal | Marítimo, Aéreo ou Rodoviário | Obrigatório |
| incoterm | EXW, FOB, CIF, DDP, etc. | Obrigatório (define responsabilidades) |
| moeda | USD, EUR, CNY, etc. | Obrigatório |
| taxa_cambio_prevista | Taxa de câmbio estimada | Obrigatório para cálculos |
| taxa_cambio_real | Taxa de câmbio efetiva | Preenchido ao finalizar |
| valor_fob_previsto | Valor FOB orçado | Obrigatório |
| valor_fob_real | Valor FOB efetivo | Preenchido ao finalizar |
| data_embarque_prevista | Data planejada de embarque | Obrigatório |
| data_embarque_real | Data efetiva de embarque | Preenchido pelo Operacional |
| data_chegada_prevista | Data planejada de chegada | Obrigatório |
| data_chegada_real | Data efetiva de chegada | Preenchido pelo Operacional |
| eta | Estimated Time of Arrival | Atualizado dinamicamente |
| usuario_ultima_modificacao | Quem mexeu por último | Automático (auditoria) |
| data_ultima_modificacao | Quando foi modificado | Automático (auditoria) |

---

### Fornecedor Internacional
> "Quem vende para você no exterior"

Empresa ou pessoa que fabrica/vende os produtos no país de origem.

**Campos:**
- Nome/Razão Social
- País
- CNPJ/Tax ID (identificação fiscal)
- Endereço completo
- Contatos (email, telefone)
- Histórico de processos (quantos PIs já foram feitos com este fornecedor)

**Regras:**
1. CNPJ/Tax ID obrigatório
2. País obrigatório
3. Não pode excluir fornecedor com processos ativos vinculados

---

### Prestador de Serviço
> "Quem ajuda você a trazer a carga"

Empresas que prestam serviços na cadeia de importação. Podem ser de vários tipos:

**Tipos de Prestadores:**
- **Freight Forwarder**: Agente de carga, organiza o transporte internacional
- **Despachante Aduaneiro**: Faz o desembaraço na Receita Federal
- **Seguradora**: Fornece seguro da carga
- **Transportadora Nacional**: Faz transporte interno no Brasil
- **Armazém**: Armazena a carga temporariamente
- **Outros**: Serviços auxiliares (classificação fiscal, inspeção, etc.)

**Campos:**
- Nome/Razão Social
- CNPJ
- Tipo de Prestador
- Endereço
- Contatos
- Observações

**Regras:**
1. CNPJ obrigatório
2. Tipo de Prestador obrigatório
3. Um processo pode ter múltiplos prestadores de tipos diferentes
4. Não pode ter dois prestadores do mesmo tipo principal (ex: dois despachantes) no mesmo processo

---

### Custo Previsto
> "O orçamento do processo"

São os custos que você **espera ter** antes de iniciar a importação. É o orçamento inicial.

**Categorias de Custos Previstos:**

| Categoria | Descrição | Exemplo |
|-----------|-----------|---------|
| FOB | Valor da mercadoria + custos até embarque | US$ 50.000 |
| Frete Internacional | Transporte internacional | US$ 5.000 (marítimo) |
| Seguro Internacional | Seguro da carga | US$ 500 (1% do FOB) |
| Taxas Origem | Taxas no país de origem | US$ 200 |
| II (Imposto Importação) | Alíquota sobre (FOB + Frete + Seguro) | 14% = R$ 35.000 |
| IPI | Imposto sobre Produtos Industrializados | 10% = R$ 10.000 |
| PIS/COFINS | Impostos federais | 9,65% = R$ 8.000 |
| ICMS | Imposto estadual | 18% = R$ 20.000 |
| Despachante | Taxa do despachante aduaneiro | R$ 2.500 |
| Armazenagem | Armazém alfandegado | R$ 1.000 |
| Capatazia | Movimentação de carga | R$ 800 |
| Transporte Nacional | Frete do porto até empresa | R$ 3.000 |
| Outros | Custos diversos | R$ 500 |

**Regras:**
1. FOB previsto é obrigatório
2. Impostos (II, IPI, PIS/COFINS, ICMS) são calculados automaticamente com base nas alíquotas configuradas no sistema
3. Soma total dos custos previstos = **Custo Total Previsto**
4. Sistema converte automaticamente valores em moeda estrangeira para BRL usando a taxa de câmbio prevista

---

### Custo Real
> "O que você realmente gastou"

São os custos **efetivos** que vão sendo lançados conforme as faturas chegam. É a realidade versus o orçamento.

**Categorias (mesmas do Custo Previsto):**
- FOB real
- Frete Internacional real
- Seguro real
- Taxas origem reais
- II, IPI, PIS/COFINS, ICMS reais (conforme DI - Declaração de Importação)
- Despachante real
- Armazenagem real
- Capatazia real
- Transporte nacional real
- Extras não previstos

**Regras:**
1. Custos reais só podem ser lançados quando processo estiver em status "Em Trânsito" ou superior
2. Deve ser informado o número da fatura/nota fiscal para cada custo real
3. Sistema calcula automaticamente o **desvio** (real - previsto) para cada categoria
4. Soma total dos custos reais = **Custo Total Real**
5. Se um custo real for lançado e não havia previsão, o desvio será 100% sobre o previsto (zero)

---

### Evento Logístico
> "O diário de bordo da carga"

Registros de datas e marcos importantes do processo.

**Principais Eventos:**

| Evento | Descrição | Regra |
|--------|-----------|-------|
| Data Embarque | Carga embarcou no país de origem | Muda status para "Em Trânsito" |
| ETA (Estimated Time of Arrival) | Previsão de chegada (atualizada dinamicamente) | Atualizado pelo freight forwarder |
| Data Chegada Porto/Aeroporto | Carga chegou no Brasil | Registrado pelo Operacional |
| Data Início Desembaraço | Iniciou processo na Receita Federal | Registrado pelo despachante |
| Data Fim Desembaraço | Liberado pela aduana | Muda status para "Desembaraçado" |
| Data Entrega Final | Carga entregue no destino final | Pré-requisito para "Finalizado" |

**Regras:**
1. Eventos devem seguir ordem cronológica (data embarque < data chegada < data desembaraço < data entrega)
2. Sistema alerta se houver inconsistência de datas
3. ETA pode ser atualizado múltiplas vezes (é uma estimativa dinâmica)
4. Registro de atrasos é automático: se data_real > data_prevista, calcula dias de atraso

---

### Ocorrência
> "Os imprevistos do caminho"

Registro de problemas, observações ou eventos inesperados durante o processo.

**Campos:**
- Data/hora da ocorrência
- Tipo (Atraso, Avaria, Extravio, Inspeção, Documentação, Outros)
- Descrição detalhada
- Impacto (Alto, Médio, Baixo)
- Responsável pelo registro
- Status (Aberta, Em tratamento, Resolvida)

**Exemplos:**
- "Navio atrasou 5 dias por condições climáticas no porto de Xangai"
- "Documentação fiscal rejeitada pela Receita - falta classificação NCM"
- "Container avariado durante transbordo - seguradora acionada"

**Regras:**
1. Toda ocorrência com impacto Alto deve notificar o Gestor
2. Ocorrências abertas impedem finalização do processo
3. Sistema sugere criar ocorrência automaticamente quando detecta atraso > 7 dias

---

## Fluxos de Negócio

### Fluxo 1: Criação e Planejamento de um Processo

**Pré-requisitos:**
- Usuário deve ter perfil Operacional ou superior
- Fornecedor deve estar cadastrado no sistema
- Prestadores de serviço devem estar cadastrados

**Passos:**

1. **Operacional** acessa "Novo Processo de Importação"
2. **Sistema** solicita dados obrigatórios:
   - Número do processo (único)
   - Fornecedor
   - País de origem
   - Modal de transporte
   - Incoterm
   - Porto/Aeroporto origem e destino
   - Moeda e taxa de câmbio prevista
   - Valor FOB previsto
   - Datas previstas (embarque, chegada)
3. **Operacional** preenche os dados
4. **Sistema** valida:
   - Número do processo não existe ainda
   - Fornecedor está ativo
   - Datas previstas são futuras (ou no máximo hoje)
   - Taxa de câmbio > 0
   - Valor FOB > 0
5. **Operacional** adiciona custos previstos:
   - FOB (já preenchido)
   - Frete internacional
   - Seguro
   - Taxas origem
6. **Sistema** calcula automaticamente:
   - Impostos (II, IPI, PIS/COFINS, ICMS) com base nas alíquotas configuradas
   - Conversão para BRL usando taxa de câmbio prevista
   - **Custo Total Previsto**
7. **Operacional** adiciona custos nacionais previstos:
   - Despachante
   - Armazenagem
   - Capatazia
   - Transporte nacional
8. **Sistema** salva o processo com status **PLANEJADO**
9. **Sistema** registra auditoria: quem criou, quando

**Diagrama:**

```
[Operacional] ──▶ [Preenche Dados] ──▶ [Sistema Valida] ──▶ [Calcula Custos] ──▶ [Salva PI]
                                              │
                                              ▼
                                        [Se erro: exibe mensagens]
```

**Exceções:**
- Se número do processo já existe: "Processo já cadastrado no sistema"
- Se fornecedor não está ativo: "Fornecedor inativo, favor verificar cadastro"
- Se datas inválidas: "Data de embarque prevista deve ser anterior à data de chegada"

---

### Fluxo 2: Aprovação do Processo (Opcional)

**Pré-requisitos:**
- Processo deve estar em status PLANEJADO
- Sistema deve ter fluxo de aprovação habilitado
- Usuário deve ter perfil Gestor

**Passos:**

1. **Gestor** acessa lista de processos pendentes de aprovação
2. **Sistema** exibe processos em status PLANEJADO
3. **Gestor** seleciona um processo e revisa:
   - Dados do fornecedor
   - Custos previstos
   - Viabilidade econômica
4. **Gestor** pode:
   - **Aprovar**: muda status para APROVADO
   - **Rejeitar**: volta para Operacional com observações
   - **Solicitar ajustes**: mantém PLANEJADO mas envia notificação ao Operacional
5. **Sistema** registra decisão do Gestor (quem, quando, motivo)
6. **Sistema** notifica Operacional da decisão

**Diagrama:**

```
[PI Planejado] ──▶ [Gestor Revisa] ──┬──▶ [Aprovado] ──▶ [Status: APROVADO]
                                      │
                                      └──▶ [Rejeitado] ──▶ [Notifica Operacional]
```

**Exceções:**
- Se processo já foi aprovado: "Processo já foi aprovado anteriormente"
- Se processo foi alterado após envio: "Processo foi modificado, favor revisar novamente"

---

### Fluxo 3: Registro de Embarque e Início do Trânsito

**Pré-requisitos:**
- Processo deve estar em status APROVADO (ou PLANEJADO se não houver fluxo de aprovação)
- Data de embarque prevista deve estar próxima

**Passos:**

1. **Operacional** recebe aviso do freight forwarder: "Carga embarcou"
2. **Operacional** acessa o processo e registra:
   - Data de embarque real
   - Número do container / AWB (Air Waybill) / Placa do caminhão (conforme modal)
   - ETA inicial (estimativa de chegada)
3. **Sistema** valida:
   - Data de embarque real <= data atual
   - Data de embarque real <= ETA
4. **Sistema** altera status para **EM TRÂNSITO**
5. **Sistema** compara data_embarque_real vs data_embarque_prevista:
   - Se atrasou: calcula dias de atraso e sugere criar ocorrência
   - Se adiantou: registra (pode impactar custos de armazenagem na chegada)
6. **Sistema** libera lançamento de custos reais
7. **Sistema** registra auditoria

**Diagrama:**

```
[Freight Forwarder] ──▶ [Avisa Embarque] ──▶ [Operacional Registra] ──▶ [Status: EM TRÂNSITO]
                                                      │
                                                      ▼
                                               [Se atraso > 2 dias]
                                                      │
                                                      ▼
                                              [Sugere criar ocorrência]
```

**Exceções:**
- Se data de embarque > data atual: "Data de embarque não pode ser futura"
- Se data de embarque > ETA: "Data de embarque deve ser anterior à previsão de chegada"

---

### Fluxo 4: Registro de Chegada e Desembaraço

**Pré-requisitos:**
- Processo deve estar em status EM TRÂNSITO
- Carga deve ter chegado ao porto/aeroporto brasileiro

**Passos:**

1. **Operacional** recebe aviso: "Carga chegou no Porto de Santos"
2. **Operacional** registra:
   - Data de chegada real
   - Local de chegada (confirmação)
3. **Sistema** valida data de chegada
4. **Sistema** compara com data_chegada_prevista e ETA:
   - Calcula desvio de prazo
   - Se atraso > 7 dias: cria ocorrência automaticamente
5. **Despachante** inicia desembaraço aduaneiro (fora do sistema, mas coordenado)
6. **Operacional** registra:
   - Data início desembaraço
   - Número da DI (Declaração de Importação)
7. **Sistema** aguarda liberação da Receita Federal
8. **Operacional** registra:
   - Data fim desembaraço
   - Valores dos impostos efetivos (conforme DI)
9. **Sistema** lança automaticamente custos reais dos impostos
10. **Sistema** altera status para **DESEMBARAÇADO**
11. **Sistema** calcula desvio de impostos: real vs previsto

**Diagrama:**

```
[Carga Chega] ──▶ [Operacional Registra Chegada] ──▶ [Despachante Inicia]
                                                             │
                                                             ▼
                                                    [Receita Federal]
                                                             │
                                                             ▼
                                               [Operacional Registra Liberação]
                                                             │
                                                             ▼
                                                [Status: DESEMBARAÇADO]
```

**Exceções:**
- Se data de chegada < data de embarque: "Data de chegada deve ser posterior ao embarque"
- Se DI não informada: "Número da DI é obrigatório para registrar desembaraço"

---

### Fluxo 5: Entrega Final e Finalização do Processo

**Pré-requisitos:**
- Processo deve estar em status DESEMBARAÇADO
- Todos os custos reais principais devem estar lançados
- Carga deve ter sido entregue no destino final

**Passos:**

1. **Operacional** registra:
   - Data de entrega final
   - Local de entrega
   - Responsável pelo recebimento
2. **Operacional** lança custos reais finais:
   - Frete nacional efetivo
   - Armazenagem efetiva
   - Capatazia efetiva
   - Extras (se houver)
3. **Sistema** valida:
   - Todos os custos reais principais foram lançados
   - Todas as ocorrências abertas foram resolvidas
   - Datas estão consistentes
4. **Operacional** solicita finalizar processo
5. **Sistema** calcula:
   - **Custo Total Real**
   - **Desvio Total**: (Custo Real - Custo Previsto) / Custo Previsto * 100
   - **Lead Time Real**: data_entrega_final - data_embarque_real
   - **Desvio de Prazo**: Lead Time Real - Lead Time Previsto
6. **Sistema** altera status para **FINALIZADO**
7. **Sistema** trava o processo (não pode mais ser editado, apenas consulta)
8. **Sistema** adiciona processo aos indicadores históricos
9. **Sistema** dispara notificação ao Gestor: "Processo X finalizado com desvio de Y%"

**Diagrama:**

```
[Carga Entregue] ──▶ [Operacional Lança Custos Finais] ──▶ [Solicita Finalizar]
                                                                   │
                                                                   ▼
                                                        [Sistema Valida Completude]
                                                                   │
                                                                   ▼
                                                          [Calcula Indicadores]
                                                                   │
                                                                   ▼
                                                         [Status: FINALIZADO]
                                                                   │
                                                                   ▼
                                                        [Notifica Gestor]
```

**Exceções:**
- Se custos principais faltando: "Faltam lançar custos reais de: Frete Internacional, Seguro"
- Se ocorrências abertas: "Existem 2 ocorrências abertas. Favor resolver antes de finalizar."
- Se datas inconsistentes: "Data de entrega deve ser posterior ao desembaraço"

---

### Fluxo 6: Consulta de Indicadores pelo Gestor

**Pré-requisitos:**
- Usuário deve ter perfil Gestor
- Deve haver pelo menos 1 processo finalizado no sistema

**Passos:**

1. **Gestor** acessa Dashboard de Indicadores
2. **Sistema** exibe visão consolidada:
   - Total de processos (por status)
   - Processos finalizados no último mês/trimestre/ano
   - Valor total importado (BRL)
   - Desvio médio de custo (%)
   - Desvio médio de prazo (dias)
3. **Gestor** pode filtrar por:
   - Período (data)
   - Fornecedor
   - País de origem
   - Modal
   - Status
4. **Sistema** exibe gráficos:
   - **Composição de Custos**: quanto % é FOB, frete, impostos, etc.
   - **Desvio Previsto x Real**: comparação visual por processo
   - **Lead Time Médio por Rota**: comparação entre China-Santos, EUA-Guarulhos, etc.
   - **Custo por Unidade**: se informado peso/volume/qtd, calcula custo unitário
5. **Gestor** pode perfurar (drill-down) em qualquer indicador para ver detalhes
6. **Gestor** pode exportar para Excel/PDF

**Principais KPIs Calculados:**

| KPI | Fórmula | Interpretação |
|-----|---------|---------------|
| % Custo Logístico sobre FOB | (Frete + Seguro + Custos Nacionais) / FOB * 100 | Quanto % o frete/logística representa do valor da mercadoria |
| Desvio de Custo | (Custo Real - Custo Previsto) / Custo Previsto * 100 | Se positivo: gastou mais que previsto. Se negativo: economizou. |
| Lead Time Médio | Média de (data_entrega_final - data_embarque_real) | Quantos dias em média leva cada rota |
| Custo por Container | Custo Total Real / Quantidade de Containers | Comparar viabilidade entre processos |
| Taxa de Processos no Prazo | Processos sem atraso / Total de Processos * 100 | % de processos que chegaram no prazo |

**Diagrama:**

```
[Gestor] ──▶ [Acessa Dashboard] ──▶ [Sistema Calcula KPIs] ──▶ [Exibe Gráficos]
                    │
                    ├──▶ [Filtrar por Período]
                    │
                    ├──▶ [Filtrar por Fornecedor]
                    │
                    └──▶ [Exportar Relatório]
```

---

## Regras de Validação

### RN001 - Número Único de Processo
**Contexto:** Ao criar ou editar um processo de importação
**Regra:** O número do processo deve ser único no sistema. Não pode haver dois processos com o mesmo número.
**Validação:** Sistema verifica no banco de dados antes de salvar. Se já existir, exibe erro: "Número de processo já cadastrado."

---

### RN002 - Datas Cronológicas
**Contexto:** Ao registrar eventos logísticos
**Regra:** As datas devem seguir ordem cronológica:
- data_embarque_real <= data_chegada_real
- data_chegada_real <= data_desembaraço_inicio
- data_desembaraço_inicio <= data_desembaraço_fim
- data_desembaraço_fim <= data_entrega_final

**Validação:** Sistema valida ao salvar cada evento. Se houver inconsistência, exibe erro: "Data de chegada não pode ser anterior ao embarque."

---

### RN003 - Custos Reais Apenas Após Embarque
**Contexto:** Ao lançar custos reais
**Regra:** Custos reais só podem ser lançados quando o processo estiver em status "Em Trânsito" ou superior.
**Validação:** Sistema desabilita campos de custos reais se status = PLANEJADO ou APROVADO. Se tentar burlar via API, retorna erro 403.

---

### RN004 - Cálculo Automático de Impostos
**Contexto:** Ao preencher custos previstos
**Regra:** Impostos (II, IPI, PIS/COFINS, ICMS) são calculados automaticamente com base nas alíquotas configuradas no sistema. Usuário não edita manualmente.
**Validação:** Campos de impostos previstos são read-only. Sistema recalcula automaticamente quando FOB, frete ou seguro mudam.

**Fórmula:**
```
Base de Cálculo = (FOB + Frete Internacional + Seguro) * Taxa de Câmbio
II = Base de Cálculo * Alíquota II
IPI = (Base de Cálculo + II) * Alíquota IPI
PIS/COFINS = Base de Cálculo * Alíquota PIS/COFINS
ICMS = (Base de Cálculo + II + IPI + PIS/COFINS) / (1 - Alíquota ICMS) * Alíquota ICMS
```

---

### RN005 - Fornecedor Ativo
**Contexto:** Ao criar um processo de importação
**Regra:** O fornecedor selecionado deve estar com status ATIVO no cadastro.
**Validação:** Sistema filtra apenas fornecedores ativos no dropdown. Se fornecedor for desativado após processo criado, processo não é afetado (mantém referência).

---

### RN006 - Finalização Completa
**Contexto:** Ao tentar finalizar um processo
**Regra:** Para finalizar, o processo deve ter:
- Status = DESEMBARAÇADO
- Data de entrega final preenchida
- Custos reais principais lançados (FOB, Frete, Seguro, Impostos)
- Todas as ocorrências abertas resolvidas

**Validação:** Sistema exibe checklist antes de finalizar. Se faltarem itens, não permite finalizar e mostra mensagem: "Faltam lançar custos reais de: Frete Internacional, Seguro."

---

### RN007 - Auditoria de Modificações
**Contexto:** Qualquer alteração em um processo
**Regra:** Sistema deve registrar automaticamente:
- Quem fez a modificação (usuário)
- Quando foi modificado (timestamp)
- Qual campo foi alterado (se possível, histórico de mudanças)

**Validação:** Campos de auditoria são automáticos e invisíveis ao usuário. Gestor e Administrador podem consultar log de auditoria.

---

### RN008 - Conversão de Moeda
**Contexto:** Ao calcular custos em BRL
**Regra:** Todos os custos em moeda estrangeira devem ser convertidos para BRL usando:
- **Taxa de Câmbio Prevista** para custos previstos
- **Taxa de Câmbio Real** (se informada) para custos reais, ou Taxa Prevista como fallback

**Validação:** Sistema não permite taxa de câmbio <= 0. Se taxa não informada, usa taxa PTAX do Banco Central da data do embarque (integração futura).

---

### RN009 - Incoterm Define Responsabilidades
**Contexto:** Ao definir custos previstos
**Regra:** O Incoterm selecionado determina quem paga cada custo:
- **EXW** (Ex Works): Comprador paga tudo (frete, seguro, impostos)
- **FOB** (Free On Board): Comprador paga frete internacional, seguro e importação
- **CIF** (Cost, Insurance, Freight): Vendedor paga frete e seguro até destino; comprador paga impostos
- **DDP** (Delivered Duty Paid): Vendedor paga tudo, inclusive impostos

**Validação:** Sistema sugere campos a preencher conforme Incoterm. Ex: se CIF, frete e seguro já estão inclusos no FOB (não lançar separado).

---

### RN010 - Modal Define Locais de Origem/Destino
**Contexto:** Ao criar processo
**Regra:** Conforme modal escolhido:
- **Marítimo**: Obrigatório informar porto_origem e porto_destino
- **Aéreo**: Obrigatório informar aeroporto_origem e aeroporto_destino
- **Rodoviário**: Obrigatório informar fronteira_origem e cidade_destino

**Validação:** Sistema exibe campos condicionais conforme modal selecionado. Se tentar salvar sem preencher, exibe erro: "Porto de origem é obrigatório para modal marítimo."

---

### RN011 - Desvio de Custo > 10% Alerta Gestor
**Contexto:** Ao finalizar um processo
**Regra:** Se o desvio de custo (real vs previsto) for maior que 10% (para cima ou para baixo), sistema envia notificação automática ao Gestor.
**Validação:** Sistema calcula desvio ao finalizar. Se |desvio| > 10%, cria notificação: "Processo X finalizado com desvio de +15%. Revisar orçamento."

---

### RN012 - Atraso > 7 Dias Cria Ocorrência
**Contexto:** Ao registrar data de chegada real
**Regra:** Se data_chegada_real - data_chegada_prevista > 7 dias, sistema sugere criar ocorrência automaticamente.
**Validação:** Sistema exibe modal: "Detectado atraso de 10 dias. Deseja criar uma ocorrência?" [Sim] [Não]

---

### RN013 - Prestador Único por Tipo Principal
**Contexto:** Ao adicionar prestadores ao processo
**Regra:** Um processo não pode ter dois prestadores do mesmo tipo principal (ex: dois despachantes, dois freight forwarders).
**Validação:** Sistema valida ao adicionar prestador. Se já houver um do mesmo tipo, exibe erro: "Já existe um Despachante Aduaneiro vinculado a este processo."

---

### RN014 - Gestor Não Edita Dados Operacionais
**Contexto:** Ao acessar um processo
**Regra:** Usuários com perfil Gestor têm acesso read-only aos dados operacionais. Podem apenas aprovar/rejeitar processos planejados e consultar indicadores.
**Validação:** Sistema desabilita todos os campos de edição para perfil Gestor. Apenas Operacional e Administrador podem editar.

---

### RN015 - Processo Finalizado É Imutável
**Contexto:** Ao tentar editar um processo finalizado
**Regra:** Processos com status FINALIZADO não podem ser editados. Apenas consulta é permitida.
**Validação:** Sistema desabilita todos os botões de edição. Se tentar editar via API, retorna erro 403: "Processo finalizado não pode ser alterado."

---

## Cálculos Automáticos

### 1. Custo Total Previsto (em BRL)

```
Custo_Total_Previsto_BRL =
  (FOB_Previsto + Frete_Internacional_Previsto + Seguro_Previsto + Taxas_Origem) * Taxa_Cambio_Prevista
  + II_Previsto
  + IPI_Previsto
  + PIS_COFINS_Previsto
  + ICMS_Previsto
  + Despachante_Previsto
  + Armazenagem_Prevista
  + Capatazia_Prevista
  + Transporte_Nacional_Previsto
  + Outros_Previstos
```

### 2. Custo Total Real (em BRL)

```
Custo_Total_Real_BRL =
  (FOB_Real + Frete_Internacional_Real + Seguro_Real + Taxas_Origem_Real) * Taxa_Cambio_Real
  + II_Real
  + IPI_Real
  + PIS_COFINS_Real
  + ICMS_Real
  + Despachante_Real
  + Armazenagem_Real
  + Capatazia_Real
  + Transporte_Nacional_Real
  + Extras_Real
```

### 3. Desvio de Custo (%)

```
Desvio_Custo_Percentual = ((Custo_Total_Real - Custo_Total_Previsto) / Custo_Total_Previsto) * 100
```

**Interpretação:**
- Positivo: Gastou mais que o previsto (ex: +15% = gastou 15% a mais)
- Negativo: Economizou (ex: -5% = gastou 5% a menos)
- Zero: Dentro do orçamento

### 4. Lead Time (dias)

```
Lead_Time_Previsto = data_chegada_prevista - data_embarque_prevista
Lead_Time_Real = data_entrega_final - data_embarque_real
Desvio_Lead_Time_Dias = Lead_Time_Real - Lead_Time_Previsto
```

### 5. % Custo Logístico sobre FOB

```
Percentual_Custo_Logistico =
  ((Frete_Internacional_Real + Seguro_Real + Transporte_Nacional_Real + Armazenagem_Real + Capatazia_Real) / (FOB_Real * Taxa_Cambio_Real)) * 100
```

**Interpretação:** Quanto % o custo logístico representa do valor da mercadoria. Ex: se FOB = R$ 100.000 e custo logístico = R$ 15.000, então 15%.

### 6. Custo por Container / Unidade

```
Custo_por_Container = Custo_Total_Real / Quantidade_Containers
Custo_por_Kg = Custo_Total_Real / Peso_Total_Kg
Custo_por_m3 = Custo_Total_Real / Volume_Total_m3
```

### 7. Impostos Calculados (Previstos)

**Base de Cálculo:**
```
Base_Calculo_BRL = (FOB + Frete_Internacional + Seguro) * Taxa_Cambio_Prevista
```

**II (Imposto de Importação):**
```
II = Base_Calculo_BRL * Aliquota_II
```

**IPI (Imposto sobre Produtos Industrializados):**
```
IPI = (Base_Calculo_BRL + II) * Aliquota_IPI
```

**PIS/COFINS:**
```
PIS_COFINS = Base_Calculo_BRL * Aliquota_PIS_COFINS
```

**ICMS (por dentro):**
```
ICMS = ((Base_Calculo_BRL + II + IPI + PIS_COFINS) / (1 - Aliquota_ICMS)) * Aliquota_ICMS
```

---

## Notificações Automáticas

O sistema envia notificações automáticas nos seguintes casos:

| Evento | Destinatário | Mensagem |
|--------|--------------|----------|
| Processo criado | Gestor | "Novo processo X aguardando aprovação" |
| Processo aprovado | Operacional | "Processo X foi aprovado pelo Gestor" |
| Processo rejeitado | Operacional | "Processo X foi rejeitado: [motivo]" |
| Embarque atrasado > 2 dias | Operacional + Gestor | "Processo X: embarque atrasado em 3 dias" |
| Chegada atrasada > 7 dias | Operacional + Gestor | "Processo X: chegada atrasada em 10 dias - ocorrência criada" |
| Processo desembaraçado | Operacional | "Processo X foi desembaraçado - próximo: entrega final" |
| Processo finalizado | Gestor | "Processo X finalizado com desvio de +15%" |
| Desvio > 10% | Gestor | "ALERTA: Processo X com desvio significativo de custo" |
| Ocorrência de Alto Impacto | Gestor | "Ocorrência de ALTO impacto no processo X: [descrição]" |

---

## Relatórios Disponíveis

### 1. Relatório de Processos por Status
- Filtros: Período, status
- Exibe: Lista de processos com dados principais (número, fornecedor, status, valor, datas)

### 2. Relatório de Desvios de Custo
- Filtros: Período, fornecedor, país
- Exibe: Desvio % de cada processo, ordenado por maior desvio
- Gráfico: Desvio médio por fornecedor / por país / por modal

### 3. Relatório de Lead Time
- Filtros: Período, rota (origem-destino), modal
- Exibe: Lead time médio por rota, comparação entre modais
- Gráfico: Evolução do lead time ao longo do tempo

### 4. Relatório de Composição de Custos
- Filtros: Período, processo específico
- Exibe: Pizza chart com % de cada categoria de custo
- Comparação: Previsto vs Real lado a lado

### 5. Relatório de Ocorrências
- Filtros: Período, tipo de ocorrência, impacto
- Exibe: Lista de ocorrências com descrição, impacto, status
- Estatística: Quantas ocorrências por tipo, taxa de resolução

### 6. Relatório de Desempenho de Fornecedores
- Filtros: Período, fornecedor
- Exibe: Quantidade de processos, desvio médio de custo, taxa de atraso, valor total importado
- Ranking: Top 5 fornecedores (menor desvio + menor atraso)

### 7. Relatório Gerencial Consolidado
- Filtros: Período
- Exibe:
  - Total de processos
  - Valor total importado (BRL)
  - Desvio médio de custo
  - Lead time médio
  - Taxa de processos no prazo
  - Top 3 países de origem
  - Top 3 fornecedores

---

## Glossário

| Termo | Significado |
|-------|-------------|
| **PI** | Processo de Importação - documento principal do sistema |
| **FOB** | Free On Board - preço da mercadoria + custos até embarque no país de origem |
| **CIF** | Cost, Insurance, Freight - preço FOB + frete internacional + seguro |
| **Incoterm** | International Commercial Terms - termos que definem responsabilidades entre comprador e vendedor |
| **ETA** | Estimated Time of Arrival - previsão de chegada da carga |
| **DI** | Declaração de Importação - documento da Receita Federal para desembaraço |
| **NCM** | Nomenclatura Comum do Mercosul - código de classificação fiscal da mercadoria |
| **II** | Imposto de Importação - imposto federal sobre produtos importados |
| **IPI** | Imposto sobre Produtos Industrializados - imposto federal |
| **PIS/COFINS** | Programa de Integração Social / Contribuição para Financiamento da Seguridade Social - impostos federais |
| **ICMS** | Imposto sobre Circulação de Mercadorias e Serviços - imposto estadual |
| **Freight Forwarder** | Agente de carga - empresa que organiza o transporte internacional |
| **Despachante Aduaneiro** | Profissional habilitado para fazer desembaraço na Receita Federal |
| **Container** | Unidade padronizada de transporte marítimo (20' ou 40') |
| **AWB** | Air Waybill - conhecimento de transporte aéreo |
| **Lead Time** | Tempo total desde embarque até entrega final |
| **Desvio** | Diferença entre previsto e real (custo ou prazo) |
| **Taxa de Câmbio** | Valor de conversão entre moedas (ex: 1 USD = 5,00 BRL) |
| **Modal** | Meio de transporte (marítimo, aéreo, rodoviário) |
| **Capatazia** | Serviço de movimentação e manuseio de carga no porto/aeroporto |

---

## Permissões por Perfil

| Funcionalidade | Administrador | Gestor | Operacional |
|----------------|---------------|--------|-------------|
| Criar usuários | ✅ | ❌ | ❌ |
| Criar processos | ✅ | ❌ | ✅ |
| Editar processos | ✅ | ❌ (read-only) | ✅ |
| Aprovar processos | ✅ | ✅ | ❌ |
| Lançar custos reais | ✅ | ❌ | ✅ |
| Finalizar processos | ✅ | ❌ | ✅ |
| Ver indicadores | ✅ | ✅ | ✅ (limitado) |
| Exportar relatórios | ✅ | ✅ | ❌ |
| Configurar parâmetros | ✅ | ❌ | ❌ |
| Cadastrar fornecedores | ✅ | ❌ | ✅ |
| Cadastrar prestadores | ✅ | ❌ | ✅ |
| Ver auditoria | ✅ | ✅ (read-only) | ❌ |

---

## Integrações Futuras

### 1. Siscomex (Sistema Integrado de Comércio Exterior)
- Importar dados de DI automaticamente
- Validar NCM e alíquotas
- Acompanhar status de desembaraço em tempo real

### 2. Banco Central (PTAX)
- Buscar taxa de câmbio oficial do dia
- Atualizar automaticamente taxa_cambio_prevista

### 3. ViaCEP / Google Maps
- Calcular distância e tempo de transporte nacional
- Estimar custo de frete por km

### 4. APIs de Freight Forwarders
- Importar ETA automaticamente
- Rastreamento de containers em tempo real

### 5. Sistema ERP da Empresa
- Integrar com módulo de compras
- Enviar dados de custos finais para contabilidade

---

**Documento criado em:** 2026-01-15
**Versão:** 1.0
**Autor:** Especialista em Regras de Negócio
**Status:** Aprovado para desenvolvimento
