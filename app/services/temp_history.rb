class TempHistory
  attr_reader :data, :tag, :data_max_size, :updated_at
  def initialize(tag = "history#{rand(100)}", data_max_size: nil)
    @tag = tag
    @data = []
    @data_max_size = data_max_size
    @updated_at = nil
  end

  # When reaching max size, will pop the oldest data
  # when price is the same, then choose not to insert
  def insert(price)
    return if price == data.last

    data << price
    data.shift if data_max_size && (data.size > data_max_size)

    @updated_at = Time.zone.now
  end

  # @return [Array] array of most frequent price
  def most_frequent
    # Use integer so that it's helpful for gathering
    # TODO: can determin the rounding
    frequency = data.each_with_object(Hash.new(0)) { |v, h| h[v.to_i] += 1; }

    # Map to the portion
    frequency = frequency.map { |k, v| [k, (v.to_d / data.size).round(2)] }.to_h
    max = frequency.values.max
    frequency.select { |_, f| f == max }
  end

  def mean
    (data.sum / size).round(2)
  rescue => e
    0
  end

  def inspect
    [
      "---------- (#{tag}) -----------".blue,
      {
        updated_at: updated_at,
        data: "[#{min} .. #{max}] (size: #{size} / #{data_max_size})",
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
