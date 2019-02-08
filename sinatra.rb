require 'sinatra'
require 'csv'

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
