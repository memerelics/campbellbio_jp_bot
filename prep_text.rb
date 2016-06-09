require 'bundler'
Bundler.require
require 'pp'

table = ENV['TABLE']

dynamo = Aws::DynamoDB::Client.new(region: 'ap-northeast-1')
pp dynamo.public_methods(false)

open('./init.txt').read.split("\n").each.with_index do |line, i|
  pp line
  matched = /^(.*)\(p.(\d+)\)/.match(line)
  res = dynamo.put_item(table_name: table,
                        item: {text_id: i + 1, seq_id: 1,
                               text: matched[1], page: matched[2].to_i})
  pp res
  sleep 1
end

