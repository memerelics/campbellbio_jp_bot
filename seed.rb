require 'bundler'
Bundler.require
require 'pp'
require 'pry'
require 'rb-readline'

table  = ENV['TABLE']
dynamo = Aws::DynamoDB::Client.new(region: 'ap-northeast-1')
wcu    = dynamo.describe_table(table_name: table).table.provisioned_throughput.write_capacity_units
# pp dynamo.public_methods(false)

items = open('./data.txt').read.split("\n")
                          .reject{|l| l =~ /^;;/ ? (puts l or true) : false }

puts "update total item count: #{items.count}"
dynamo.update_item(table_name: table,
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

def query_target_text_items(dynamo, table, i)
  dynamo.query(table_name: table,
               key_condition_expression: "#text_id = :i",
               expression_attribute_names: { "#text_id": "text_id" },
               expression_attribute_values: { ":i": i }).items
end

def remote_line(target_text_items)
  target_text_items[0]['chapter'] + ',' +
    target_text_items[0]['page'] + ',' +
    target_text_items.map{|item| item['text'] }.join
end

items.each.with_index do |line, i|
  i += 1
  #puts "item No. #{i}..."

  remote_items = query_target_text_items(dynamo, table, i)
  unless remote_items.empty?
    remote_md5 = Digest::MD5.hexdigest(remote_line(remote_items))
    local_md5  = Digest::MD5.hexdigest(line)
    next if local_md5 == remote_md5
    puts '---'

    puts "local line: #{line}"
    puts "delete remote items: #{remote_line(remote_items)}"

    remote_items.each do |item|
      pp({"text_id": {"N": i.to_s },
          "seq_id":  {"N": item['seq_id'].to_i.to_s }})
      dynamo.delete_item(table_name: table,
                         key: {"text_id": i, "seq_id": item['seq_id'].to_i})
    end
  end

  chapter, page, text = line.split(',')

  puts text
  # at maximum: "@campbellbio_jp <content> (ch.xx, p.xxxx)".length #=> 32
  tweets = text_to_tweets(text, 108)
  puts "text.length: #{text.length} -> #{tweets.map{|t| t.length}}"

  tweets.each.with_index do |t, seq_index|
    dynamo.put_item(table_name: table,
                    item: {text_id: i, seq_id: seq_index,
                           chapter: chapter, page: page, text: t})
  end
  sleep 1 if (i % wcu).zero?
end
