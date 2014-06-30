# JSON::Stream

JSON::Stream is a JSON parser, based on a finite state machine, that generates
events for each state change. This allows streaming both the JSON document into
memory and the parsed object graph out of memory to some other process. This
is much like an XML SAX parser that generates events during parsing. There is
no requirement for the document, or the object graph, to be fully buffered in
memory. This is best suited for huge JSON documents that won't fit in memory.
For example, streaming and processing large map/reduce views from Apache
CouchDB.

## Usage

The simplest way to parse is to read the full JSON document into memory
and then parse it into a full object graph. This is fine for small documents
because we have room for both the document and parsed object in memory.

```ruby
require 'json/stream'
json = File.read('/tmp/test.json')
obj = JSON::Stream::Parser.parse(json)
```

While it's possible to do this with JSON::Stream, we really want to use the json
gem for documents like this. JSON.parse() is much faster than this parser,
because it can rely on having the entire document in memory to analyze.

For larger documents we can use an IO object to stream it into the parser.
We still need room for the parsed object, but the document itself is never
fully read into memory.

```ruby
require 'json/stream'
stream = File.open('/tmp/test.json')
obj = JSON::Stream::Parser.parse(stream)
```

Again, while JSON::Stream can be used this way, if we just need to stream the
document from disk or the network, we're better off using the yajl-ruby gem.

Huge documents arriving over the network in small chunks to an EventMachine
receive_data loop is where JSON::Stream is really useful. Inside an
EventMachine::Connection subclass we might have:

```ruby
def post_init
  @parser = JSON::Stream::Parser.new do
    start_document { puts "start document" }
    end_document   { puts "end document" }
    start_object   { puts "start object" }
    end_object     { puts "end object" }
    start_array    { puts "start array" }
    end_array      { puts "end array" }
    key            {|k| puts "key: #{k}" }
    value          {|v| puts "value: #{v}" }
  end
end

def receive_data(data)
  begin
    @parser << data
  rescue JSON::Stream::ParserError => e
    close_connection
  end
end
```

The parser accepts chunks of the JSON document and parses up to the end of the
available buffer. Passing in more data resumes the parse from the prior state.
When an interesting state change happens, the parser notifies all registered
callback procs of the event.

The event callback is where we can do interesting data filtering and passing
to other processes. The above example simply prints state changes, but
imagine the callbacks looking for an array named `rows` and processing sets
of these row objects in small batches. Millions of rows, streaming over the
network, can be processed in constant memory space this way.

## Dependencies

* ruby >= 1.9.2



## License

JSON::Stream is released under the MIT license. Check the LICENSE file for details.
