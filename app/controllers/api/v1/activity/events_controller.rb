# frozen_string_literal: true

module Api
  module V1
    module Activity
      # Api::V1::Activity::EventsController
      #
      #   Used to manage authenticated user activity events
      #     (activity feed)
      #
      class EventsController < ApplicationController
        specify_title_header 'Activity', 'Events'

        specify_serializers default: ActivityEventSerializer

        # GET : api/v1/activity/events
        #
        #   optional filter parameters :
        #
        #     - action - Filter by activity events by action(created, updated)
        #
        # @see #filter_params
        #
        # Get list of authenticate user activity events
        #
        def index
          activity_feed = filter_events(filter_params).preload(:target)

          render_collection activity_feed,
                            include: [:target],
                            status: :ok
        end

        private

        def filter_events(filters = {})
          ActivityEventsFinder.call(context: current_user, params: filters)
        end

        def filter_params
          super(::Activity::Events::IndexContract)
        end
      end
    end
  end
end
