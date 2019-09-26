require 'json'
require 'oj'
require 'set'
require 'csv'

require_relative 'company'
require_relative 'state'
require_relative 'player_response'

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
    assert state.get_new_company.name

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
    assert comp.name == '43 things'
    assert comp.description
    assert comp.result == 'dead'
    assert comp.year_founded == 2004

    p loaded.current_results
    p loaded.leaderboard

    loaded.mark_played
end