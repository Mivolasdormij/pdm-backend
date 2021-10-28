# frozen_string_literal: true

require 'test_helper'

class CuratedModelTest < ActiveSupport::TestCase
  include ResourceTestHelper
  test 'Can create new resources' do
    p = profiles(:harrys_profile)
    types = [AllergyIntolerance, CarePlan, Condition, Device, Encounter, Goal,
             Immunization, MedicationAdministration, MedicationOrder, MedicationStatement,
             Observation, Procedure, ExplanationOfBenefit, Claim]
    types.each do |type|
      puts "Testing create #{type}"
      snake = type.name.underscore
      create_new_success(type, p, parse_test_file("#{snake.pluralize}/#{snake}_good.json"))
    rescue StandardError
      assert false, "Error testing #{type} #{$ERROR_INFO}"
    end

    p.reload

    assert_equal p.allergy_intolerances.length, 1
    assert_equal p.care_plans.length, 1
    assert_equal p.conditions.length, 1
    assert_equal p.devices.length, 1
    assert_equal p.encounters.length, 1
    assert_equal p.immunizations.length, 1
    assert_equal p.medication_administrations.length, 1
    assert_equal p.medication_orders.length, 1
    assert_equal p.medication_statements.length, 1
    assert_equal p.observations.length, 1
  end

  test 'Should validate resource for wrong type' do
    p = profiles(:harrys_profile)
    types = [AllergyIntolerance, CarePlan, Condition, Device, Encounter, Goal,
             Immunization, MedicationAdministration, MedicationOrder, MedicationStatement,
             Observation, Procedure, ExplanationOfBenefit, Claim]
    types.each do |type|
      puts "Testing resourceType #{type}"

      mod = type.new(profile: p, resource: parse_test_file('bundles/search-set.json'))
      assert_equal false, mod.valid?, 'Should not be valid with wrond resource type'
      errors = mod.errors
      assert_equal errors['resource'], ["Wrong resource type: expected #{type.name} was Bundle"]
    rescue StandardError
      assert false, "Error testing #{type} #{$ERROR_INFO}"
    end
  end
  # Disable for now: Need to determin whether we go with DSTU2 or STU3 as a basis or
  # Need to determin how to handle both versions.
  # test 'Should validate resource based on fhir structure' do
  #   p = profiles(:harrys_profile)
  #   # Device
  #   types = [AllergyIntolerance, CarePlan, Condition, Encounter, Goal,
  #            Immunization, MedicationAdministration, MedicationRequest, MedicationStatement,
  #            Observation, Procedure]
  #   types.each do |type|
  #     begin
  #       puts "Testing invalid resource for  #{type}"
  #       snake = type.name.underscore
  #       mod = type.new(profile: p, resource: parse_test_file("#{snake.pluralize}/#{snake}_bad.json"))
  #       mod.valid?
  #       errors = mod.errors
  #       assert_equal false, mod.valid?, 'Should not be valid with invalid fhir resource'
  #       assert_not errors['resource_errors'].empty?, "Resource validation errors should be greater than 0 for #{type}"
  #     rescue StandardError
  #       assert false, "Error testing #{type} #{$ERROR_INFO}"
  #     end
  #   end
  # end
end
