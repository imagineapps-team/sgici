<template>
  <Link v-bind="$attrs" :prefetch="false">
    <slot />
  </Link>
</template>

<script setup lang="ts">
import { Link } from '@inertiajs/vue3'

// Wrapper do Link do Inertia com prefetch desabilitado por padrao
// Use este componente ao inves de Link para evitar requisicoes no hover
</script>
