require 'json'
require 'oj'
require 'set'
require 'csv'


class PlayerResponse
    attr_accessor :user, :response, :points, :company_name
end

COMPANY_RESULT = ['acquired', 'dead', 'ipo', 'alive']
RESPONSES = ['fund_it', 'kill_it']

class Company
    attr_accessor :name, :description, :result, :year_founded, :played

    def self.load_stuff(file)
        companies = []
        csv = CSV.open(file, col_sep: '|', headers: true)
        csv.each do |row|
            comp = Company.new
            comp.name = row['name']
            comp.description = row['description']
            comp.result = row['result']
            comp.year_founded = row['year_founded'].to_i
            if comp.name != 'decide.com'
                companies << comp
            end
        end
        companies
    end

    def success?
        self.result == 'acquired' || self.result == 'ipo' || self.result == 'alive'
    end

    def result_description
        case self.result
        when 'dead'
            'This company is now dead.'
        when 'acquired'
            'This company has been acquired.'
        when 'alive'
            'This company is still alive.'
        when 'ipo'
            'This company IPO\'ed'
    end

    def get_points(response)
        if response == 'fund_it'
            case self.result
            when 'dead'
                -3
            when 'alive'
                1
            when 'acquired'
                2
            when 'ipo'
                5
            end
        elsif response == 'kill_it'
            case self.result
            when 'dead'
                1
            when 'alive'
                -1
            when 'acquired'
                -3
            when 'ipo'
                -10
            end
        end
    end
end

Companies = Company.load_stuff('companies.tsv')

class State
    attr_accessor :company, :player_responses, :companies_played

    def initialize
        self.companies_played = Set.new
        self.player_responses = []
    end

    def get_new_company
        comp = Companies.sample(1).first
        while (comp)
            if self.companies_played.include?(comp)
                comp = Companies.sample(1).first
            else
                return comp
            end
        end
    end

    def current_results
        str = ""
        self.player_responses.each do |response|
            if response.company_name == self.company.name
                if response.points > 0
                    str << " <@#{response.user}> got it correct."
                else
                    str << " <@#{response.user}> was wrong."
                end
            end
        end
        str
    end

    def leaderboard
        players_by_name = Hash.new(0)
        self.player_responses.each do |response|
            players_by_name[response.user] += response.points
        end
        str = ""
        players_by_name.to_a.sort_by {|k| -k[1]}.each_with_index do |arr,i|
            pname = arr[0]
            points = arr[1]
            str << "Place: #{i+1} - #{pname}: #{points} points.\n"
        end
        str
    end

    def mark_played
        self.companies_played.add(self.company.name)
    end

    def save(file)
        File.open(file, 'w') { |file| file.write(Oj.dump(self)) }
    end

    def self.load(file)
        str = File.open(file, 'r').read
        Oj.load(str)
    end
end

if __FILE__ == $0
    require 'test/unit'
    extend Test::Unit::Assertions

    company = Company.new
    company.name = 'decide.com'
    company.description = '2 week predictions on consumer electronics'
    company.result = 'ipo'
    company.year_founded = 2009

    pr = PlayerResponse.new
    pr.user = 'CDFEHW'
    pr.response = 'fund_it'
    pr.points = 1
    pr.company_name = company.name

    pr2 = PlayerResponse.new
    pr2.user = 'BBBEHW'
    pr2.response = 'kill_it'
    pr2.points = -1
    pr2.company_name = company.name

    state = State.new
    state.company = company
    state.player_responses = [pr, pr2]
    assert state.get_new_company.name == 'decide.com'

    state.save('test_results.json')

    loaded = State.load('test_results.json')
    assert loaded.company.name == 'decide.com'
    assert loaded.company.description == '2 week predictions on consumer electronics'
    assert loaded.company.result == 'ipo'
    assert loaded.company.year_founded == 2009

    assert loaded.player_responses.size == 2
    
    pr1 = loaded.player_responses.first
    assert pr1.user == 'CDFEHW'
    assert pr1.response == 'fund_it'
    assert pr1.points == 1
    assert pr1.company_name == 'decide.com'

    companies = Company.load_stuff('companies.tsv')
    comp = companies.first
    assert comp.name == 'decide.com'
    assert comp.description == 'this is a desc'
    assert comp.result == 'ipo'
    assert comp.year_founded == 2009

    p loaded.current_results
    p loaded.leaderboard

    loaded.mark_played
end
end