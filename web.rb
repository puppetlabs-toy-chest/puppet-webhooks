require 'sinatra'

get '/' do
  "Hello, world"
end

get '/trello/puppet-dev-community/view' do
  begin
    File.read('buffer')
  rescue Errno::ENOENT => detail
    "ERROR: #{detail.message}"
  end
end

post '/trello/puppet-dev-community/?' do
  # TODO thread safety
  File.open('buffer', 'w+') do |f|
    f.write(params['payload'])
  end
end
