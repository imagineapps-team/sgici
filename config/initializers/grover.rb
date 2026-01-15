# frozen_string_literal: true

Grover.configure do |config|
  config.options = {
    format: 'A4',
    margin: {
      top: '1cm',
      bottom: '1cm',
      left: '1cm',
      right: '1cm'
    },
    print_background: true,
    prefer_css_page_size: true,
    emulate_media: 'print',
    launch_args: ['--no-sandbox', '--disable-setuid-sandbox'],
    wait_until: 'networkidle0'
  }

  # Para desenvolvimento, usar puppeteer local
  # Em produção, configurar o path do Chrome se necessário
  # config.options[:executable_path] = '/usr/bin/google-chrome'
end
