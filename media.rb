#!/usr/bin/env ruby

require 'json'
require 'pp'
require 'pry'

exit 1 unless ARGV[0]

_result = `bundle exec twurl -H upload.twitter.com -X POST "/1.1/media/upload.json" --file "#{ARGV[0]}" --file-field "media"`
result = JSON.load(_result)
pp result

media_id = result['media_id']

exit 1 unless media_id

File.open('tw.json', 'w+'){|f|
  f.write({media: media_id.to_s, tweet: 'TODO'}.to_json)
}

puts '$ edit tw.json'
puts '$ nvm use stable && node local.js'
