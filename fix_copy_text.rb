#!/usr/bin/env ruby
require 'bundler'
Bundler.require

input = if ARGV[0]
          open(ARGV[0]).read
        else
          puts 'inserted text will be saved as .tmp.input_raw.txt'
          puts 'result text will be saved as .tmp.output.txt'
          puts ">>> End with Ctrl-D <<<"
          $stdin.read
        end

open('./.tmp.input_raw.txt', 'w+') {|f| f.write input }

output = Unicode::nfkc(input)
  .gsub(/ /, '')
  .gsub(/,/, '，')
  .gsub(/\.|。/, '．')
  .gsub(/．$/, '')
  .gsub(/^\s*\n/, '')

open('./.tmp.output.txt', 'w+') {|f| f.write output }
puts output
