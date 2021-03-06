require 'sinatra'
require 'csv'
require 'net/http'
require 'uri'
require 'json'
require 'slack-ruby-client'
require_relative 'model'

SLACK_API_TOKEN = ENV['SLACK_API_TOKEN']

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

set :bind, '0.0.0.0'

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

CurrentState = State.load('results.json')

Client = Slack::Web::Client.new
Client.auth_test

def send_message(channel, text)
    Client.chat_postMessage(channel: channel, text: text, as_user: true)
    p "Sending slack message #{channel} #{text}"
end

puts "Current State: #{CurrentState.company}"

def fund_it(user, channel)
    return if user == 'UG2N2CNTE'

    if !CurrentState.has_answered?(user)
        pr = PlayerResponse.new
        pr.user = user
        pr.response = 'fund_it'
        pr.points = CurrentState.company.get_points('fund_it')
        pr.company_name = CurrentState.company.name
        CurrentState.player_responses << pr
        send_message(channel, "Recorded <@#{user}> would fund it.")
    else
        send_message(channel, "<@#{user}> already answered.")
    end
end

def kill_it(user, channel)
    return if user == 'UG2N2CNTE'

    if !CurrentState.has_answered?(user)
        pr = PlayerResponse.new
        pr.user = user
        pr.response = 'kill_it'
        pr.points = CurrentState.company.get_points('kill_it')
        pr.company_name = CurrentState.company.name
        CurrentState.player_responses << pr
        send_message(channel, "Recorded <@#{user}> would kill it.")
    else
        send_message(channel, "<@#{user}> already answered.")
    end
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
    begin
        if event_type == 'challenge'
            content_type 'text/plain'
            body request_payload['challenge']
            status 200
        elsif event_type == 'message'
            p 'Message'
            if text.include?('fund it')
                p 'Capture fund it'
                fund_it(user, channel)
            elsif text.include?('kill it')
                p 'Capture kill it'
                kill_it(user, channel)
            end
        elsif event_type == 'app_mention'
            if text.include?('leaderboard')
                p 'Leaderboard'
                leaderboard_text = CurrentState.leaderboard
                send_message(channel, leaderboard_text)
            elsif CurrentState.company == nil
                if text.include?('new startup')
                    p 'New Startup'
                    send_message(channel, "Ok <@#{user}>. Let's play.")
                    company = CurrentState.get_new_company
                    if company
                        send_message(channel, "#{company.name} was started in #{company.year_founded}. It does #{company.description}. Would you fund it?")
                        CurrentState.company = company
                    else
                        send_message(channel, 'Thanks for playing. We ran out of startups.')
                    end
                end
            else
                if text.include?('fund it')
                    p 'Capture fund it'
                    fund_it(user, channel)
                elsif text.include?('kill it')
                    p 'Capture kill it'
                    kill_it(user, channel)
                elsif text.include?('results')
                    p 'Capture results'
                    if CurrentState.has_response?
                        company = CurrentState.company
                        send_message(channel, company.result_description)
                        send_message(channel, CurrentState.current_results)
                        CurrentState.mark_played
                        CurrentState.company = nil
                    else
                        send_message(channel, 'Waiting for at least 1 player to respond.')
                    end
                end
            end
            CurrentState.save('results.json')
        end
    rescue StandardError => e
        puts "Rescued: #{e.inspect}"
    ensure
        return [200, 'Ok']
    end
end

