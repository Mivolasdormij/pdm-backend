# frozen_string_literal: true

require 'rake'
require 'json'

namespace :profile do
  desc 'Manual Import of FHIR resources'
  task :import_fhir, %i[profile_id provider_id file] => :environment do |_t, args|
    bundle_json = File.open(args.file, 'r:UTF-8').read

    receipt = DataReceipt.new(profile_id: args.profile_id,
                              provider_id: args.provider_id,
                              data_type: 'fhir_bundle',
                              data: bundle_json)

    receipt.process!
    merger = HDM::Merge:: Merger.new
    merger.update_profile(receipt.profile)
  end

  desc 'Manual Import of FHIR resources'
  task :load, %i[file] => :environment do |_t, args|
    bundle_json = File.open(args.file, 'r:UTF-8').read
    users = User.all.to_a
    providers = Provider.all.to_a
    user_indx = 0
    profile_indx = 0
    provider_indx = 0

    user_first_name = 'A'
    user_last_name = 'A'
    json_format = JSON.parse(bundle_json)
    json_format['entry'].each do |entry|
      if entry.key?('resource')
        if entry['resource'].key?('name')
          if entry['resource']['name'].length > 0
            if entry['resource']['name'][0].key?('family')
              user_last_name = entry['resource']['name'][0]['family']
            end

            if entry['resource']['name'][0].key?('given')
              if entry['resource']['name'][0]['given'].length > 0
                  user_first_name = entry['resource']['name'][0]['given'][0]
                  break
              end
            end
          end
        end
      end
    end
    user_email = user_first_name + "_" + user_last_name[0] + "@gmail.com"
    user_password = 'Password123'
    User.create(first_name: user_first_name, last_name: user_last_name, email: user_email, password: user_password)

    if users.length > 1
      puts 'Select which user you want to load the data for '
      users.each_with_index { |u, i| puts "#{i}. #{u.email}" }
      user_indx = STDIN.gets.chomp.to_i
    else
      puts "Using only user in the system: #{users[user_indx].email}"
    end

    user = users[user_indx]
    profiles = user.profiles
    if profiles.empty?
      puts 'User has no profile, please create a profile before continuing'
      return
    elsif profiles.length > 1
      puts 'Select which profile you want to load the data into '
      profiles.each_with_index { |p, i| puts "#{i}. #{p.name}" }
      profile_indx = STDIN.gets.chomp.to_i
    else
      puts "User only has a single profile, using profile #{profiles[profile_indx.to_i].name}"
    end

    if providers.empty?
      puts 'There are no providers in the system, please load some providers before continuing'
    elsif providers.length > 1
      puts 'Select which provider you want to assocaiate the data with '
      providers.each_with_index { |p, i| puts "#{i} #{p.name}" }
      provider_indx = STDIN.gets.chomp.to_i
    else
      puts "There is only 1 provider in the system, using provider #{providers[provider_indx.to_i].name}"
    end
    profile = profiles[profile_indx.to_i]
    provider = providers[provider_indx.to_i]

    receipt = DataReceipt.new(profile_id: profile.id,
                              provider_id: provider.id,
                              data_type: 'fhir_bundle',
                              data: bundle_json)

    receipt.process!
    merger = HDM::Merge:: Merger.new
    merger.update_profile(receipt.profile)

    # select a profile
  end

  desc 'Manually Trigger Profile Sync'
  task :sync_profile, [:profile_provider_id] => :environment do |_t, args|
    pp = ProfileProvider.find(args.profile_provider_id)

    client = HDM::Client.get_client(pp.provider)
    client.sync_profile(pp)

    DataReceipt.where(profile: pp.profile).each(&:process!)
    HDM::Merge:: Merger.new.update_profile(pp.profile)
  end
end
