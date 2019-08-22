require 'matrix'

module AffinityPropagation
  refine Array do
    def median
      relevant_elements = if size % 2 == 0
        # Even number of items in this list => let's get the middle two and return their mean
        slice(size / 2, 2)
      else
        slice(size / 2, 1)
      end

      relevant_elements.sum / relevant_elements.size
    end
  end

  refine Matrix do
    def to_matlab
      output = row_vectors.map(&:to_a).map { |row| row.join(', ') }.join('; ')

      "[#{output}]"
    end

    public :[]=
  end

  class Calculator
    using AffinityPropagation

    LAMBDA = 0.75

    attr_accessor :raw_clusters

    def initialize(data, lambda: LAMBDA, &block)
      @data = data
      @lambda = lambda

      raise 'no block provided to calculate similarities within data!' unless block_given?

      @similarities = similarity_matrix(&block)
      reset
    end

    def reset
      @raw_clusters = {}
      @stable_cluster_iterations = 0
      @total_iterations = 0

      @availabilities = Matrix.zero(@data.size, @data.size)
      @responsibilities = Matrix.zero(@data.size, @data.size)
    end

    def iterate
      @availabilities = availability_matrix
      @responsibilities = responsibility_matrix
      update_clusters

      @total_iterations += 1
    end

    def clusters
      clusters = []

      raw_clusters.each do |exemplar_id, data_ids|
        clusters << {
          exemplar: @data[exemplar_id],
          members: data_ids.map { |datum_id| @data[datum_id] }
        }
      end

      clusters
    end

    def run(iterations: 100, stable_iterations: 10)
      while @total_iterations < iterations && @stable_cluster_iterations < stable_iterations
        iterate

        yield(@total_iterations, @stable_cluster_iterations) if block_given?
      end
    end

    private

    def similarity_matrix(&block)
      similarity_array = []
      similarities = Matrix.zero(@data.size, @data.size)

      @data.size.times do |row_idx|
        @data.size.times do |col_idx|
          exemplar = @data[row_idx]
          datum = @data[col_idx]

          similarity = block.call(datum, exemplar)
          similarity_array << similarity

          similarities[row_idx, col_idx] = similarity
        end
      end

      median_similarity = similarity_array.median

      (0...@data.size).each { |idx| similarities[idx, idx] = median_similarity }

      similarities
    end

    def dampen(new_value, existing_value)
      (1 - @lambda) * new_value + @lambda * existing_value
    end

    def responsibility_matrix
      responsibilities = Matrix.zero(@similarities.row_count, @similarities.column_count)

      @similarities.row_count.times do |row_idx|
        @similarities.column_count.times do |col_idx|
          exemplar_idx = row_idx
          datum_idx = col_idx

          availability_column = @availabilities.column(col_idx).to_a
          availability_column.slice!(exemplar_idx)
          similarity_column = @similarities.column(col_idx).to_a
          similarity_column.slice!(exemplar_idx)

          availability_plus_similarity = []
          availability_column.zip(similarity_column) { |data| availability_plus_similarity << data.sum }

          responsibilities[row_idx, col_idx] = dampen(@similarities[row_idx, col_idx] - availability_plus_similarity.max, @responsibilities[exemplar_idx, datum_idx])
        end
      end

      responsibilities
    end

    def availability_matrix
      availabilities = Matrix.zero(@responsibilities.row_count, @responsibilities.column_count)

      @responsibilities.row_count.times do |row_idx|
        @responsibilities.column_count.times do |col_idx|
          exemplar_idx = row_idx
          datum_idx = col_idx
          responsibility_column = @responsibilities.row(exemplar_idx).to_a

          if exemplar_idx == datum_idx
            # self-availability
            responsibility_column.slice!(exemplar_idx)

            dampen(responsibility_column.inject(0) { |sum, item| sum += [0, item].max },@availabilities[exemplar_idx, datum_idx])
          else
            self_responsibility = @responsibilities[exemplar_idx, exemplar_idx]
            if datum_idx > exemplar_idx
              # Slice out the datum index first since in this case it won't affect the exemplar index
              responsibility_column.slice!(datum_idx)
              responsibility_column.slice!(exemplar_idx)
            else
              responsibility_column.slice!(exemplar_idx)
              responsibility_column.slice!(datum_idx)
            end

            responsibility_column_sum = responsibility_column.inject(0) { |sum, item| sum += [0, item].max }

            availabilities[row_idx, col_idx] = dampen([0, self_responsibility + responsibility_column_sum].min, @availabilities[exemplar_idx, datum_idx])
          end
        end
      end

      availabilities
    end

    def identify_raw_clusters
      clusters = {}

      @data.each_with_index do |item, datum_idx|
        availability_column = @availabilities.column(datum_idx).to_a
        responsibility_column = @responsibilities.column(datum_idx).to_a

        availability_and_responsibility = @data.size.times.map do |exemplar_idx|
          availability_column[exemplar_idx] + responsibility_column[exemplar_idx]
        end
        exemplar_idx = availability_and_responsibility.index(availability_and_responsibility.max)

        if clusters.key?(exemplar_idx)
          clusters[exemplar_idx] << datum_idx
        else
          clusters[exemplar_idx] = [datum_idx]
        end
      end

      clusters
    end

    def update_clusters
      new_clusters = identify_raw_clusters

      if new_clusters == @raw_clusters
        @stable_cluster_iterations += 1
      else
        @raw_clusters = new_clusters
        @stable_cluster_iterations = 0
      end
    end
  end
end
