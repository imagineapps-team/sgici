import type { MenuSection, MenuItem } from '../types/navigation'

export const menuSections: MenuSection[] = [
  {
    id: 'main',
    items: [
      {
        id: 'dashboard',
        label: 'Dashboard',
        href: '/',
        controller: 'dashboard',
        icon: 'home'
      }
    ]
  },
  {
    id: 'operacional',
    title: 'Operacional',
    items: [
      {
        id: 'processos',
        label: 'Processos de Importacao',
        href: '/processos_importacao',
        controller: 'processos_importacao',
        icon: 'truck'
      },
      {
        id: 'custos',
        label: 'Gestao de Custos',
        href: '/custos',
        icon: 'currencyDollar',
        children: [
          {
            id: 'custos-previstos',
            label: 'Custos Previstos',
            href: '/custos_previstos',
            controller: 'custos_previstos'
          },
          {
            id: 'custos-reais',
            label: 'Custos Reais',
            href: '/custos_reais',
            controller: 'custos_reais'
          }
        ]
      },
      {
        id: 'eventos-logisticos',
        label: 'Eventos Logisticos',
        href: '/eventos_logisticos',
        controller: 'eventos_logisticos',
        icon: 'calendar'
      }
    ]
  },
  {
    id: 'cadastros',
    title: 'Cadastros',
    items: [
      {
        id: 'fornecedores',
        label: 'Fornecedores',
        href: '/fornecedores',
        controller: 'fornecedores',
        icon: 'building'
      },
      {
        id: 'prestadores',
        label: 'Prestadores de Servico',
        href: '/prestadores_servico',
        controller: 'prestadores_servico',
        icon: 'users'
      },
      {
        id: 'categorias',
        label: 'Categorias de Custo',
        href: '/categorias_custo',
        controller: 'categorias_custo',
        icon: 'folder'
      }
    ]
  },
  {
    id: 'relatorios',
    title: 'Relatorios',
    items: [
      {
        id: 'relatorio-processos',
        label: 'Processos',
        href: '/relatorios/processos',
        controller: 'relatorios',
        icon: 'documentText'
      },
      {
        id: 'relatorio-custos',
        label: 'Analise de Custos',
        href: '/relatorios/custos',
        controller: 'relatorios',
        icon: 'chart'
      },
      {
        id: 'relatorio-fornecedores',
        label: 'Performance Fornecedores',
        href: '/relatorios/fornecedores',
        controller: 'relatorios',
        icon: 'chartBar'
      }
    ]
  },
  {
    id: 'administrativo',
    title: 'Administrativo',
    items: [
      {
        id: 'usuarios',
        label: 'Usuarios',
        href: '/usuarios',
        controller: 'usuarios',
        icon: 'userCog'
      },
      {
        id: 'permissoes_menu',
        label: 'Controle de Acesso',
        href: '/permissoes_menu',
        controller: 'permissoes_menu',
        icon: 'lockClosed'
      }
    ]
  }
]

/**
 * Filtra menu baseado nas permissoes do perfil do usuario
 * @param sections - Secoes do menu
 * @param allowedPaths - Paths permitidos (null = acesso total admin)
 */
export function filterMenuByPermissions(
  sections: MenuSection[],
  allowedPaths: string[] | null
): MenuSection[] {
  // null = acesso total (admin)
  if (allowedPaths === null) return sections

  return sections
    .map(section => ({
      ...section,
      items: filterItems(section.items, allowedPaths)
    }))
    .filter(section => section.items.length > 0)
}

function filterItems(items: MenuItem[], allowedPaths: string[]): MenuItem[] {
  return items
    .map(item => {
      // Se tem children, filtra recursivamente
      if (item.children) {
        const filteredChildren = filterItems(item.children, allowedPaths)
        if (filteredChildren.length === 0) return null
        return { ...item, children: filteredChildren }
      }
      // Verifica se controller esta em allowedPaths
      const isAllowed = item.controller
        ? allowedPaths.some(path => path.startsWith(`/${item.controller}`))
        : true // Items sem controller sao permitidos por padrao
      return isAllowed ? item : null
    })
    .filter((item): item is MenuItem => item !== null)
}
