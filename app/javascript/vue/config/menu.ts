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
    id: 'cadastros',
    title: 'Cadastros',
    items: [
      {
        id: 'beneficiarios',
        label: 'Beneficiarios',
        href: '/beneficiarios',
        icon: 'users',
        children: [
          {
            id: 'contratos',
            label: 'Contratos',
            href: '/contratos',
            controller: 'contratos'
          },
          {
            id: 'clientes',
            label: 'Clientes',
            href: '/clientes',
            controller: 'clientes'
          }
        ]
      },
      {
        id: 'acoes-eventos',
        label: 'Acoes/Eventos',
        href: '/acoes-eventos',
        icon: 'calendar',
        children: [
          {
            id: 'acoes',
            label: 'Acoes',
            href: '/acaos',
            controller: 'acaos'
          },
          {
            id: 'tipo-acoes',
            label: 'Tipo de Acoes',
            href: '/tipo_acaos',
            controller: 'tipo_acaos'
          },
          {
            id: 'eventos',
            label: 'Eventos',
            href: '/eventos',
            controller: 'eventos'
          }
        ]
      },
      {
        id: 'parceiro',
        label: 'Parceiro',
        href: '/parceiros',
        icon: 'building',
        children: [
          {
            id: 'instituicoes',
            label: 'Instituicoes',
            href: '/instituicaos',
            controller: 'instituicaos'
          },
          {
            id: 'parceiros',
            label: 'Parceiros',
            href: '/parceiros',
            controller: 'parceiros'
          },
          {
            id: 'recicladores',
            label: 'Recicladores',
            href: '/recicladors',
            controller: 'recicladors'
          }
        ]
      },
      {
        id: 'residuos',
        label: 'Residuos',
        href: '/residuos',
        icon: 'trash',
        children: [
          {
            id: 'tipo-residuo',
            label: 'Tipo de Residuo',
            href: '/tipo_residuos',
            controller: 'tipo_residuos'
          },
          {
            id: 'unidade-medida',
            label: 'Unidade de Medida',
            href: '/unidade_medidas',
            controller: 'unidade_medidas'
          },
          {
            id: 'residuos-lista',
            label: 'Residuos',
            href: '/residuos',
            controller: 'residuos'
          }
        ]
      },
      {
        id: 'localidades',
        label: 'Localidades',
        href: '/localidades',
        icon: 'mapPin',
        children: [
          {
            id: 'locais-acao',
            label: 'Locais de Acao',
            href: '/comunidades',
            controller: 'comunidades'
          },
          {
            id: 'bairros',
            label: 'Bairros',
            href: '/bairros',
            controller: 'bairros'
          }
        ]
      },
      {
        id: 'campanhas',
        label: 'Campanhas',
        href: '/campanhas',
        controller: 'campanhas',
        icon: 'megaphone'
      },
      {
        id: 'veiculos',
        label: 'Cadastro de Veiculos',
        href: '/veiculos',
        controller: 'veiculos',
        icon: 'truck'
      }
    ]
  },
  {
    id: 'reciclagens',
    title: 'Reciclagens',
    items: [
      {
        id: 'reciclagens-participantes',
        label: 'Participantes',
        href: '/reciclagens',
        controller: 'reciclagens',
        icon: 'userGroup'
      },
      {
        id: 'reciclagens-recibos',
        label: 'Emissão de Recibos',
        href: '/recibos',
        controller: 'recibos',
        icon: 'documentText'
      },
      {
        id: 'reciclagens-integracoes',
        label: 'Integrações',
        href: '/reciclagens/integracoes',
        controller: 'reciclagens',
        icon: 'arrowsRightLeft'
      }
    ]
  },
  {
    id: 'relatorios',
    title: 'Relatórios',
    items: [
      {
        id: 'historico',
        label: 'Histórico',
        href: '/relatorios',
        icon: 'chart',
        children: [
          {
            id: 'historico-eventos',
            label: 'Por Ação',
            href: '/relatorios/historico_eventos',
            controller: 'relatorios'
          },
          {
            id: 'historico-participacao',
            label: 'Por Participação',
            href: '/relatorios/historico_participacao',
            controller: 'relatorios'
          },
          {
            id: 'historico-residuos',
            label: 'Por Resíduos',
            href: '/relatorios/historico_residuos',
            controller: 'relatorios'
          },
          {
            id: 'historico-reciclador-evento',
            label: 'Reciclador por Evento',
            href: '/relatorios/historico_reciclador_evento',
            controller: 'relatorios'
          }
        ]
      },
      {
        id: 'historico-fatura-reciclador',
        label: 'Fatura do Reciclador',
        href: '/relatorios/historico_fatura_reciclador',
        controller: 'relatorios',
        icon: 'documentText'
      },
      {
        id: 'relatorio-campanhas',
        label: 'Campanhas',
        href: '/relatorios/campanhas',
        controller: 'relatorios',
        icon: 'megaphone'
      },
      {
        id: 'relatorio-veiculos',
        label: 'Veiculos',
        href: '/relatorios/veiculos',
        controller: 'relatorios',
        icon: 'truck'
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
