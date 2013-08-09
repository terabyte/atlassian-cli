
# add deep_symbolize_keys
Hash.class_eval do
  def deep_symbolize_keys
    # symbolize keys
    newhash = self.dup
    newhash.keys.each do |key|
      newhash[(key.to_sym rescue key) || key] = newhash.delete(key)
    end
    # deep
    newhash.each_entry do |k,v|
      if v.is_a?(Hash)
        newhash[k] = v.deep_symbolize_keys
      elsif v.is_a?(Array)
        v.each_index do |i|
          if newhash[k][i].is_a?(Hash) || newhash[k][i].is_a?(Array)
            newhash[k][i] = newhash[k][i].deep_symbolize_keys
          end
        end
      end
    end
    newhash
  end

  # Create a hash with autovivification, whee!
  # SEE: http://stackoverflow.com/questions/1503671/ruby-hash-autovivification-facets
  def self.auto_vivifying_hash(*args)
    new(*args) {|hash,key| hash[key] = Hash.new(&hash.default_proc) }
  end
end

Array.class_eval do
  def deep_symbolize_keys
    # symbolize keys in any hashes
    myarray = self.dup
    myarray.each_index do |i|
      if myarray[i].is_a?(Hash)
        myarray[i] = myarray[i].deep_symbolize_keys
      elsif myarray[i].is_a?(Array)
        myarray[i] = myarray[i].deep_symbolize_keys
      end
    end
    myarray
  end
end

# http://stackoverflow.com/questions/3673607/how-do-i-submit-a-boolean-parameter-in-rails
String.class_eval do
  def to_bool
    return true if ['true', '1', 'yes', 'on', 't'].include? self.downcase
    return false if ['false', '0', 'no', 'off', 'f'].include? self.downcase
    return nil
  end

  # starts_with? isn't always available, so fix that.
  if !String.respond_to? :starts_with?
    def starts_with?(prefix)
      prefix = prefix.to_s
      self[0,prefix.length] == prefix
    end
  end
end
TrueClass.class_eval do
  def to_bool
    return self
  end
end
FalseClass.class_eval do
  def to_bool
    return self
  end
end
NilClass.class_eval do
  def to_bool
    return self
  end
end

