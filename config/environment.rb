# Be sure to restart your server when you modify this file
# RAILS_ENV = 'production'
# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"

	config.gem 'calendar_date_select'
	config.gem 'will_paginate'
	config.gem 'holidays'
	config.gem 'american_date'
	config.gem 'spreadsheet'
	config.gem 'fastercsv', :version => '1.5.1'
	config.gem 'mail'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  # config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

require 'usstate'
require 'hash_ext'
require 'number_ext'
require 'datetime_ext'
require 'bool_ext'
require 'tempfile'
require 'tempfile_ext'
require 'db'
require 'net/http'
require 'net/https'
require 'rexml/document'
require 'base64'
require 'spreadsheet'
require 'net/pop'
require 'net/ftp'
require 'shellwords'

#require 'twitter'
#require 'oauth' 
require 'twitter_oauth'
require 'koala' #Facebook

CalendarDateSelect.format = :american

Rack::Utils.key_space_limit = 262144

class ActiveRecord::Base
	
	attr :http_posted, true
	attr :http_posted_by, true
	
end

if RUBY_VERSION =~ /1.9/
	Encoding.default_external = Encoding::UTF_8
	Encoding.default_internal = Encoding::UTF_8
end

ExceptionNotifier.exception_recipients = %w(jessesternberg@monroecounty.gov rgrape@monroecounty.gov sduritza@monroecounty.gov)
ExceptionNotifier.sender_address = %("MCCS Error" <mccs@monroecounty.gov>)

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings[:address] = '10.100.224.102' #'173.84.13.11' #'66.192.47.11'
ActionMailer::Base.raise_delivery_errors = true
#ActionMailer::Base.delivery_method = :sendmail
#ActionMailer::Base.sendmail_settings[:arguments] = '-i -t -fwebmaster@monroecounty.gov'



# Fix calendar date select to accept 2-digit years.
class Date 
	class << self 
		def _parse_with_auto_year_adjust(str, comp=false) 
			elem = _parse_without_auto_year_adjust(str, comp=false) 
			if elem[:year] && (0..100).include?(elem[:year]) 
				elem[:year] += 1900 
				elem[:year] += 100 if elem[:year] < 1969 
			end
			elem 
		end

		alias_method_chain :_parse, :auto_year_adjust
	end
end 

if RAILS_ENV == 'development'
	FACEBOOK_KEY = '1549656988650169'
	FACEBOOK_SECRET = 'cca686f8fc318d3dc81a5432c11176b9'
	TWITTER_KEY = 'q6WnT3FFkQbXlfSDbEGXukqLY'
	TWITTER_SECRET = 'JYTxpu7IdIX9tcyuH64Q7rntPtOEJccyAagcTGQwq21GT3Uvo6'
else
	FACEBOOK_KEY = '1549656988650169'
	FACEBOOK_SECRET = 'cca686f8fc318d3dc81a5432c11176b9'
	TWITTER_KEY = 'q6WnT3FFkQbXlfSDbEGXukqLY'
	TWITTER_SECRET = 'JYTxpu7IdIX9tcyuH64Q7rntPtOEJccyAagcTGQwq21GT3Uvo6'
end
	

