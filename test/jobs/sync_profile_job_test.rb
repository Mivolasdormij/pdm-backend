# frozen_string_literal: true

require 'test_helper'

class SyncProfileJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper
  def load_bundle(name)
    File.read(File.join(__dir__, "../fixtures/dstu2_files/bundles/#{name}.json"))
  end

  test 'that profile provider is synced' do
    fake_body = File.read(File.join(__dir__, '../fixtures/dstu2_files/ouath_capability_statement.json'))
    FakeWeb.register_uri(:post, %r{http://partners.com/oauth/token}, body: { access_token: 'new token', expires_in: 3600 }.to_json, content_type: 'application/json')
    FakeWeb.register_uri(:get, %r{http://partners.com/smart/metadata}, body: fake_body, content_type: 'application/json')
    FakeWeb.register_uri(:get, %r{http://partners.com/smart/Observation}, body: load_bundle('search-set'), content_type: 'application/json')
    FakeWeb.register_uri(:get, %r{http://partners.com/smart/Patient}, body: '{}', content_type: 'application/json')
    FakeWeb.register_uri(:get, %r{http://partners.com/smart/Encounter}, body: '{}', content_type: 'application/json')
    FakeWeb.register_uri(:get, %r{http://partners.com/smart/MedicationAdminstration}, body: '{}', content_type: 'application/json')
    FakeWeb.register_uri(:get, %r{http://partners.com/smart/MedicationOrder}, body: '{}', content_type: 'application/json')
    FakeWeb.register_uri(:get, %r{http://partners.com/smart/MedicationStatement}, body: '{}', content_type: 'application/json')
    FakeWeb.register_uri(:get, %r{http://partners.com/smart/Device}, body: '{}', content_type: 'application/json')
    FakeWeb.register_uri(:get, %r{http://partners.com/smart/Immunization}, body: '{}', content_type: 'application/json')
    FakeWeb.register_uri(:get, %r{http://partners.com/smart/Condition}, body: '{}', content_type: 'application/json')
    FakeWeb.register_uri(:get, %r{http://partners.com/smart/Encounter}, body: '{}', content_type: 'application/json')

    pp = profile_providers(:harry_partners)
    raw_resource_count = pp.profile.resources.count
    resource_count = pp.profile.all_resources.length
    count = DataReceipt.count()
    SyncProfileJob.perform_now(pp.profile)
    # ensure that the profile_provider was syned as part of the profile being synced
    assert DataReceipt.count > count
    assert pp.profile.resources.count > raw_resource_count
    assert pp.profile.all_resources.length > resource_count
  end

  test 'that the profile is broadcast following the job' do
    profile = profiles(:smart_sandbox)
    assert_broadcast_on(profile, profile.bundle_everything, channel: UpdateChannel) do
      # also ensure only a single broadcast, not one per profile, since the SyncProfileProviderJob can broadcast too
      assert_broadcasts(profile, 1, channel: UpdateChannel) do
        SyncProfileJob.perform_now(profile, false)
      end
    end
  end
end
