class TempHistory
  attr_reader :data, :tag
  def initialize(tag = "history#{rand(100)}")
    @tag = tag
    @data = []
  end

  # will insert into data in sorted way
  def insert(price)
    if data.empty?
      data << price
    else
      insert_at = data.bsearch_index { |x| x > price }
      data.insert(insert_at || -1, price)
    end
  end

  # @return [Array] array of most frequent price
  def most_frequent
    # Use integer so that it's helpful for gathering
    # TODO: can determin the rounding
    frequency = data.each_with_object(Hash.new(0)) { |v, h| h[v.to_i] += 1; }
    max = frequency.values.max
    frequency.select { |_, f| f == max }.keys
  end

  def inspect
    [
      "[#{self.class}] (:#{tag})",
      "data: [#{min}..#{max}] (size: #{size})",
      "most_frequent: #{most_frequent}",
    ].join("  \n")
  end

  def to_s
    inspect
  end

  delegate :min, to: :data
  delegate :max, to: :data
  delegate :size, to: :data
  delegate :clear, to: :data
end
