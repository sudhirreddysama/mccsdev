# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_mccs_session' + (RAILS_ENV == 'development' ? 'dev' : ''),
  :secret      => '30eaa43e6eff615814adda2a6fa31e65e5aa15adf3e27d3a0ed2d0b25120ad00c9c4aa2e225e97a89c65ea89711882c2d7a44002691ad92c811149a956cc2604'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
