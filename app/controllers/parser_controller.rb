require 'csv'
require 'json'
require 'mongo'
require 'uri'

class ParserController < ApplicationController

	# Gets a connection to the MongoHQ server
	#def get_connection
	#  return @db_connection if @db_connection
	#  db = URI.parse(ENV['MONGOHQ_URL'])
	#  db_name = db.path.gsub(/^\//, '')
	#  @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
	#  @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
	#  @db_connection
	#end

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
 				attribute_underscore = attribute.split.join('_')
 				@attributes[attribute_underscore] = "String"
 			end

			# Now create a representation of the model we want
			@collection = Collection.new
			@collection.name = params[:name]
			@collection.attrs = @attributes.to_json

			base_url = SecureRandom.hex(10)
			# If base_url collides, find a new random hex values
			while not DataModel.find_by(base_url: base_url).nil? do
				base_url = SecureRandom.hex(10)
			end

			@collection.base_url = base_url
			@collection.save

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
 				if is_numeric?(@hashes[0][attribute])
 					attributes_copy.delete(attribute)
 					attributes_copy[attribute] = 'Numeric'
 				end
 			end
 			@attributes = attributes_copy

 			Rails.cache.write("collection", @collection)
 			Rails.cache.write("attributes", @attributes)
 			Rails.cache.write("hashes", @hashes)

 		end

 	end

 	def upload

 		@attributes = Rails.cache.read("attributes")
 		@hashes = Rails.cache.read("hashes")
 		@collection = Rails.cache.read("collection")

		# Write new values for the attributes
		attributes_copy = @attributes.clone
		@attributes.each do |attribute, type|
			attributes_copy.delete(attribute)
			attributes_copy[attribute] = type
		end
		@attributes = attributes_copy

		# Modify the attributes of the data model created earlier
		@collection.attrs = @attributes.to_json
		@collection.save()

  		# Attempt to connect to MongoDB
 		# db = get_connection
 		# collection = db[@dm.base_url]

 		# Rewrite the data types in the collection
 		@hashes.each_with_index do |hash, index|
 			entry = Entry.new
 			entry.save
 			hash.each do |attribute|
 			# attribute is represented as [key, value], not {key => value}
 				property = Property.new
 				property.name = attribute[0]
 				name = attribute[0]
 				value = attribute[1]
 				# property.ptype = @attributes[attribute]
 				if @attributes[name] == 'Numeric'
 					property.value = value.to_i
 				else
 					property.value = value
 				end
 				property.save
 				entry.properties.append(property)
 			end
 			@collection.entries.append(entry)
 		end
		@collection.save()

 		# @hashes = hashes_copy

 		# @dm.documents = @hashes

 		# Send it all over to MongoDB
 		# collection.insert(@hashes)

 	end

end
