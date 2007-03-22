module ShootingStar
  class Config
    def initialize(hash)
      @hash = hash.keys.inject({}) do |new_hash, key|
        new_hash[key.to_s] = hash[key]
        new_hash
      end
    end

    def merge!(hash)
      hash.keys.each{|key| @hash[key.to_s] = hash[key]}; self
    end

    def method_missing(method, *arg, &block)
      value = @hash[method.to_s]
      value.is_a?(Hash) ? Config.new(value) : value
    end
  end
end
