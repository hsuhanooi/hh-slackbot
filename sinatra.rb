require 'sinatra'
require 'csv'
require 'net/http'
require 'uri'
require 'json'
require 'slack-ruby-client'

SLACK_API_TOKEN = ENV['SLACK_API_TOKEN']

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

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

class CompanyResponse
    attr_accessor :user, :response
end

class State
    attr_accessor :company
end

CurrentState = State.new

def send_message(channel, text)
    client = Slack::Web::Client.new
    client.chat_postMessage(channel: channel, text: text, as_user: true)
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
        if CurrentState.company == nil
            if text.include?('new startup')
                send_message(channel, "Ok <@#{user}>. Let's play.")
                company = Companies.sample(1).first
                send_message(channel, "#{company['name']} was started in 2007. It does magic. Would you fund it?")
                CurrentState.company = company
            end
        else
            if text.include?('fund it')
                send_message(channel, "Recorded <@#{user}> would fund it.")
            elsif text.include?('kill it')
                send_message(channel, "Recorded <@#{user}> would kill it.")
            elsif text.include?('results')
                company = CurrentState.company
                send_message(channel, "#{company['name']} was killed in 2013. <@#{user}> wins.")
                CurrentState.company = nil
            end
        end

        body 'Ok'
        status 200
    end
end

