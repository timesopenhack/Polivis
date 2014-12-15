#Example of a program that uses the polivis backend ruby class
require './polivis_backend.rb'

article_url = "http://www.nytimes.com/2014/12/14/us/senate-spending-package.html"

p = Polivis.new()

#set API keys
p.enigma_api_key = "INSERT YOUR ENIGMA API KEY HERE (if not defined in polivis_properties.cfg file)"
p.alchemy_api_key = "INSERT YOUR ALCHEMY API KEY HERE (if not defined in polivis_properties.cfg file)"

#verify API keys are set correctly
puts p.enigma_api_key
puts p.alchemy_api_key

#test lookup of entities using Alchemy
all_entities_in_article = p.getPageEntities(article_url)

#test lookup of enigma data gievn array of entities
all_contributions_in_article = p.getEntitiesData(all_entities_in_article)
puts all_contributions

#test write of data to CSV
p.enigmaDataToCSV(all_contributions_in_article)
