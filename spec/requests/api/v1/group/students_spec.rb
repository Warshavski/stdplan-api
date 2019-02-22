require 'rails_helper'

RSpec.describe 'Students management', type: :request do
  include_context 'shared setup'

  let(:base) { '/api/v1/group/students' }

  let_it_be(:student)   { create(:student, :group_member, user: user) }

  subject { get endpoint, headers: headers }

  before(:each) { subject }

  describe 'GET #index' do
    let(:endpoint) { base }

    context 'authorized user' do
      it { expect(response).to have_http_status(:ok) }

      it { expect(body_as_json[:data].count).to eq(1) }
    end

    context 'anonymous user' do
      let(:headers) { nil }

      it { expect(response).to have_http_status(:unauthorized) }
    end
  end

  describe 'GET #show' do
    let(:endpoint)  { "#{base}/#{student.id}" }

    context 'anonymous user' do
      let(:headers) { nil }

      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'authorized user' do
      it 'responds with a 200 status' do
        expect(response).to have_http_status(:ok)
      end

      include_examples 'json:api examples',
                       %w[data included],
                       %w[id type attributes relationships],
                       %w[full_name email phone about president social_networks created_at updated_at],
                       %w[user group]


      context 'not existed group member' do
        let(:user) { create(:student, :group_member).user }
        let(:endpoint) { "#{base}/0" }

        it { expect(response).to have_http_status(:not_found) }
      end
    end
  end
end