# frozen_string_literal: true

module Api
  module V1
    module Users
      # Api::V1::Users::RegistrationsController
      #
      #   Used to handle new user registration
      #
      class RegistrationsController < Devise::RegistrationsController
        skip_before_action :authorize_access!

        specify_title_header 'Users', 'Registration'

        specify_serializers default: UserSerializer

        %i[cancel new edit update destroy].each do |method|
          define_method(method) { route_not_found }
        end

        # POST : api/v1/users
        #
        def create
          user = ::Users::Register.call { build_resource(sign_up_params) }

          #
          # Success but activation required
          #
          message = find_message(:"signed_up_but_#{user.inactive_message}", {})

          render_meta({ message: message }, status: :created)
        end
      end
    end
  end
end
