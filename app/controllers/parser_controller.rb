require 'csv'
require 'json'
require 'mongo'
require 'uri'

class ParserController < ApplicationController

	# Gets a connection to the MongoHQ server
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

 		# 

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
 				attribute_underscore = attribute.split.join('_')
 				@attributes[attribute_underscore] = "String"
 			end

			# Now create a representation of the model we want
			@dm = DataModel.new
			@dm.name = params[:name]
			@dm.attrs = @attributes.to_json

			base_url = SecureRandom.hex(10)
			# If base_url collides, find a new random hex value
			while DataModel.find_by(base_url: base_url).nil? do
				base_url = SecureRandom.hex(10)
			end


			@dm.base_url = base_url

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
 				if is_numeric?(@hashes[0][attribute])
 					puts type
 					attributes_copy.delete(attribute)
 					attributes_copy[attribute] = 'Numeric'
 				end
 			end
 			@attributes = attributes_copy

 			Rails.cache.write("attributes", @attributes)
 			Rails.cache.write("hashes", @hashes)
 			Rails.cache.write("dm", @dm)

 		end

 	end

 	def upload

 		@attributes = Rails.cache.read("attributes")
 		@hashes = Rails.cache.read("hashes")
 		@dm = Rails.cache.read("dm")

		# Write new values for the attributes
		attributes_copy = @attributes.clone
		@attributes.each do |attribute, type|
			puts attribute
			attributes_copy.delete(attribute)
			attributes_copy[attribute] = type
		end
		@attributes = attributes_copy
		puts @attributes

		# Modify the attributes of the data model created earlier
		puts @dm.attrs
		@dm.attrs = @attributes.to_json
		@dm.save()

  		# Attempt to connect to MongoDB
 		db = get_connection
 		collection = db[@dm.base_url]

 		# Rewrite the data types in the collection
 		hashes_copy = @hashes.clone
 		@hashes.each_with_index do |hash, index|
 			hash.each do |attribute, type|
 				if @attributes[attribute] == 'Numeric'
 					current_hash = hashes_copy[index]
 					current_hash[attribute] = hash[attribute].to_i
 				end
 			end
 		end
 		@hashes = hashes_copy

 		# Send it all over to MongoDB
 		collection.insert(@hashes)

 	end

end
