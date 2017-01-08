#!/usr/bin/env ruby
require 'bundler'
Bundler.require

# usage: $ ./fix_copy_text.rb <<EOF >> data.txt
# heredoc> ...paste text here...
# heredoc> EOF

$stdout.print Unicode::nfkc($stdin.read)
.gsub(/ /, '')
.gsub(/,/, '，')
.gsub(/\.|。/, '．')
.gsub(/．$/, '')
.gsub(/^\s*\n/, '')
