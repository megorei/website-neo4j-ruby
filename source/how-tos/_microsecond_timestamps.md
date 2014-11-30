Neo4j is currently persisting timestamps as integers in the database. As you can guess integer timestamps have second precision.

![Integer Timestamps](/images/integer_timestamps.png)

If you want persisted timestamps to have higher precision it's better to save them as float or string.


Here is a sample code how to make it:

app/models/your_model.rb

~~~ ruby
class YourModel
  include Neo4j::ActiveNode
  property :created_at, type: MicrosecondTimestamp, typecaster: MicrosecondTimestampTypecaster.new
  property :updated_at, type: MicrosecondTimestamp, typecaster: MicrosecondTimestampTypecaster.new

  serialize :created_at, MicrosecondTimestamp
  serialize :updated_at, MicrosecondTimestamp
end
~~~

app/ext/microsecond_timestamp.rb

~~~ ruby
class MicrosecondTimestamp
  def initialize(*args)
    timestamp = args.first
    if timestamp.is_a?(Date) or timestamp.is_a?(Time)
      @timestamp = timestamp.to_datetime
    elsif timestamp.is_a?(Numeric)
      @timestamp = Time.at(timestamp).to_datetime
    else
      @timestamp = DateTime.new(*args)
    end
  end

  def to_s
    @timestamp.iso8601(6)
  end

  def inspect
    to_s
  end

  def method_missing(method, *args)
    @timestamp.send(method, *args)
  end
end
~~~

app/ext/neo4j/shared/type_converters.rb

~~~ ruby
module Neo4j::Shared::TypeConverters
  # Converts timestamps with microsecond precision
  class MicrosecondTimestampConverter
    class << self

      def convert_type
        MicrosecondTimestamp
      end

      def to_db(value)
        return nil if value.nil?
        value.to_time.to_datetime.iso8601(6)
      end

      def to_ruby(value)
        return nil if value.nil?
        MicrosecondTimestamp.new(DateTime.parse(value))
      end
    end
  end
end
~~~

app/ext/microsecond_timestamp_typecaster.rb

~~~ ruby
class MicrosecondTimestampTypecaster
  def call(value)
    value
  end
end
~~~
