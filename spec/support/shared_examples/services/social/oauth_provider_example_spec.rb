RSpec.shared_examples 'oauth login provider' do
  context 'user registration' do
    it 'is expected to create a new user' do
      expect { subject }.to change(User, :count).by(1)
    end

    it 'is expected to create a new identity' do
      expect { subject }.to change(Identity, :count).by(1)
    end

    it 'is expected to create a new student' do
      expect { subject }.to change(Student, :count).by(1)
    end

    it 'is expected to return an identity class' do
      expect(subject).to be_instance_of(Identity)
    end

    it 'is expected to not sent confirmation email' do
      expect { subject }.not_to(have_enqueued_job(ActionMailer::DeliveryJob))
    end
  end

  context 'existed user login' do
    let!(:user) { create(:user, :student, email: email) }

    it 'is expected to not create a new user' do
      expect { subject }.not_to change(User, :count)
    end

    it 'is expected to create a new identity' do
      expect { subject }.to change(Identity, :count).by(1)
    end

    it 'is expected to return an identity instance' do
      expect(subject).to be_instance_of(Identity)
    end
  end

  context 'when user and identity are already exist' do
    let!(:user)      { existed_user }
    let!(:identity)  { existed_identity }

    it 'is expected to not create a new user' do
      expect { subject }.not_to change(User, :count)
    end

    it 'is expected to not create a new identity' do
      expect { subject }.not_to change(Identity, :count)
    end

    it 'is expected to return identity instance' do
      is_expected.to be_instance_of(Identity)
    end
  end

  context 'when provider request raises an error' do
    before do
      allow(oauth_client).to(
        receive_message_chain(:auth_code, :get_token)
          .with(code, redirect_uri: redirect_uri)
          .and_raise OAuth2::Error.new(double('response', 'error=': {}, parsed: {}, body: '{}'))
      )
    end

    it 'is expected to reraise an api error' do
      expect { subject }.to raise_error(Api::UnprocessableAuth)
    end
  end
end
