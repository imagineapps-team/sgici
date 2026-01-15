import { ref, computed } from 'vue'
import type { EventoAtivo } from '../types/dashboard'
import type { MapMarker } from '../components/IMap/IMap.vue'
import type { DataTableColumn } from '../types/datatable'
import { formatNumber } from '../utils'

export function useDashboardEventos() {
  const eventosAtivos = ref<EventoAtivo[]>([])

  const eventosAtivosMarkers = computed<MapMarker[]>(() => {
    if (!eventosAtivos.value?.length) return []

    return eventosAtivos.value
      .filter(e => e.latitude && e.longitude)
      .map(e => ({
        id: `${e.acao_id}-${e.local_id}`,
        lat: e.latitude!,
        lng: e.longitude!,
        tooltip: `${e.acao} - ${e.local}`,
        label: `<strong>${e.acao}</strong><br/>${e.local}<br/>Coletado: ${formatNumber(e.total_coletado, 2)} kg`,
        color: e.acao.toUpperCase().includes('ECOPONTO') ? 'green' as const : 'blue' as const
      }))
  })

  const colunasEventosAtivos: DataTableColumn<EventoAtivo>[] = [
    { key: 'acao', label: 'Ação' },
    { key: 'local', label: 'Local' },
    { key: 'total_coletado', label: 'Coletado', align: 'right', format: (v) => formatNumber(v, 2) }
  ]

  const setEventosAtivos = (data: EventoAtivo[]) => {
    eventosAtivos.value = data
  }

  return {
    eventosAtivos,
    eventosAtivosMarkers,
    colunasEventosAtivos,
    setEventosAtivos
  }
}
