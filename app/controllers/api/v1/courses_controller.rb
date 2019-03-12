# frozen_string_literal: true

module Api
  module V1
    # Api::V1::CoursesController
    #
    #   Used to control courses in the scope of the group
    #
    #   Regular group member's actions:
    #
    #     - list available courses
    #     - get information about particular course
    #
    #   Group owner actions:
    #
    #     - regular group member's actions
    #     - create a new course
    #     - update information about particular course
    #     - delete particular course
    #
    class CoursesController < ApplicationController
      set_default_serializer CourseSerializer

      before_action :authorize_edit!, only: %i[create update destroy]

      # GET : api/v1/group/courses
      #
      # Get list of courses
      #
      def index
        courses = filter_courses.eager_load(:lecturers)

        render_json courses, status: :ok
      end

      # GET : api/v1/group/courses/{:id}
      #
      # Get course by id (information about course)
      #
      def show
        course = filter_courses.find(params[:id])

        render_json course, status: :ok
      end

      # POST : api/v1/group/courses
      #
      # Create new course
      #
      def create
        course = current_group.courses.create!(course_params)

        render_json course, status: :created
      end

      # PATCH/PUT : api/v1/group/courses/{:id}
      #
      # Update course(information about course)
      #
      def update
        course = filter_courses.find(params[:id])

        course.update!(course_params)

        render_json course, status: :ok
      end

      # DELETE : api/v1/group/courses/{:id}
      #
      # Delete course
      #
      def destroy
        course = filter_courses.find(params[:id])

        course.destroy!

        head :no_content
      end

      private

      def authorize_edit!
        return if current_student.group_owner?

        raise Elplano::Errors::AuthError, 'Edit not allowed'
      end

      def filter_courses
        current_group&.courses || Course.none
      end

      def course_params
        restify_param(:course)
          .require(:course)
          .permit(:title, lecturer_ids: [])
      end
    end
  end
end