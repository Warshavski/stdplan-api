# frozen_string_literal: true

module Api
  module V1
    module Admin
      # Api::V1::Admin::UsersController
      #
      #   Application's users management
      #
      class UsersController < Admin::ApplicationController
        set_default_serializer UserSerializer

        denote_title_header 'Users'

        # GET : api/v1/admin/users
        #
        #   optional filter parameters :
        #
        #     - status - Filter by the user status(active, confirmed, banned)
        #     - search - Filter by search term(email, username)
        #
        # @see #filter_params
        #
        # Get filtered list of users
        #
        def index
          users = filter_users(filter_params).preload(:student)

          render_resource users,
                          include: [:student],
                          status: :ok
        end

        # GET : api/v1/admin/users/{:id}
        #
        # Get information about selected user
        #
        def show
          user = find_user(params[:id])

          render_resource user,
                          include: [:student],
                          status: :ok
        end

        # GET : api/v1/admin/users
        #
        # Update user state
        #
        def update
          user = find_user(params[:id]).tap do |u|
            ::Admin::Users::Manage.call(u, params[:action_type])
          end

          render_resource user,
                          include: [:student],
                          status: :ok
        end

        # DELETE : api/v1/admin/users/{:id}
        #
        # Delete selected user and associated data
        #
        def destroy
          find_user(params[:id]).tap do |user|
            user.destroy! unless user == current_user
          end

          head :no_content
        end

        private

        def find_user(user_id)
          filter_users.find(user_id)
        end

        def filter_users(filters = {})
          UsersFinder.new(filters).execute
        end

        def filter_params
          validate_with(::Admin::Users::IndexContract.new, params[:filters])
        end
      end
    end
  end
end
