<template>
  <Head :title="`Processo ${processo.numero}`" />

  <AppLayout :usuario="usuario">
    <div class="max-w-6xl mx-auto space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div>
          <div class="flex items-center gap-3">
            <h1 class="text-2xl font-bold text-gray-900">{{ processo.numero }}</h1>
            <span
              :class="[
                'inline-flex items-center px-3 py-1 rounded-full text-sm font-medium',
                statusClass(processo.status)
              ]"
            >
              {{ processo.statusLabel }}
            </span>
            <span v-if="processo.atrasado" class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-800">
              {{ processo.diasAtraso }}d atraso
            </span>
          </div>
          <p class="mt-1 text-sm text-gray-500">
            Criado por {{ processo.criadoPor.nome }} em {{ formatDate(processo.createdAt) }}
          </p>
        </div>

        <div class="flex items-center gap-2">
          <Link
            href="/processos_importacao"
            class="inline-flex items-center gap-2 px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            <ArrowLeftIcon class="h-5 w-5" />
            Voltar
          </Link>

          <Link
            v-if="podeEditar"
            :href="`/processos_importacao/${processo.id}/edit`"
            class="inline-flex items-center gap-2 px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            <PencilIcon class="h-5 w-5" />
            Editar
          </Link>
        </div>
      </div>

      <!-- Acoes de Transicao -->
      <div v-if="podeAprovar || podeTransitar || podeDesembaracar || podeFinalizar || podeCancelar" class="bg-white rounded-lg shadow p-4">
        <h3 class="text-sm font-medium text-gray-700 mb-3">Acoes Disponiveis</h3>
        <div class="flex flex-wrap gap-2">
          <button
            v-if="podeAprovar"
            @click="handleAprovar"
            :disabled="transitioning"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50"
          >
            Aprovar Processo
          </button>

          <button
            v-if="podeTransitar"
            @click="handleTransitar"
            :disabled="transitioning"
            class="px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 transition-colors disabled:opacity-50"
          >
            Iniciar Transito
          </button>

          <button
            v-if="podeDesembaracar"
            @click="handleDesembaracar"
            :disabled="transitioning"
            class="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors disabled:opacity-50"
          >
            Registrar Desembaraco
          </button>

          <button
            v-if="podeFinalizar"
            @click="handleFinalizar"
            :disabled="transitioning"
            class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50"
          >
            Finalizar Processo
          </button>

          <button
            v-if="podeCancelar"
            @click="showCancelModal = true"
            :disabled="transitioning"
            class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50"
          >
            Cancelar Processo
          </button>
        </div>
      </div>

      <!-- Tabs Navigation -->
      <div class="border-b border-gray-200">
        <nav class="-mb-px flex space-x-8" aria-label="Tabs">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            @click="activeTab = tab.id"
            :class="[
              activeTab === tab.id
                ? 'border-brand-primary text-brand-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300',
              'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm flex items-center gap-2'
            ]"
          >
            <component :is="tab.icon" class="h-5 w-5" />
            {{ tab.label }}
            <span
              v-if="tab.count !== undefined && tab.count > 0"
              class="ml-1 bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full text-xs"
            >
              {{ tab.count }}
            </span>
          </button>
        </nav>
      </div>

      <!-- Tab Content -->
      <div>
        <!-- Tab: Geral -->
        <div v-show="activeTab === 'geral'" class="space-y-6">
          <!-- Grid de Informacoes -->
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Dados do Fornecedor -->
            <div class="bg-white rounded-lg shadow p-6">
              <h3 class="text-lg font-semibold text-gray-900 mb-4">Fornecedor</h3>
              <dl class="space-y-3">
                <div>
                  <dt class="text-sm text-gray-500">Nome</dt>
                  <dd class="text-sm font-medium text-gray-900">{{ processo.fornecedor.nome }}</dd>
                </div>
                <div>
                  <dt class="text-sm text-gray-500">Pais</dt>
                  <dd class="text-sm text-gray-900">{{ processo.fornecedor.pais || processo.paisOrigem }}</dd>
                </div>
                <div v-if="processo.responsavel">
                  <dt class="text-sm text-gray-500">Responsavel</dt>
                  <dd class="text-sm text-gray-900">{{ processo.responsavel.nome }}</dd>
                </div>
              </dl>
            </div>

            <!-- Dados do Transporte -->
            <div class="bg-white rounded-lg shadow p-6">
              <h3 class="text-lg font-semibold text-gray-900 mb-4">Transporte</h3>
              <dl class="space-y-3">
                <div>
                  <dt class="text-sm text-gray-500">Modal</dt>
                  <dd class="text-sm font-medium text-gray-900">{{ processo.modalLabel }}</dd>
                </div>
                <div v-if="processo.incoterm">
                  <dt class="text-sm text-gray-500">Incoterm</dt>
                  <dd class="text-sm text-gray-900">{{ processo.incoterm }}</dd>
                </div>
                <div v-if="processo.portoOrigem || processo.aeroportoOrigem">
                  <dt class="text-sm text-gray-500">Origem</dt>
                  <dd class="text-sm text-gray-900">{{ processo.portoOrigem || processo.aeroportoOrigem }}</dd>
                </div>
                <div v-if="processo.portoDestino || processo.aeroportoDestino">
                  <dt class="text-sm text-gray-500">Destino</dt>
                  <dd class="text-sm text-gray-900">{{ processo.portoDestino || processo.aeroportoDestino }}</dd>
                </div>
              </dl>
            </div>

            <!-- Valores -->
            <div class="bg-white rounded-lg shadow p-6">
              <h3 class="text-lg font-semibold text-gray-900 mb-4">Valores</h3>
              <dl class="space-y-3">
                <div v-if="processo.valorFob">
                  <dt class="text-sm text-gray-500">Valor FOB</dt>
                  <dd class="text-sm font-medium text-gray-900">{{ processo.moeda }} {{ formatNumber(processo.valorFob) }}</dd>
                </div>
                <div v-if="processo.taxaCambio">
                  <dt class="text-sm text-gray-500">Taxa Cambio</dt>
                  <dd class="text-sm text-gray-900">{{ Number(processo.taxaCambio).toFixed(4) }}</dd>
                </div>
                <div v-if="processo.custoPrevistoTotal">
                  <dt class="text-sm text-gray-500">Custo Previsto Total</dt>
                  <dd class="text-sm text-gray-900">R$ {{ formatNumber(processo.custoPrevistoTotal) }}</dd>
                </div>
                <div v-if="processo.custoRealTotal">
                  <dt class="text-sm text-gray-500">Custo Real Total</dt>
                  <dd class="text-sm text-gray-900">R$ {{ formatNumber(processo.custoRealTotal) }}</dd>
                </div>
                <div v-if="processo.desvioPercentual != null">
                  <dt class="text-sm text-gray-500">Desvio</dt>
                  <dd :class="['text-sm font-medium', desvioClass(processo.desvioPercentual)]">
                    {{ Number(processo.desvioPercentual) > 0 ? '+' : '' }}{{ Number(processo.desvioPercentual).toFixed(2) }}%
                  </dd>
                </div>
              </dl>
            </div>
          </div>

          <!-- Documentos -->
          <div v-if="processo.numeroBl || processo.numeroContainer || processo.numeroAwb || processo.numeroDi || processo.numeroDuimp" class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Documentos</h3>
            <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
              <div v-if="processo.numeroBl">
                <dt class="text-sm text-gray-500">B/L</dt>
                <dd class="text-sm font-medium text-gray-900">{{ processo.numeroBl }}</dd>
              </div>
              <div v-if="processo.numeroAwb">
                <dt class="text-sm text-gray-500">AWB</dt>
                <dd class="text-sm font-medium text-gray-900">{{ processo.numeroAwb }}</dd>
              </div>
              <div v-if="processo.numeroContainer">
                <dt class="text-sm text-gray-500">Container</dt>
                <dd class="text-sm font-medium text-gray-900">{{ processo.numeroContainer }}</dd>
              </div>
              <div v-if="processo.numeroDi">
                <dt class="text-sm text-gray-500">DI</dt>
                <dd class="text-sm font-medium text-gray-900">{{ processo.numeroDi }}</dd>
              </div>
              <div v-if="processo.numeroDuimp">
                <dt class="text-sm text-gray-500">DUIMP</dt>
                <dd class="text-sm font-medium text-gray-900">{{ processo.numeroDuimp }}</dd>
              </div>
            </div>
          </div>

          <!-- Datas -->
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Cronograma</h3>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <dt class="text-sm text-gray-500">Embarque Previsto</dt>
                <dd class="text-sm text-gray-900">{{ processo.dataEmbarquePrevista ? formatDate(processo.dataEmbarquePrevista) : '-' }}</dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Embarque Real</dt>
                <dd class="text-sm text-gray-900">{{ processo.dataEmbarqueReal ? formatDate(processo.dataEmbarqueReal) : '-' }}</dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Chegada Prevista</dt>
                <dd class="text-sm text-gray-900">{{ processo.dataChegadaPrevista ? formatDate(processo.dataChegadaPrevista) : '-' }}</dd>
              </div>
              <div>
                <dt class="text-sm text-gray-500">Chegada Real</dt>
                <dd class="text-sm text-gray-900">{{ processo.dataChegadaReal ? formatDate(processo.dataChegadaReal) : '-' }}</dd>
              </div>
              <div v-if="processo.dataDesembaraco">
                <dt class="text-sm text-gray-500">Desembaraco</dt>
                <dd class="text-sm text-gray-900">{{ formatDate(processo.dataDesembaraco) }}</dd>
              </div>
              <div v-if="processo.dataEntregaPrevista">
                <dt class="text-sm text-gray-500">Entrega Prevista</dt>
                <dd class="text-sm text-gray-900">{{ formatDate(processo.dataEntregaPrevista) }}</dd>
              </div>
              <div v-if="processo.dataEntregaReal">
                <dt class="text-sm text-gray-500">Entrega Real</dt>
                <dd class="text-sm text-gray-900">{{ formatDate(processo.dataEntregaReal) }}</dd>
              </div>
              <div v-if="processo.dataFinalizacao">
                <dt class="text-sm text-gray-500">Finalizacao</dt>
                <dd class="text-sm text-gray-900">{{ formatDate(processo.dataFinalizacao) }}</dd>
              </div>
              <div v-if="processo.leadTimeDias">
                <dt class="text-sm text-gray-500">Lead Time</dt>
                <dd class="text-sm font-medium text-gray-900">{{ processo.leadTimeDias }} dias</dd>
              </div>
            </div>
          </div>

          <!-- Observacoes -->
          <div v-if="processo.observacoes" class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Observacoes</h3>
            <p class="text-sm text-gray-700 whitespace-pre-wrap">{{ processo.observacoes }}</p>
          </div>
        </div>

        <!-- Tab: Custos Previstos -->
        <div v-show="activeTab === 'custos_previstos'" class="space-y-6">
          <div class="bg-white rounded-lg shadow">
            <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <div>
                <h3 class="text-lg font-semibold text-gray-900">Custos Previstos</h3>
                <p class="text-sm text-gray-500">
                  Total: <span class="font-semibold text-gray-900">R$ {{ formatNumber(totalCustosPrevistos) }}</span>
                </p>
              </div>
              <div v-if="podeEditar" class="flex items-center gap-2">
                <button
                  @click="showCalculadoraModal = true"
                  class="inline-flex items-center gap-2 px-3 py-2 text-sm text-blue-700 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
                >
                  <CalculatorIcon class="h-4 w-4" />
                  Calcular Impostos
                </button>
                <button
                  @click="handleAddCusto"
                  class="inline-flex items-center gap-2 px-3 py-2 text-sm text-white bg-brand-primary rounded-lg hover:bg-brand-primary-dark transition-colors"
                >
                  <PlusIcon class="h-4 w-4" />
                  Adicionar Custo
                </button>
              </div>
            </div>
            <div v-if="custosPrevistos.length > 0" class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Categoria</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Descricao</th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Valor Original</th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Valor BRL</th>
                    <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase">Data Previsao</th>
                    <th v-if="podeEditar" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Acoes</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr v-for="custo in custosPrevistos" :key="custo.id" class="hover:bg-gray-50">
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {{ custo.categoria?.nome || '-' }}
                    </td>
                    <td class="px-6 py-4 text-sm text-gray-500">
                      {{ custo.descricao || '-' }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 text-right">
                      {{ custo.moeda }} {{ formatNumber(custo.valor) }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 text-right">
                      R$ {{ formatNumber(custo.valorBrl) }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">
                      {{ custo.dataPrevisao ? formatDate(custo.dataPrevisao) : '-' }}
                    </td>
                    <td v-if="podeEditar" class="px-6 py-4 whitespace-nowrap text-right">
                      <div class="flex items-center justify-end gap-2">
                        <button
                          @click="handleEditCusto(custo)"
                          class="p-1 text-gray-400 hover:text-blue-600 transition-colors"
                          title="Editar"
                        >
                          <PencilIcon class="h-4 w-4" />
                        </button>
                        <button
                          v-if="!custo.realizado"
                          @click="handleDeleteCustoClick(custo)"
                          class="p-1 text-gray-400 hover:text-red-600 transition-colors"
                          title="Excluir"
                        >
                          <TrashIcon class="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                </tbody>
                <tfoot class="bg-gray-50">
                  <tr>
                    <td :colspan="podeEditar ? 4 : 3" class="px-6 py-3 text-sm font-semibold text-gray-900 text-right">Total</td>
                    <td class="px-6 py-3 text-sm font-semibold text-gray-900 text-right">
                      R$ {{ formatNumber(totalCustosPrevistos) }}
                    </td>
                    <td v-if="podeEditar"></td>
                  </tr>
                </tfoot>
              </table>
            </div>
            <div v-else class="px-6 py-12 text-center text-gray-500">
              <CurrencyDollarIcon class="mx-auto h-12 w-12 text-gray-300" />
              <p class="mt-2">Nenhum custo previsto cadastrado.</p>
              <button
                v-if="podeEditar"
                @click="handleAddCusto"
                class="mt-4 inline-flex items-center gap-2 px-4 py-2 text-sm text-white bg-brand-primary rounded-lg hover:bg-brand-primary-dark transition-colors"
              >
                <PlusIcon class="h-4 w-4" />
                Adicionar Primeiro Custo
              </button>
            </div>
          </div>
        </div>

        <!-- Tab: Custos Reais -->
        <div v-show="activeTab === 'custos_reais'" class="space-y-6">
          <div class="bg-white rounded-lg shadow">
            <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <div>
                <h3 class="text-lg font-semibold text-gray-900">Custos Reais</h3>
                <p class="text-sm text-gray-500">
                  Total: <span class="font-semibold text-gray-900">R$ {{ formatNumber(totalCustosReais) }}</span>
                </p>
              </div>
              <div v-if="podeEditar" class="flex items-center gap-2">
                <button
                  @click="handleAddCustoReal"
                  class="inline-flex items-center gap-2 px-3 py-2 text-sm text-white bg-brand-primary rounded-lg hover:bg-brand-primary-dark transition-colors"
                >
                  <PlusIcon class="h-4 w-4" />
                  Lancar Custo
                </button>
              </div>
            </div>
            <div v-if="custosReais.length > 0" class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Categoria</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Prestador</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Documento</th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Valor BRL</th>
                    <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase">Vencimento</th>
                    <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase">Pagamento</th>
                    <th v-if="podeEditar" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Acoes</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr v-for="custo in custosReais" :key="custo.id" class="hover:bg-gray-50">
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {{ custo.categoria?.nome || '-' }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {{ custo.prestador?.nome || '-' }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {{ custo.numeroDocumento || '-' }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 text-right">
                      R$ {{ formatNumber(custo.valorBrl) }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">
                      {{ custo.dataVencimento ? formatDate(custo.dataVencimento) : '-' }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-center">
                      <span v-if="custo.dataPagamento" class="text-green-600">
                        {{ formatDate(custo.dataPagamento) }}
                      </span>
                      <span v-else class="text-yellow-600">Pendente</span>
                    </td>
                    <td v-if="podeEditar" class="px-6 py-4 whitespace-nowrap text-right">
                      <div class="flex items-center justify-end gap-2">
                        <button
                          @click="handleEditCustoReal(custo)"
                          class="p-1 text-gray-400 hover:text-blue-600 transition-colors"
                          title="Editar"
                        >
                          <PencilIcon class="h-4 w-4" />
                        </button>
                        <button
                          @click="handleDeleteCustoRealClick(custo)"
                          class="p-1 text-gray-400 hover:text-red-600 transition-colors"
                          title="Excluir"
                        >
                          <TrashIcon class="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                </tbody>
                <tfoot class="bg-gray-50">
                  <tr>
                    <td :colspan="podeEditar ? 4 : 3" class="px-6 py-3 text-sm font-semibold text-gray-900 text-right">Total</td>
                    <td class="px-6 py-3 text-sm font-semibold text-gray-900 text-right">
                      R$ {{ formatNumber(totalCustosReais) }}
                    </td>
                    <td colspan="2"></td>
                  </tr>
                </tfoot>
              </table>
            </div>
            <div v-else class="px-6 py-12 text-center text-gray-500">
              <CurrencyDollarIcon class="mx-auto h-12 w-12 text-gray-300" />
              <p class="mt-2">Nenhum custo real lancado.</p>
              <button
                v-if="podeEditar"
                @click="handleAddCustoReal"
                class="mt-4 inline-flex items-center gap-2 px-4 py-2 text-sm text-white bg-brand-primary rounded-lg hover:bg-brand-primary-dark transition-colors"
              >
                <PlusIcon class="h-4 w-4" />
                Lancar Primeiro Custo
              </button>
            </div>
          </div>

          <!-- Comparativo -->
          <div v-if="comparativoCustos.length > 0" class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Comparativo Previsto vs Real</h3>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead>
                  <tr>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Categoria</th>
                    <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Previsto</th>
                    <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Real</th>
                    <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Desvio</th>
                    <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">%</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                  <tr v-for="custo in comparativoCustos" :key="custo.categoriaId">
                    <td class="px-4 py-3 text-sm text-gray-900">{{ custo.categoria }}</td>
                    <td class="px-4 py-3 text-sm text-gray-900 text-right">R$ {{ formatNumber(custo.previsto) }}</td>
                    <td class="px-4 py-3 text-sm text-gray-900 text-right">R$ {{ formatNumber(custo.real) }}</td>
                    <td class="px-4 py-3 text-sm text-right" :class="desvioClass(custo.desvioPercentual)">
                      R$ {{ formatNumber(custo.desvio) }}
                    </td>
                    <td class="px-4 py-3 text-sm text-right font-medium" :class="desvioClass(custo.desvioPercentual)">
                      {{ Number(custo.desvioPercentual || 0) > 0 ? '+' : '' }}{{ Number(custo.desvioPercentual || 0).toFixed(1) }}%
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Tab: Logistica -->
        <div v-show="activeTab === 'logistica'" class="space-y-6">
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-6">Timeline de Eventos</h3>

            <div v-if="processo.eventosLogisticos && processo.eventosLogisticos.length > 0" class="flow-root">
              <ul role="list" class="-mb-8">
                <li v-for="(evento, idx) in processo.eventosLogisticos" :key="evento.id">
                  <div class="relative pb-8">
                    <span
                      v-if="idx !== processo.eventosLogisticos.length - 1"
                      class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200"
                      aria-hidden="true"
                    ></span>
                    <div class="relative flex space-x-3">
                      <div>
                        <span
                          :class="[
                            'h-8 w-8 rounded-full flex items-center justify-center ring-8 ring-white',
                            eventoIconClass(evento.tipo)
                          ]"
                        >
                          <component :is="eventoIcon(evento.tipo)" class="h-4 w-4 text-white" />
                        </span>
                      </div>
                      <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                        <div>
                          <p class="text-sm font-medium text-gray-900">
                            {{ evento.tipoLabel }}
                          </p>
                          <p v-if="evento.descricao" class="mt-0.5 text-sm text-gray-500">
                            {{ evento.descricao }}
                          </p>
                          <p v-if="evento.localEvento" class="mt-0.5 text-xs text-gray-400">
                            Local: {{ evento.localEvento }}
                          </p>
                        </div>
                        <div class="whitespace-nowrap text-right text-sm text-gray-500">
                          <time :datetime="evento.dataEvento">{{ formatDate(evento.dataEvento) }}</time>
                          <p class="text-xs text-gray-400">por {{ evento.registradoPor.nome }}</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </li>
              </ul>
            </div>

            <div v-else class="text-center py-12 text-gray-500">
              <TruckIcon class="mx-auto h-12 w-12 text-gray-300" />
              <p class="mt-2">Nenhum evento logistico registrado.</p>
            </div>
          </div>

          <!-- Prestadores Envolvidos -->
          <div v-if="processo.prestadores && processo.prestadores.length > 0" class="bg-white rounded-lg shadow p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Prestadores Envolvidos</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <div
                v-for="prestador in processo.prestadores"
                :key="prestador.id"
                class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg"
              >
                <div class="flex-shrink-0">
                  <BuildingOfficeIcon class="h-6 w-6 text-gray-400" />
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900">{{ prestador.nome }}</p>
                  <p class="text-xs text-gray-500">{{ prestador.tipo }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Tab: Documentos -->
        <div v-show="activeTab === 'documentos'" class="space-y-6">
          <div class="bg-white rounded-lg shadow p-6">
            <AnexosManager
              :base-url="`/processos_importacao/${processo.id}/anexos`"
              :readonly="!podeEditar"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Modal de Cancelamento -->
    <IModal v-model="showCancelModal" title="Cancelar Processo" size="md">
      <div class="space-y-4">
        <p class="text-sm text-gray-600">
          Informe o motivo do cancelamento do processo {{ processo.numero }}.
        </p>
        <textarea
          v-model="cancelMotivo"
          rows="3"
          class="w-full rounded-lg border-gray-300 shadow-sm focus:border-brand-primary focus:ring-brand-primary"
          placeholder="Motivo do cancelamento..."
        ></textarea>
      </div>

      <template #footer>
        <div class="flex justify-end gap-3">
          <button
            @click="showCancelModal = false"
            class="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
          >
            Voltar
          </button>
          <button
            @click="handleCancelar"
            :disabled="transitioning"
            class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
          >
            Confirmar Cancelamento
          </button>
        </div>
      </template>
    </IModal>

    <!-- Modal de Custo Previsto -->
    <CustoPrevistoModal
      v-model="showCustoModal"
      :processo-id="processo.id"
      :custo="custoEmEdicao"
      :categorias="categorias"
      @saved="handleCustoSaved"
    />

    <!-- Modal de Calculadora de Impostos -->
    <CalculadoraImpostosModal
      v-model="showCalculadoraModal"
      :processo-id="processo.id"
      :valor-fob-inicial="processo.valorFob"
      :taxa-cambio-inicial="processo.taxaCambio"
      @generated="handleImpostosGenerated"
    />

    <!-- Modal de Confirmacao de Exclusao de Custo Previsto -->
    <ConfirmationModal
      v-model="showDeleteCustoModal"
      title="Excluir Custo Previsto"
      :message="`Tem certeza que deseja excluir o custo '${custoParaDeletar?.categoria?.nome || ''}'?`"
      confirm-text="Excluir"
      type="danger"
      @confirm="handleDeleteCusto"
    />

    <!-- Modal de Custo Real -->
    <CustoRealModal
      v-model="showCustoRealModal"
      :processo-id="processo.id"
      :custo="custoRealEmEdicao"
      :categorias="categoriasReais"
      :prestadores="prestadores"
      :custos-previstos="custosPrevistosPendentes"
      @saved="handleCustoRealSaved"
    />

    <!-- Modal de Confirmacao de Exclusao de Custo Real -->
    <ConfirmationModal
      v-model="showDeleteCustoRealModal"
      title="Excluir Custo Real"
      :message="`Tem certeza que deseja excluir o custo '${custoRealParaDeletar?.categoria?.nome || ''}'?`"
      confirm-text="Excluir"
      type="danger"
      @confirm="handleDeleteCustoReal"
    />
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed, type Component } from 'vue'
import { Head, Link, router } from '@inertiajs/vue3'
import {
  ArrowLeftIcon,
  PencilIcon,
  InformationCircleIcon,
  CurrencyDollarIcon,
  TruckIcon,
  CheckCircleIcon,
  ClockIcon,
  DocumentTextIcon,
  BuildingOfficeIcon,
  PlusIcon,
  CalculatorIcon,
  TrashIcon,
  PaperClipIcon
} from '@heroicons/vue/24/outline'
import AppLayout from '../../layouts/AppLayout.vue'
import IModal from '../../components/IModal/IModal.vue'
import CustoPrevistoModal from '../../components/CustoPrevistoModal.vue'
import CustoRealModal from '../../components/CustoRealModal.vue'
import CalculadoraImpostosModal from '../../components/CalculadoraImpostosModal.vue'
import ConfirmationModal from '../../components/ConfirmationModal/ConfirmationModal.vue'
import { AnexosManager } from '../../components/AnexosManager'
import type { UserInfo } from '../../types/navigation'
import type { ProcessoImportacao, ComparativoCusto, ProcessoStatus, CustoPrevisto, CustoReal, CategoriaOption, PrestadorOption, CustoPrevistoOption } from '../../types/importacao'
import { formatDate } from '../../utils'
import { useNotifications } from '../../composables/useNotification'
import api from '../../lib/axios'

interface Props {
  usuario: UserInfo
  processo: ProcessoImportacao
  comparativoCustos: ComparativoCusto[]
  categorias: CategoriaOption[]
  categoriasReais: CategoriaOption[]
  prestadores: PrestadorOption[]
  custosPrevistosPendentes: CustoPrevistoOption[]
  podeEditar: boolean
  podeAprovar: boolean
  podeTransitar: boolean
  podeDesembaracar: boolean
  podeFinalizar: boolean
  podeCancelar: boolean
}

const props = defineProps<Props>()
const { success, error: showError } = useNotifications()

const activeTab = ref('geral')
const transitioning = ref(false)
const showCancelModal = ref(false)
const cancelMotivo = ref('')

// Custos Previstos state
const showCustoModal = ref(false)
const showCalculadoraModal = ref(false)
const showDeleteCustoModal = ref(false)
const custoEmEdicao = ref<CustoPrevisto | null>(null)
const custoParaDeletar = ref<CustoPrevisto | null>(null)
const custosPrevistos = ref<CustoPrevisto[]>(props.processo.custosPrevistos || [])
const deletingCusto = ref(false)

// Custos Reais state
const showCustoRealModal = ref(false)
const showDeleteCustoRealModal = ref(false)
const custoRealEmEdicao = ref<CustoReal | null>(null)
const custoRealParaDeletar = ref<CustoReal | null>(null)
const custosReais = ref<CustoReal[]>(props.processo.custosReais || [])
const deletingCustoReal = ref(false)

// Tabs configuration
const tabs = computed(() => [
  {
    id: 'geral',
    label: 'Informacoes Gerais',
    icon: InformationCircleIcon
  },
  {
    id: 'custos_previstos',
    label: 'Custos Previstos',
    icon: CurrencyDollarIcon,
    count: custosPrevistos.value.length
  },
  {
    id: 'custos_reais',
    label: 'Custos Reais',
    icon: CurrencyDollarIcon,
    count: custosReais.value.length
  },
  {
    id: 'logistica',
    label: 'Logistica',
    icon: TruckIcon,
    count: props.processo.eventosLogisticos?.length || 0
  },
  {
    id: 'documentos',
    label: 'Documentos',
    icon: PaperClipIcon,
    count: props.processo.totalAnexos || 0
  }
])

// Computed totals
const totalCustosPrevistos = computed(() => {
  return custosPrevistos.value.reduce((sum, c) => sum + (c.valorBrl || 0), 0)
})

const totalCustosReais = computed(() => {
  return custosReais.value.reduce((sum, c) => sum + (c.valorBrl || 0), 0)
})

// Custos Previstos handlers
function handleAddCusto() {
  custoEmEdicao.value = null
  showCustoModal.value = true
}

function handleEditCusto(custo: CustoPrevisto) {
  custoEmEdicao.value = custo
  showCustoModal.value = true
}

function handleDeleteCustoClick(custo: CustoPrevisto) {
  custoParaDeletar.value = custo
  showDeleteCustoModal.value = true
}

async function handleDeleteCusto() {
  if (!custoParaDeletar.value) return

  deletingCusto.value = true
  try {
    const response = await api.delete(
      `/processos_importacao/${props.processo.id}/custos_previstos/${custoParaDeletar.value.id}/ajax_destroy`
    )
    if (response.data.success) {
      custosPrevistos.value = custosPrevistos.value.filter(c => c.id !== custoParaDeletar.value!.id)
      success('Custo removido com sucesso')
    } else {
      showError(response.data.message || 'Erro ao remover custo')
    }
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : 'Erro ao remover custo'
    showError(errorMessage)
  } finally {
    deletingCusto.value = false
    showDeleteCustoModal.value = false
    custoParaDeletar.value = null
  }
}

function handleCustoSaved(custo: CustoPrevisto) {
  const idx = custosPrevistos.value.findIndex(c => c.id === custo.id)
  if (idx >= 0) {
    custosPrevistos.value[idx] = custo
  } else {
    custosPrevistos.value.push(custo)
  }
  showCustoModal.value = false
  custoEmEdicao.value = null
}

function handleImpostosGenerated() {
  // Recarrega a página para obter os novos custos
  router.reload()
}

// Custos Reais handlers
function handleAddCustoReal() {
  custoRealEmEdicao.value = null
  showCustoRealModal.value = true
}

function handleEditCustoReal(custo: CustoReal) {
  custoRealEmEdicao.value = custo
  showCustoRealModal.value = true
}

function handleDeleteCustoRealClick(custo: CustoReal) {
  custoRealParaDeletar.value = custo
  showDeleteCustoRealModal.value = true
}

async function handleDeleteCustoReal() {
  if (!custoRealParaDeletar.value) return

  deletingCustoReal.value = true
  try {
    const response = await api.delete(
      `/processos_importacao/${props.processo.id}/custos_reais/${custoRealParaDeletar.value.id}/ajax_destroy`
    )
    if (response.data.success) {
      custosReais.value = custosReais.value.filter(c => c.id !== custoRealParaDeletar.value!.id)
      success('Custo removido com sucesso')
    } else {
      showError(response.data.message || 'Erro ao remover custo')
    }
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : 'Erro ao remover custo'
    showError(errorMessage)
  } finally {
    deletingCustoReal.value = false
    showDeleteCustoRealModal.value = false
    custoRealParaDeletar.value = null
  }
}

function handleCustoRealSaved(custo: CustoReal) {
  const idx = custosReais.value.findIndex(c => c.id === custo.id)
  if (idx >= 0) {
    custosReais.value[idx] = custo
  } else {
    custosReais.value.push(custo)
  }
  showCustoRealModal.value = false
  custoRealEmEdicao.value = null
}

function statusClass(status: ProcessoStatus): string {
  switch (status) {
    case 'planejado': return 'bg-gray-100 text-gray-800'
    case 'aprovado': return 'bg-blue-100 text-blue-800'
    case 'em_transito': return 'bg-yellow-100 text-yellow-800'
    case 'desembaracado': return 'bg-purple-100 text-purple-800'
    case 'finalizado': return 'bg-green-100 text-green-800'
    case 'cancelado': return 'bg-red-100 text-red-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}

function desvioClass(desvio: number): string {
  if (desvio > 10) return 'text-red-600'
  if (desvio > 5) return 'text-yellow-600'
  if (desvio < -5) return 'text-green-600'
  return 'text-gray-600'
}

function formatNumber(value: number): string {
  return new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value)
}

function eventoIconClass(tipo: string): string {
  switch (tipo) {
    case 'embarque': return 'bg-blue-500'
    case 'chegada': return 'bg-green-500'
    case 'desembaraco': return 'bg-purple-500'
    case 'entrega': return 'bg-emerald-500'
    default: return 'bg-gray-500'
  }
}

function eventoIcon(tipo: string): Component {
  switch (tipo) {
    case 'embarque': return TruckIcon
    case 'chegada': return CheckCircleIcon
    case 'desembaraco': return DocumentTextIcon
    case 'entrega': return CheckCircleIcon
    default: return ClockIcon
  }
}

async function handleTransition(action: string, data: Record<string, unknown> = {}) {
  transitioning.value = true
  try {
    const response = await api.post(`/processos_importacao/${props.processo.id}/${action}`, data)
    if (response.data.success) {
      success(response.data.message)
      router.reload()
    } else {
      showError(response.data.message || 'Erro ao executar acao')
    }
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : 'Erro ao executar acao'
    showError(errorMessage)
  } finally {
    transitioning.value = false
  }
}

function handleAprovar() {
  handleTransition('aprovar')
}

function handleTransitar() {
  handleTransition('transitar')
}

function handleDesembaracar() {
  handleTransition('desembaracar')
}

function handleFinalizar() {
  handleTransition('finalizar')
}

function handleCancelar() {
  handleTransition('cancelar', { motivo: cancelMotivo.value })
  showCancelModal.value = false
  cancelMotivo.value = ''
}
</script>
