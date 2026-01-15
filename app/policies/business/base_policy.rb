# frozen_string_literal: true

module Business
  # Classe base para Business Policies (Strategy Pattern)
  #
  # Use para encapsular variações de regras de negócio entre aplicações.
  # Cada policy define um contrato e múltiplas implementações.
  #
  # == Quando usar
  #
  # - Regra de negócio que varia PERMANENTEMENTE entre aplicações
  # - Cálculos com fórmulas diferentes por cliente
  # - Validações com critérios diferentes
  #
  # == Quando NÃO usar
  #
  # - Features temporárias (use Flipper)
  # - Kill switches (use Flipper)
  # - Rollout gradual (use Flipper)
  #
  # == Como criar uma nova Policy
  #
  # 1. Crie um diretório em app/policies/business/
  # 2. Crie a policy que herda de BasePolicy
  # 3. Registre as implementações
  # 4. Crie as classes de implementação
  #
  # == Exemplo: BonusPolicy (cálculo de bonus em reciclagens)
  #
  #   # app/policies/business/bonus/bonus_policy.rb
  #   module Business
  #     module Bonus
  #       class BonusPolicy < BasePolicy
  #         register :default, DefaultBonus
  #         register :percentual, PercentualBonus
  #
  #         def self.env_key = "BONUS_POLICY"
  #       end
  #     end
  #   end
  #
  #   # app/policies/business/bonus/default_bonus.rb
  #   module Business
  #     module Bonus
  #       class DefaultBonus
  #         # Usa valor fixo do campo bonus_valor
  #         def calculate(reciclagem_recurso)
  #           reciclagem_recurso.bonus_valor
  #         end
  #
  #         def calculate_total(reciclagem)
  #           reciclagem.reciclagem_recursos.sum(:bonus_valor)
  #         end
  #       end
  #     end
  #   end
  #
  #   # app/policies/business/bonus/percentual_bonus.rb
  #   module Business
  #     module Bonus
  #       class PercentualBonus < DefaultBonus
  #         # Calcula bonus como percentual da quantidade
  #         def calculate(reciclagem_recurso)
  #           quantidade = reciclagem_recurso.quantidade
  #           percentual = reciclagem_recurso.bonus_percentual.to_f / 100
  #           quantidade * percentual * taxa_por_kg
  #         end
  #
  #         private
  #
  #         def taxa_por_kg
  #           0.50 # R$ 0,50 por kg
  #         end
  #       end
  #     end
  #   end
  #
  # == Uso no código
  #
  #   # No model ou service:
  #   def total_bonus
  #     Business::Bonus::BonusPolicy.for.calculate_total(self)
  #   end
  #
  #   # Ou diretamente:
  #   bonus = Business::Bonus::BonusPolicy.for
  #   valor = bonus.calculate(reciclagem_recurso)
  #
  # == Configuração via ENV
  #
  #   # .env.app_a
  #   BONUS_POLICY=default
  #
  #   # .env.app_b
  #   BONUS_POLICY=percentual
  #
  class BasePolicy
    class << self
      # Registra implementações disponíveis
      # @param name [Symbol] identificador da implementação
      # @param klass [Class] classe que implementa a policy
      def register(name, klass)
        implementations[name.to_sym] = klass
      end

      # Hash de implementações registradas
      # @return [Hash<Symbol, Class>]
      def implementations
        @implementations ||= {}
      end

      # Retorna a implementação configurada via ENV
      # @return [Object] instância da implementação
      def for
        policy_name = ENV.fetch(env_key, "default").to_sym
        klass = implementations[policy_name] || implementations[:default]

        raise "No implementation registered for '#{policy_name}' in #{name}" unless klass

        klass.new
      end

      # Subclasses DEVEM implementar
      # @return [String] nome da ENV var que define qual implementação usar
      # @example
      #   def self.env_key = "BONUS_POLICY"
      def env_key
        raise NotImplementedError, "#{name} deve implementar self.env_key"
      end

      # Nome da policy atual (para debug/logs)
      # @return [Symbol]
      def current_policy_name
        ENV.fetch(env_key, "default").to_sym
      end
    end
  end
end
