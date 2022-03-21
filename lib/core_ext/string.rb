class String
  Alpha26 = ('A'..'Z').to_a

  def to_i_alpha
    result = 0
    upcase!

    (1..length).each do |i|
      char = self[-i]
      result += 26**(i - 1) * (Alpha26.index(char) + 1)
    end

    result
  end
end
