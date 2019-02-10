require 'sinatra'
require 'csv'
require 'net/http'
require 'uri'
require 'json'
require 'slack-ruby-client'

SLACK_API_TOKEN = ENV['SLACK_API_TOKEN']

set :bind, '0.0.0.0'

def read_csv(filename)
    companies = []
    Zlib::GzipReader.open(filename) do |gzip|
        csv = CSV.new(gzip, headers: true)
        begin
            ##<CSV::Row "permalink":"/company/afraxis" "name":"Afraxis" "category_code":nil "funding_total_usd":"345000" "status":"operating" "country_code":"USA" "state_code":"CA" "region":"San Diego" "city":"La Jolla" "funding_rounds":"2" "founded_at":nil "founded_month":nil "founded_quarter":nil "founded_year":nil "first_funding_at":"2011-12-21" "last_funding_at":"2012-04-03" "last_milestone_at":"2008-01-01">
            csv.each do |row|
                companies << row
            end
        rescue ArgumentError
            # Ignore
        end
    end
    companies
end

Companies = read_csv('data/crunchbase-companies.csv.gz')

puts Companies.sample['name']

get '/slack/startup' do
    Companies.sample['name']
end

post '/slack/startup' do
    status 200
    body 'hello world'
end

TEST = {
    "token":"jdDiPnaP3xVzuunW9HCmiISc",
    "team_id":"TBUSKAGHF",
    "api_app_id":"AG1AHD2R2",
    "event":{
        "client_msg_id":"3d055a7a-ed91-45ec-9644-ec26989f7864",
        "type":"app_mention",
        "text":"<@UG2N2CNTE> helo",
        "user":"UBWEKD6A3",
        "ts":"1549764382.000700",
        "channel":"GG3USD4CX",
        "event_ts":"1549764382.000700"
    },
    "type":"event_callback",
    "event_id":"EvG2N6EZC4",
    "event_time":1549764382,
    "authed_users":["UG2N2CNTE"]
}

# Example response
# POST https://slack.com/api/chat.postMessage
# Content-type: application/json
# Authorization: Bearer YOUR_BOTS_TOKEN
# {
#     "text": "Hello <@UA8RXUPSP>! Knock, knock.",
#     "channel": "CBR2V3XEX"
# }

def send_response(token, channel, text)
    uri = URI.parse("https://slack.com/api/chat.postMessage")
    header = {
        'Content-type': 'application/json',
        'Authorization': "Bearer #{token}"
    }
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = {
        'text': text,
        'channel': channel
    }.to_json
    response = http.request(request)
    puts response
    puts response.body
end


post '/slack/action-endpoint' do
    status 200
    payload = JSON.parse request.body.read
    puts payload
    event = payload['event']
    token = SLACK_API_TOKEN
    channel = event['channel']
    text = event['text']
    event_type = event['type']
    user = event['user']

    if event_type == 'challenge'
        content_type 'text/plain'
        body request_payload['challenge']
        status 200
    elsif event_type == 'app_mention'
        respond = "Hello world"
        send_response(token, channel, respond)
        body 'Ok'
        status 200
    end
end

