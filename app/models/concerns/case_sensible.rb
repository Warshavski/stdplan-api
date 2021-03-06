# frozen_string_literal: true

# CaseSensitivity
#
#   Concern for querying columns with specific case sensitivity handling.
#
module CaseSensible
  extend ActiveSupport::Concern

  # Queries the given columns regardless of the casing used.
  #
  # Unlike other ActiveRecord methods this method only operates on a Hash.
  #
  module ClassMethods
    # @param params [Hash] conditions(key - value)
    #
    # @return [ApplicationRecord]
    #
    def iwhere(params)
      criteria = self

      params.each do |key, value|
        criteria = criteria.where(resolve_condition(key, value))
      end

      criteria
    end

    private

    def resolve_condition(key, value)
      value.is_a?(Array) ? value_in(key, value) : value_equal(key, value)
    end

    def value_equal(column, value)
      lower_value = lower_value(value)

      lower_column(arel_table[column]).eq(lower_value).to_sql
    end

    def value_in(column, values)
      lower_values = values.map(&method(:lower_value))

      lower_column(arel_table[column]).in(lower_values).to_sql
    end

    def lower_value(value)
      Arel::Nodes::NamedFunction.new('LOWER', [Arel::Nodes.build_quoted(value)])
    end

    def lower_column(column)
      column.lower
    end
  end
end
