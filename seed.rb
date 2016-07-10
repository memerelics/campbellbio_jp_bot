require 'bundler'
Bundler.require
require 'pp'
require 'pry'

table  = ENV['TABLE']
dynamo = Aws::DynamoDB::Client.new(region: 'ap-northeast-1')
wcu    = dynamo.describe_table(table_name: table).table.provisioned_throughput.write_capacity_units
# pp dynamo.public_methods(false)

items = open('./data.txt').read.split("\n")
                          .reject{|l| l =~ /^;;/ ? (puts l or true) : false }

puts "total item count: #{items.count}"
pp dynamo.update_item(table_name: table,
                      key: { text_id: 0, seq_id: 0},
                      update_expression: 'SET #c = :val',
                      expression_attribute_names: { '#c' => 'count' },
                      expression_attribute_values: { ':val' => items.count })

def text_to_tweets(text, cursor)
  if text.length > cursor
    matched = text[0..cursor].match(/^.+(，|．| )/)
    [matched[0]] + text_to_tweets(text[matched[0].length..-1], cursor)
  else
    [text]
  end
end

items.each.with_index do |line, i|
  chapter, page, text = line.split(',')

  puts text
  # at maximum: "@campbellbio_jp <content> (ch.xx, p.xxxx)".length #=> 32
  tweets = text_to_tweets(text, 108)
  puts "text.length: #{text.length} -> #{tweets.map{|t| t.length}}"

  tweets.each.with_index do |t, seq_index|
    dynamo.put_item(table_name: table,
                    item: {text_id: i + 1, seq_id: seq_index,
                           chapter: chapter, page: page, text: t})
  end
  sleep 1 if (i % wcu).zero?
end
