# frozen_string_literal: true

# IdentitySerializer
#
#   Used for the user oauth providers data representation
#     (sign in info via social networks)
#
class IdentitySerializer < ApplicationSerializer
  set_type :identity

  attributes :provider, :created_at, :updated_at
end
