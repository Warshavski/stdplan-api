# frozen_string_literal: true

require 'acceptance_helper'

resource "User's event tasks" do
  explanation <<~DESC
    El Plano event tasks API(creates for group event by group owner).

    #{Descriptions::Model.task}
  
    #{Descriptions::Model.attachment}

    #{Descriptions::Model.event}

    #{Descriptions::Model.assignment}
  DESC

  let_it_be(:student)   { create(:student, :group_supervisor) }
  let_it_be(:classmate) { create(:student, group: student.group) }
  let_it_be(:course)    { create(:course, group: student.group) }
  let_it_be(:labels)    { [create(:label)] }

  let_it_be(:event) do
    create(:event, eventable: student.group, labels: labels, creator: student, course: course)
  end

  let_it_be(:task)        { create(:task, event: event, author: student)}
  let_it_be(:assignment)  { create(:assignment, student: student, task: task) }

  let_it_be(:id) { task.id }

  let_it_be(:user)  { student.user }
  let_it_be(:token) { create(:token, resource_owner_id: user.id).token }
  let_it_be(:authorization) { "Bearer #{token}" }

  let_it_be(:file) { fixture_file_upload('spec/fixtures/files/dk.png') }
  let_it_be(:metadata) { AttachmentUploader.new(:cache).upload(file) }

  let_it_be(:external_links) do
    %w[Google DropBox].map do |description|
      { description: description, url: Faker::Internet.url }
    end
  end

  let_it_be(:attachment) do
    create(:attachment, author: user, attachable: task, attachment_data: metadata)
  end

  header 'Accept',        'application/vnd.api+json'
  header 'Content-Type',  'application/vnd.api+json'
  header 'Authorization', :authorization

  get 'api/v1/tasks' do
    example 'INDEX : Retrieve tasks list' do
      explanation <<~DESC
        Returns a list of the available tasks.

        <b>OPTIONAL FILTERS</b> :

          - `"event_id": 1` - Returns tasks for the selected event.
          - `"expiration": - Returns tasks filtered by expiration scope(#{Task::EXPIRATION_SCOPES}).
          - `"appointed": true/false` - Returns appointed or authored tasks.
          - `"accomplished": true/false` - Returns accomplished or unfulfilled tasks.

        Example: 

        <pre>
        {
          "filters": {
            "event_id": 1,
            "expiration": "active",
            "appointed": false,
            "accomplished": false
          }
        }
        </pre>

        <b>MORE INFORMATION</b> :
        
          - See model attribute description in section description.
          - See "Filters" and "Pagination" sections in the README section for more details. 

        <b>NOTES<b> :

          - By default, this endpoint returns tasks sorted by recently created.
          - By default, this endpoint returns tasks without expiration date assumptions.
          - By default, this endpoint returns authored tasks.
          - By default, this endpoint returns tasks limited by 15
          - Accomplishment filter can be applied only to appointed tasks
            (in the case when only "accomplished" filter set with value "true" this endpoint will return appointed tasks)
      DESC

      do_request

      expected_body = TaskSerializer
                        .new([task], params: { exclude: [:attachments] })
                        .to_json

      expect(status).to eq(200)
      expect(response_body).to eq(expected_body)
    end
  end

  get 'api/v1/tasks/:id' do
    example 'SHOW : Retrieve detailed information about requested task' do
      explanation <<~DESC
        Returns a single instance of the task.

        <b>MORE INFORMATION</b> :

          - See model attribute description in section description.

        <b>NOTES</b> :

           - Also, includes information about related event and attachments.
      DESC

      do_request

      expected_body = TaskSerializer
                        .new(task, include: %i[event attachments])
                        .to_json

      expect(status).to eq(200)
      expect(response_body).to eq(expected_body)
    end
  end

  post 'api/v1/tasks' do
    with_options scope: %i[task] do
      parameter :title, 'Task title(human readable identity)',
                required: true

      parameter :description, 'Task detailed description or assigment itself'
      parameter :expired_at, 'Task expiration timestamp'

      parameter :event_id, 'Event which task is attached to',
                required: true

      parameter :external_links, 'Extra attachments on external storage(Google drive, for example)'

      parameter :attachments, 'Uploaded files metadata(collection) received from `uploads` endpoint'

      parameter :student_ids, 'Collection of the students who are assigned to the task',
                required: true
    end

    let(:raw_post) do
      params = build(:task_params).merge(
        event_id: event.id,
        attachments: [metadata.to_json],
        student_ids: [classmate.id],
        external_links: external_links
      )

      { task:  params }.to_json
    end

    example 'CREATE : Create a new event task' do
      explanation <<~DESC
        Creates and returns created event task.
        
        <b>MORE INFORMATION</b> :
        
          - See model attribute description in section description.
          - See `uploads` endpoint description for more info.

        <b>NOTES</b> :
 
          - This action allowed for any student, but regular group member can 
            create only self-assigned tasks for own events(self-assigned events)
            Group owner(group president) doesn't have such restrictions).
          - Also, includes information about related event and attachments.
      DESC

      do_request

      expected_body = TaskSerializer
                        .new(event.tasks.last, include: %i[event attachments])
                        .to_json

      expect(status).to eq(201)
      expect(response_body).to eq(expected_body)
    end
  end

  put 'api/v1/tasks/:id' do
    with_options scope: %i[task] do
      parameter :title, 'Task title(human readable identity)',
                required: true

      parameter :description, 'Task detailed description or assigment itself'
      parameter :expired_at, 'Task expiration timestamp'

      parameter :event_id, 'Event which task is attached to',
                required: true

      parameter :external_links, 'Extra attachments on external storage(Google drive, for example)'

      parameter :student_ids, 'Collection of the students who are assigned to the task',
                required: true
    end

    let(:raw_post) do
      {
        task: build(:task_params)
                .merge(event_id: event.id, student_ids: [classmate.id], external_links: external_links)
      }.to_json
    end

    example 'UPDATE : Update selected task information' do
      explanation <<~DESC
        Updates and return updated task.

        <b>MORE INFORMATION</b> :

          - See model attribute description in section description.

        <b>NOTES</b> :
 
          - This action allowed only for authored tasks.
          - Also, includes information about related event and attachments.
      DESC

      do_request

      expected_body = TaskSerializer
                        .new(task.reload, include: %i[event attachments])
                        .to_json

      expect(status).to eq(200)
      expect(response_body).to eq(expected_body)
    end
  end

  delete 'api/v1/tasks/:id' do
    example 'DELETE : Delete selected event task' do
      explanation <<~DESC
        Deletes event task.

        <b>NOTES</b> :

          - This action allowed only for authored tasks.
      DESC

      do_request

      expect(status).to eq(204)
    end
  end

  get 'api/v1/tasks/:id/assignment' do
    example 'SHOW : Show assignment information' do
      explanation <<~DESC
        Get detailed information about task assignment

        <b>MORE INFORMATION</b> :

          - See model attribute description in section description.
      DESC

      do_request

      expected_data = AssignmentSerializer.new(assignment).to_json

      expect(status).to eq(200)
      expect(response_body).to eq(expected_data)
    end
  end

  put 'api/v1/tasks/:id/assignment' do
    with_options scope: :assignment do
      parameter :report, 'Detailed task accomplishment description'
      parameter :accomplished, '`true` if assignment is accomplished(done), otherwise `false`'
      parameter :extra_links, 'Links(URL) to extra attachments on external storage(Google drive, for example)'
      parameter :attachments, 'Attachments. Uploaded files metadata(collection) received from `uploads` endpoint'
    end

    let(:raw_post) do
      {
        assignment:
          {
            attachments: [metadata.to_json],
            report: Faker::Lorem.paragraph(sentence_count: 6),
            accomplished: true,
            external_links: external_links
          }
      }.to_json
    end

    example 'UPDATE : Accomplish event task' do
      explanation <<~DESC
        Mark event task as accomplished and create report about accomplishment.

        <b>MORE INFORMATION</b> :

          - See model attribute description in section description.
      DESC

      do_request

      expected_data = AssignmentSerializer.new(assignment.reload).to_json

      expect(status).to eq(200)
      expect(response_body).to eq(expected_data)
    end
  end

  get 'api/v1/tasks/statistics' do
    let_it_be(:expected_stats) do
      {
        outdated_count: 4,
        today_count: 2,
        tomorrow_count: 3,
        upcoming_count: 12,
        accomplished_count: 10
      }
    end

    before do
      allow(::Tasks::Statistics).to receive(:call).and_return(expected_stats)
    end

    example 'SHOW : Retrieves tasks statistics' do
      explanation <<~DESC
        Returns a metadata with different counters.

        #{Descriptions::Model.tasks_statistics_meta}
      DESC

      do_request

      expected_meta = { meta: expected_stats }

      expect(status).to eq(200)
      expect(response_body).to eq(expected_meta.to_json)
    end
  end
end
