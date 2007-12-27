# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  unless  RAILS_ENV == 'test'
    protect_from_forgery :secret => 'e65eec458488a6408ce041992454d14b'
  end
end
