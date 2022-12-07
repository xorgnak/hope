
@vapid_key = Webpush.generate_key
if !Dir.exists? 'vapid_keys'
  Dir.mkdir 'vapid_keys'
end
File.write('vapid_keys/private_key', @vapid_key.private_key)
File.write('vapid_keys/public_key', @vapid_key.public_key)

module Z4; end

load 'lib/core.rb'
load 'lib/db.rb'
load 'lib/broker.rb'
load 'lib/app.rb'
