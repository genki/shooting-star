module FormEncoder
  def self.encode(parameters, prefix = "")
    case parameters
    when Hash; encode_hash(parameters, prefix)
    when Array; encode_array(parameters, prefix)
    else "#{prefix}=#{CGI.escape(parameters.to_s)}"
    end
  end

private
  def self.encode_hash(hash, prefix)
    hash.inject([]) do |result, (key, value)|
      key = CGI.escape(key.to_s)
      result << encode(value, prefix.empty? ? key : "#{prefix}[#{key}]")
    end.join('&')
  end

  def self.encode_array(array, prefix)
    array.inject([]) do |result, value|
      result << encode(value, "#{prefix}[]")
    end.join('&')
  end
end
