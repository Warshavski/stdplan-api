require 'rails_helper'

#
#   api_v1_admin_system_health GET    /api/v1/admin/system/health(.:format)      api/v1/admin/system/health#show {:format=>"json"}
#
describe Api::V1::Admin::System::HealthController, 'routing' do
  it 'routes to #show' do
    expect(get('api/v1/admin/system/health')).to(
      route_to('api/v1/admin/system/health#show', format: 'json')
    )
  end
end
