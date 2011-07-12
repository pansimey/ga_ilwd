class Utterance
  @@eliza = Eliza.new
  def self.parse(string)
    self.new(string)
  end

  def initialize(string)
    @string = string
  end

  def to_s
    @string
  end

  def succ
    self.class.parse(@@eliza.response(@string))
  end
end
