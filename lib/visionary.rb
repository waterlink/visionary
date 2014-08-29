require "visionary/version"
require "visionary/future"
require "visionary/promise"

module Visionary
  def self.setup!
    Future.setup!
    Promise.setup!
  end
end
