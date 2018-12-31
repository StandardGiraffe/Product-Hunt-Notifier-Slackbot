module ProductHuntBot
  module Commands
    class HelloWorld < SlackRubyBot::Commands::Base
      command 'hello' do |client, data, _match|
        client.say(channel: data.channel, text: 'Hello World yourself!')
      end
    end
  end
end