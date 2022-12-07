module Z4
  
  class Mqtt
    def initialize *ch, &b
      @client = PahoMqtt::Client.new
      PahoMqtt.logger = 'paho_mqtt'
      @client.connect('broker.hivemq.com', 1883)
      @client.on_message do |message|
        handler(message.topic, message.payload)
      end
      @client.subscribe([ch[0] || '#', 2])
    end
    def push t, p
      if p.class == String
        @client.publish(t, p, false, 0)
      else
        @client.publish(t, JSON.generate(p), false, 0)
      end
    end
    def handler t, p
      @t = t.split('/')
      if p[0] == '{' || p[0] == '['
        @p = JSON.parse p
      else
        @p = p.split(' ')
      end
      puts "MQTT: (#{@t}) #{@p}"
    end
  end
  def self.broker ch, &b
    Mqtt.new ch, b
  end
  MQTT = Mqtt.new
  def self.mqtt
    MQTT
  end
end
