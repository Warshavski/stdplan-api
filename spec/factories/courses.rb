# frozen_string_literal: true

FactoryBot.define do
  factory :course, class: Course do
    title  { Faker::Lorem.sentence(2) }

    group

    trait :with_lecturers do
      after(:create) do |course, _|
        course.update!(lecturers: create_list(:lecturer, 1, group: course.group))
      end
    end
  end

  factory :course_params, class: Hash do
    initialize_with do
      {
        type: 'course',
        attributes: {
          title: Faker::Educator.course,
        }
      }
    end
  end

  factory :invalid_course_params, class: Hash do
    initialize_with do
      {
        type: 'course',
        attributes: {
          title: nil
        }
      }
    end
  end
end