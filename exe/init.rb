
load 'exe/require.rb'
load 'exe/z4.rb'
load 'autostart.rb'
if ENV['LIVE'] != 'false' || LIVE != 'false'
  Z4.run!
end
load 'exe/repl.rb'
