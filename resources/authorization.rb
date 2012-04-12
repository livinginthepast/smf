actions :apply, :define

def self.permissions
  @permissions ||= {}
end

def self.definitions
  @definitions ||= []
end
