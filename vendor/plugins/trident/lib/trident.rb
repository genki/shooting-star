module Trident
  def self.reload
    system 'killall -INT autotest'
  end
end
