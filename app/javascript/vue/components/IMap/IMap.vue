<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted, nextTick } from 'vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

export interface MapMarker {
  id: string | number
  lat: number
  lng: number
  label?: string
  tooltip?: string
  color?: 'green' | 'blue' | 'red' | 'yellow' | 'orange'
}

interface Props {
  markers: MapMarker[]
  center?: [number, number]
  zoom?: number
  height?: string
}

const props = withDefaults(defineProps<Props>(), {
  center: () => [-3.7319, -38.5267], // Fortaleza como padrão
  zoom: 11,
  height: '300px'
})

const emit = defineEmits<{
  'marker-click': [marker: MapMarker]
}>()

const mapContainer = ref<HTMLElement | null>(null)
let map: L.Map | null = null
let markerLayer: L.LayerGroup | null = null

// Cores dos marcadores usando CDN de ícones
const markerIcons: Record<string, L.Icon> = {
  green: L.icon({
    iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41]
  }),
  blue: L.icon({
    iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-blue.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41]
  }),
  red: L.icon({
    iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41]
  }),
  yellow: L.icon({
    iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-yellow.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41]
  }),
  orange: L.icon({
    iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-orange.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41]
  })
}

const initMap = () => {
  if (!mapContainer.value) return

  // Verificar se o container tem dimensões válidas
  const rect = mapContainer.value.getBoundingClientRect()
  if (rect.width === 0 || rect.height === 0) return

  if (!map) {
    map = L.map(mapContainer.value).setView(props.center, props.zoom)

    // Usar OpenStreetMap tiles (gratuito)
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(map)

    markerLayer = L.layerGroup().addTo(map)
  }

  updateMarkers()
}

const updateMarkers = () => {
  if (!map || !markerLayer) return

  markerLayer.clearLayers()

  const validMarkers = props.markers.filter(m => m.lat && m.lng)

  validMarkers.forEach(markerData => {
    const icon = markerIcons[markerData.color || 'blue']
    const marker = L.marker([markerData.lat, markerData.lng], { icon })

    if (markerData.tooltip) {
      marker.bindTooltip(markerData.tooltip)
    }

    if (markerData.label) {
      marker.bindPopup(markerData.label)
    }

    marker.on('click', () => {
      emit('marker-click', markerData)
    })

    markerLayer!.addLayer(marker)
  })

  // Ajustar zoom para mostrar todos os marcadores
  if (validMarkers.length > 0) {
    const bounds = L.latLngBounds(validMarkers.map(m => [m.lat, m.lng]))
    map.fitBounds(bounds, { padding: [20, 20], maxZoom: 14 })
  }
}

// Observar mudanças nos marcadores
watch(() => props.markers, () => {
  nextTick(() => {
    if (map) {
      updateMarkers()
    } else {
      initMap()
    }
  })
}, { deep: true })

// ResizeObserver para detectar quando o container se torna visível
let resizeObserver: ResizeObserver | null = null

const setupResizeObserver = () => {
  if (!mapContainer.value) return

  resizeObserver = new ResizeObserver((entries) => {
    for (const entry of entries) {
      if (entry.contentRect.width > 0 && entry.contentRect.height > 0) {
        nextTick(() => {
          if (!map) {
            initMap()
          } else {
            map.invalidateSize()
          }
        })
      }
    }
  })

  resizeObserver.observe(mapContainer.value)
}

onMounted(() => {
  nextTick(() => {
    initMap()
    setupResizeObserver()
  })
})

onUnmounted(() => {
  resizeObserver?.disconnect()
  map?.remove()
  map = null
})
</script>

<template>
  <div
    ref="mapContainer"
    :style="{ height }"
    class="w-full rounded-lg overflow-hidden border border-gray-200 relative z-0"
  />
</template>

<style scoped>
/* Garantir que o mapa fique abaixo do header fixo */
:deep(.leaflet-pane),
:deep(.leaflet-control),
:deep(.leaflet-top),
:deep(.leaflet-bottom) {
  z-index: 1 !important;
}

:deep(.leaflet-control) {
  z-index: 2 !important;
}
</style>
