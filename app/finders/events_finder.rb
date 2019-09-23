# frozen_string_literal: true

# EventsFinder
#
#   Used to search, filter, and sort the collection of student's events
#
# Arguments:
#
#   params: optional search, filter and sort parameters
#
# NOTE :
#
#   - by default returns events sorted by recently added.
#   - by default returns all appointed events(personal + group events).
#
class EventsFinder
  attr_reader :params, :student

  # @param student [Student] -
  #
  # @param params [Hash] - (optional, default: {}) filter and sort parameters
  #
  # @option params [String, Symbol] :scope -
  #   One of the events scope(appointed, authored)
  #
  # @option params [String, Symbol] :type -
  #   One of the eventable types(group, personal).
  #
  def initialize(student, params = {})
    @student = student
    @params = params
  end

  # Perform filtration and sort on student's events list
  #
  # @note by default returns all appointed events(personal + group)
  #   sorted by recently created
  #
  def execute
    collection = perform_filtration

    sort(collection)
  end

  private

  def perform_filtration
    filters = {
      'appointed' => filter_appointed,
      'authored' => filter_authored
    }

    filters.fetch(params[:scope]) { filter_appointed }
  end

  def filter_authored
    student.created_events.filter(params[:type])
  end

  def filter_appointed
    filters = {
      'group' => Event.filter('group')
                      .where(eventable_id: student.group_id),
      'personal' => Event.filter('personal')
                         .where(eventable_id: student.id)
    }

    filters.fetch(params[:type]) { filters.values.inject(&:or) }
  end

  def sort(items)
    params[:sort].blank? ? items.reorder(id: :desc) : items.order_by(params[:sort])
  end
end