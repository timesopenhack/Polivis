#!/usr/bin/env ruby
# encoding: utf-8
#Alchemy article entity extraction module

require 'json'
require 'httparty'
require 'csv'
#require 'votesmart'
require 'yaml'

class APIKeyMissing < StandardError ; end
class URLNotAvailable < StandardError ; end 
class EntityNotSpecified < StandardError ; end 
class APIResponseError < StandardError ; end

#Usage: 
#1: set API keys (enigma and alchemy required)
#2: get entities from URL through getPageEntities()
#3: get JSON data from Enigma through getEntitiesData()
class Polivis
	#API keys
	attr_accessor :alchemy_api_key
	attr_accessor :enigma_api_key
	attr_accessor :votesmart_api_key
	attr_accessor :nytimes_api_key

	#Base API URLs
	attr_accessor :alchemy_api_url
	attr_accessor :enigma_api_url
	attr_accessor :votesmart_api_url
	attr_accessor :nytimes_api_url

	#Support variables
	attr_accessor :escape_characters

	def initialize()
		#Load properties file into class attrs
		config = YAML.load_file(File.absolute_path("./polivis_properties.cfg"))   
		@alchemy_api_key = config["alchemy_api_key"]
		@enigma_api_key = config["enigma_api_key"]

		@alchemy_api_url = "http://access.alchemyapi.com/calls/url/URLGetRankedNamedEntities"
		@enigma_api_url = "https://api.enigma.io/v2/data/"

		@escape_characters = " !@\#\$\%^\&*().,';ÇüéâäàåçêëèïîÄÅôöòûùÿÖÜôöòûùÿÖÜø£Ø×ƒáíóúñÑ"
	end

	#Scrapes entities from the given URL, filtering for "People" and "Organizations"
	#Inputs: working HTTP URL
	#Outputs: array containing entity names (string array)
	def getPageEntities(article_URL = "")
		entities_arr = []

		#Check that article is available (i.e. HTTP 200)
		raise URLNotAvailable, "Article URL appears to be blank" unless article_URL != "" && article_URL != nil
#		article_test = HTTParty.get(article_URL)
#		raise URLNotAvailable, "Bad response from given article URL." unless article_test.response.is_a?(Net::HTTPOK)
			
		#Check connectivitiy & API key validity for Alchemy
		raise APIKeyMissing, "API Key has not been specified" unless alchemy_api_key != nil && alchemy_api_key != ""
		#Perform Alchemy lookup
		alch_request = alchemy_api_url + "?apikey=#{alchemy_api_key}&url=#{article_URL}"#
		puts alch_request
		response = HTTParty.get(alch_request)
		puts response#.parsed_response["results"]["entities"]["entity"]
		raise APIResponseError, "Received an error response from the Alchemy API call" unless response.parsed_response.is_a?(Hash) && response.parsed_response["results"]["status"] != "ERROR"
		response.parsed_response["results"]["entities"]["entity"].each do |i|
			if i["type"] == "Person" #|| i["type"] == "Organization"
				entities_arr << i["text"] 
			end
		end
		#return array of entities detected in article/page
		return entities_arr
	end	

	#Gets a list of federal contributions for a specific entity
	def getEntityContributions(entity = "")
		#Check that entity is a string and is not blank
		raise EntityNotSpecified, "Entity value is incorrectly specified (or blank)" unless entity != "" && entity.is_a?(String)

		resp = HTTParty.get(@enigma_api_url + "#{@enigma_api_key}/us.gov.fec.summary.2012/search/" + URI.escape("@recipient_name #{entity}", @escape_characters))
		contributors_hash = {}
		if resp.parsed_response["info"]["total_results"] > 0
			#party = resp.parsed_response["result"][0]["recipient_party"]
			contributors_hash["#{entity}"] = resp.parsed_response["result"]
		end
		return contributors_hash

	end

	#Gets all data (rows) from Enigma for all entities specified
	def getEntitiesData(entities_arr = [])
		#buid request URL with datapath
		request_url = @enigma_api_url + "#{@enigma_api_key}/us.gov.fec.summary.2012/search/"

		#build pseudoSQL query into URL string
		entities_arr.each do |i|
			#!!!For the future: validate entity name against official/candidate API			
			#i = cleanEntityName(i)
			i.downcase!.gsub!("senator ", "")
			request_url += "\%22" + URI.escape(i, @escape_characters) + "\%22\%7C"
		end
		#remove extra pipe ('or') character from the end of the URL string
		request_url_enigma = request_url[0..-4]
		puts request_url_enigma
		enigma_data_json = HTTParty.get(request_url_enigma)

		raise APIResponseError, "Received an error response from the Enigma API" unless enigma_data_json.parsed_response["success"] == true
		return enigma_data_json.parsed_response
	end

	#input: HTTParty "parsed_response" from a single enigma lookup
	#output: CSV file with data from enigma; specifically, all results from the "result" array in the enigma response
	def enigmaDataToCSV(enigma_data_hash = {})
		raise EmptyEnigmaResponse, "No data in the enigma results provided." unless enigma_data_hash.is_a?(Hash) && enigma_data_hash["info"]["total_results"] > 0
		raw_data = enigma_data_hash["result"]
		CSV.open("enigma_data_#{Time.now.strftime("%y%m%d%H%M%S")}.csv", "wb") do |csv|
			csv << raw_data.first.keys # adds the attributes name on the first line
			raw_data.each do |hash|
				csv << hash.values
			end
		end

	end


	def getEntityDonations(entity = "")
		raise EntityNotSpecified, "Entity value is incorrectly specified (or blank)" unless entity != "" && entity.is_a(String)		
	end

	#TO BE IMPLEMENTED pending authorization for needed API. Returns hash with the following keys/value pairs
	#firstName => <first name>
	#lastName => <last name>
	#status => <person's title: official, candidate, or nil (not found; neither a official or a candidate)
	def cleanEntityName(entity = "")
		raise EntityNotSpecified, "Entity value is incorrectly specified (or blank)" unless entity != "" && entity.is_a(String)
		#1: drop all titles: "Senator", "Congresswoman", "Representatitve", "Speaker" etc.
		#2: split into first and last name (if first name present)
			#a) extract last word in string --> last_name
			#b) extract first word in string --> first_name
		#check entity against voter database: 
			#a) lookup by last name officals.getbylastname(), candidates.getbylastname()
			#b) if multiple matches, return the closest match to the first name provided
				#i) if no first name is provided, return official first, then candidate
		
	end

end

