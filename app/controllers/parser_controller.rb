require 'csv'
require 'json'
require 'mongo'
require 'uri'

class ParserController < ApplicationController

	def get_connection
	  return @db_connection if @db_connection
	  db = URI.parse(ENV['MONGOHQ_URL'])
	  db_name = db.path.gsub(/^\//, '')
	  @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
	  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
	  @db_connection
	end

	# Adopted from http://rosettacode.org/wiki/Determine_if_a_string_is_numeric#Ruby
	def is_numeric?(s)
		begin
			Float(s)
		rescue
			false #not numeric
		else
			true #numeric
		end
	end

 	def index

 	end

 	def verify

 		# The file data is stored in CSV
 		@file_data = params[:csv]
 		
 		# Check that we are able to read the data
 		if @file_data.respond_to?(:read)

 			# Create an array to store CSV rows
 			rows = Array.new
 			
 			# Parse apart our CSV file and read the rows into our array
 			CSV.parse(@file_data.read) do |csv_obj|
 				rows.push(csv_obj)
 			end

 			# Headers are stored in the first row
 			parsed_attributes = rows[0]
 			rows.delete_at(0)
 			@attributes = Hash.new
 			parsed_attributes.each do |attribute|
 				@attributes[attribute] = "String"
 			end

			# Now create a representation of the model we want
			@dm = DataModel.new
			@dm.name = params[:name]
			@dm.attrs = @attributes.to_json
			@dm.base_url = SecureRandom.hex(10)

 			# Generate all the hashes
 			@hashes = Array.new
 			rows.each do |row|

 				# Parse into hashes
 				h = Hash.new
 				@attributes.each_with_index do |(attribute, type), index|
 					h[attribute] = row[index]
 				end

 				# Put it into our collection
 				@hashes.push(h)
 			
 			end

 			# Create a JSON object from the hash
 			@sample = @hashes[0].to_json

 			# From the sample, figure out the proper types
 			attributes_copy = @attributes.clone
 			@attributes.each do |attribute, type|
 				puts attribute
 				puts @hashes[0]
 				if is_numeric?(hashes[0][attribute])
 					puts type
 					attributes_copy.delete(attribute)
 					attributes_copy[attribute] = 'Numeric'
 				end
 			end
 			@attributes = attributes_copy

 			# collection.insert(@hashes)

 		end

 	end

 	def upload

		# Write new values for the attributes
		attributes_copy = @attributes.clone
		@attributes.each do |attribute, type|
			attributes_copy.delete(attribute)
			attributes_copy[attribute] = type
		end
		@attributes = attributes_copy

		# Modify the attributes of the data model created earlier
		@dm.attributes = @attributes.to_json
		@dm.save()

  		# Attempt to connect to MongoDB
 		db = get_connection
 		collection = db[@dm.base_url]

 		# Rewrite the data types in the collection
 		@hashes.each do |hash|
 			hash.each do |attribute|
 				puts hash[attribute]
 			end
 		end

 	end

end
