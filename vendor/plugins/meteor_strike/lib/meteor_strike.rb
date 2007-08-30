require 'meteor_strike/controller'
require 'meteor_strike/helper'
require 'action_controller'

module MeteorStrike
  PLUGIN_ROOT = File.join(File.dirname(__FILE__), '..')
end

ActionController::Base.__send__ :include, MeteorStrike::Controller
