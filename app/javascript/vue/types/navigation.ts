export interface MenuItem {
  id: string
  label: string
  href: string
  controller?: string  // para match com menus.controller do DB
  icon?: string
  badge?: string | number
  children?: MenuItem[]
}

export interface MenuSection {
  id: string
  title?: string
  items: MenuItem[]
}

export interface UserInfo {
  id: number
  login: string
  nome: string
}
