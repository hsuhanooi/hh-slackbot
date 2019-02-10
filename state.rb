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
