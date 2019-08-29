# frozen_string_literal: true

module Api
  module V1
    module Group
      # Api::V1::Group::StudentsController
      #
      #   User to control group members(students in group)
      #
      #     - show group members
      #     - find group member by id
      #
      class StudentsController < ApplicationController
        set_default_serializer StudentSerializer

        denote_title_header 'Group', 'Students'

        # GET : api/v1/group/students
        #
        # Get list of group members
        #
        def index
          students = filter_students

          render_resource students,
                          params: { exclude: [:group] },
                          status: :ok
        end

        # GET : api/v1/group/students/{:id}
        #
        # Get group member by id
        #
        def show
          student = filter_students.find(params[:id])

          render_resource student, include: [:user], status: :ok
        end

        private

        def filter_students
          current_group.students
        end
      end
    end
  end
end
