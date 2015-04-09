require 'bundler/setup'
Bundler.require :default

# CONFIGURATIONS

# APP_ENV = "staging"
APP_ENV = "production"
# THIS IS YOUR BUCKET NAME
BUCKET_NAME = "itrigga-eu-#{APP_ENV}"

###

S3CMD = File.read File.expand_path "~/.s3cfg" # default config for s3cmd

config_parse = -> (pattern, content) do
  content.match(/#{pattern}(.+)/)[1].strip
end

ACCESS_KEY = config_parse.("access_key =", S3CMD)
SECRET_KEY = config_parse.("secret_key =", S3CMD)

# $VERBOSE = nil # suppress warnings
# $VERBOSE = nil

service = S3::Service.new(
  access_key_id:     ACCESS_KEY,
  secret_access_key: SECRET_KEY
)

puts "Connecting to s3://#{BUCKET_NAME}"

mime_type = -> (ext) do
  MIME::Types.of(ext).first.to_s
end

TYPES_FOUND = []
COUNTERS = {
  objects: 0
}

# monkeypatching
module S3
  class Object
    def update_content_type(type)
     put_object_with_content_type type
     true
    end

    def put_object_with_content_type(type)
      headers = dump_headers
      headers[:content_type] = type
      response = object_request(:put, :body => content, :headers => headers)
      parse_headers(response)
    end
  end
end

FAILURES = []

bucket = service.buckets.find BUCKET_NAME
objects = bucket.objects

for object in objects
  next if     object.key[-1] == "/"
  # COMMENT/DELETE the following FILTER line, you probably don't need it
  next unless object.key =~ /^universes\/.+\/articles/ || object.key =~ /^articles/
  # next unless object.key =~ /^articles/
  next if     (extname = File.extname object.key) == ""

  # MAIN FILTER (you may want to use those to test only in one file)
  # next unless object.key =~ /^universes\/.+\/articles\/714/
  # next unless object.key =~ /^articles\/13761/

  type = mime_type.( extname )
  next unless type
  next if     type == "" || type == 'application/x-sql'

  TYPES_FOUND << type

  puts object.key

  # retrieves the old content type
  #
  # puts object.retrieve
  # puts "old content type: '#{object.content_type}'"

  puts "new content type: '#{type}'"
  begin
    object.update_content_type type
  rescue Errno::ECONNRESET
    puts "RETRYING: #{object.key}"
    retry
  end
  puts
  COUNTERS[:objects] += 1
end

puts "Objects updated: #{COUNTERS[:objects]}"
puts
puts "Types found: #{TYPES_FOUND.uniq}"
puts
