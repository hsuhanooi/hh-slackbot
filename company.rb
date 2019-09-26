class Company
    COMPANY_RESULT = ['acquired', 'dead', 'ipo', 'alive']

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
