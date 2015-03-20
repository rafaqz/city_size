# Scrape historic city size from wikipedia

require 'rubygems'
require 'rest-client'
require 'nokogiri'
require 'csv'

url='http://en.wikipedia.org/wiki/Historical_urban_community_sizes'
cities = {}
periods = []

# Collect data from all tables into a single hash of city => { period => size }
page = Nokogiri::HTML(RestClient.get(url))
tables = page.css('table.sortable')
tables.each do |table|
  columns = table.at_css('tr').css('th').map { |cell| cell.to_str }
  columns.shift
  table.css('tr').drop(1).each do |row|

    # Add row
    sizes = []
    row.css('td').each do |cell|
      sizes << cell.text
    end
    # Remove title column
    sizes.shift

    name = row.css('td > a > text()').text

    cities[name] = {} if !cities.key?(name)
    columns.zip(sizes).to_h.each do |key, value|
      cities[name][key] = value
    end
  end
  periods.concat columns
end

periods = periods.uniq

CSV.open("cities_by_size.csv", "w") do |writer|
  header = []
  header << "City"
  header.concat periods
  writer << header
  row = []
  cities.each do |name, sizes|
    row = []
    row << name
    periods.each do |period|
      if sizes.key?(period) then
        size = sizes[period] 
      else
        size = "" 
      end
      
      row << size.gsub(/,/, '').gsub(/\./, '').scan(/\d+/).first
    end
    writer << row
    print row
  end
end 
