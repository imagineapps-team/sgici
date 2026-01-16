# frozen_string_literal: true

class InertiaController < ApplicationController
  inertia_share flash: -> { flash.to_hash }
  inertia_share usuario: -> { current_usuario&.as_json(only: [:id, :login, :nome]) }
end
