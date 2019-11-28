class TempHistory
  attr_reader :data, :tag, :data_max_size
  def initialize(tag = "history#{rand(100)}", data_max_size: nil)
    @tag = tag
    @data = []
    @data_max_size = data_max_size
  end

  # will insert into data in sorted way
  def insert(price)
    data << price
    data.shift if data_max_size && (data.size > data_max_size)
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
      "---------- (#{tag}) -----------".blue,
      {
        updated_at: updated_at,
        data: "[#{min}..#{max}] (size: #{size} / #{data_max_size})",
        mean: mean,
        most_frequent: most_frequent,
      }.awesome_inspect(indent: -4, index: false, ruby19_syntax: true),
    ].join("\n")
  end

  def to_s
    inspect
  end

  delegate :min, to: :data
  delegate :max, to: :data
  delegate :size, to: :data
  delegate :clear, to: :data
end
