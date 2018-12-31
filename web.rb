require 'sinatra/base'

module ProductHuntBot
  class Web < Sinatra::Base
    get '/' do
      'Watching Product Hunt for email products...'
    end
  end
end