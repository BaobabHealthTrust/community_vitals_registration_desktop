# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.5' unless defined? RAILS_GEM_VERSION
CVR_VERSION = `git describe`.gsub(/\n/, '')

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
	config.frameworks -= [ :action_web_service, :action_mailer, :active_resource ]
	config.log_level = :debug
	config.action_controller.session_store = :active_record_store
	config.active_record.schema_format = :sql
	# config.time_zone = 'UTC'
	config.gem 'warden'
	config.gem 'devise'
	config.gem 'will_paginate', :version => '~> 2.3.16'  
	config.action_controller.session = {
		:session_key => 'bart_session',
		:secret      => '8sgdhr431ba87cfd9bea177ba3d344a67acb0f179753f37d28db8bd102134261cdb4b1dbacccb126435631686d66e148a203fac1c5d71eea6abf955a66a472ce'
	}  
end

BART_SETTINGS = YAML.load_file(File.join(Rails.root, "config", "settings.yml"))[Rails.env] rescue nil

require 'will_paginate'
require 'fixtures'
require 'composite_primary_keys'
require 'has_many_through_association_extension'
require 'bantu_soundex'
require 'json'
require 'colorfy_strings'

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'person_address', 'person_address'
  inflect.irregular 'obs', 'obs'
  inflect.irregular 'concept_class', 'concept_class'
end  

healthdata = YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['healthdata']
bart_one_data = YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['migration']
Lab.establish_connection(healthdata)
LabTestType.establish_connection(healthdata)
LabTestTable.establish_connection(healthdata)
LabPanel.establish_connection(healthdata)
LabParameter.establish_connection(healthdata)
TableLabResultList.establish_connection(healthdata)
TableLabResult.establish_connection(healthdata)
LabSample.establish_connection(healthdata)

BartOneEncounter.establish_connection(bart_one_data) # added for migration
BartOneObservation.establish_connection(bart_one_data) # added for migration
BartOneDrugOrder.establish_connection(bart_one_data) # added for migration

class Mime::Type
  delegate :split, :to => :to_s
end

# Foreign key checks use a lot of resources but are useful during development
ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS=0") if ENV['RAILS_ENV'] != 'development'
require 'will_paginate'
