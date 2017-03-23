#!/usr/bin/env ruby
require 'bundler'
Bundler.require

# usage: $ ./fix_copy_text.rb
# ...paste text here...
# Ctrl-D

puts 'inserted text will be saved as .tmp.input_raw.txt'
puts 'result text will be saved as .tmp.output.txt'
puts ">>> End with Ctrl-D <<<"

input = $stdin.read
open('./.tmp.input_raw.txt', 'w+') {|f| f.write input }

output = Unicode::nfkc(input)
  .gsub(/ /, '')
  .gsub(/,/, '，')
  .gsub(/\.|。/, '．')
  .gsub(/．$/, '')
  .gsub(/^\s*\n/, '')

open('./.tmp.output.txt', 'w+') {|f| f.write output }
puts output
