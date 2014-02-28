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

 	# Verification process that validates the data that is being uploaded. 
 	# Checks data types and creates basic models to be associated with data
 	def verify

 		# Uploaded data is located in the POST param :csv
 		@file_data = params[:csv]
 		
 		# Check that we are able to read the data
 		if @file_data.respond_to?(:read)

 			# Create an array to store CSV rows
 			rows = Array.new
 			
 			# Parse apart our CSV file and read the rows into our array
 			CSV.parse(@file_data.read) do |csv_obj|
 				rows.push(csv_obj)
 			end

 			# We assume that attributes are in the header of the CSV
 			# TODO: Ask user whether these are actually the attributes
 			parsed_attributes = rows[0]

 			# Remove the row so we don't accidentally process it
 			rows.delete_at(0)

 			# Create a new Hash object of attributes
 			@attributes = Hash.new
 			parsed_attributes.each do |attribute|
 				attribute_underscore = attribute.split.join('_')
 				@attributes[attribute_underscore] = "String"
 			end

			# Now create a representation of the model we want
			@collection = Dataset.new
			@collection.name = params[:name]
			@collection.attrs = @attributes.to_json
			@collection.base_url = SecureRandom.hex(10)
			# If base_url collides, find a new random hex values
			#while not Collection.where(:base_url => @collection.base_url).exists? do
			#	print 'asdf'
			#	@collection.base_url = SecureRandom.hex(10)
			#end

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
		@collection.save

  		# Attempt to connect to MongoDB
 		# db = get_connection
 		# collection = db[@dm.base_url]

 		documents = []

 		# Rewrite the data types in the collection
 		@hashes.each_with_index do |hash, index|
 			#entry = Entry.new
 			#entry.save
 			document = Datadoc.new

 			hash.each do |attribute|
 			# attribute is represented as [key, value], not {key => value}
 				#property = Property.new
 				#property.name = attribute[0]
 				name = attribute[0]
 				value = attribute[1]
 				# property.ptype = @attributes[attribute]
 				if @attributes[name] == 'Numeric'
 					value = value.to_i
 				else
 					value = value
 				end
 				document["#{name}"] = value
 				# The properties are saved when the @collection is saved, so this 
 				# is a redundant update to the db. Removing it halved update time
 				# in some cases.
 				#property.save
 				#entry.properties.append(property)
 			end

 			# documents.push(document)

 			@collection.datadocs.push(document)
 			#@collection.entries.append(entry)
 		end

		Mongoid.logger = nil

		@collection.save()

 		# @hashes = hashes_copy

 		# @dm.documents = @hashes

 		# Send it all over to MongoDB
 		# collection.insert(@hashes)

 	end

end
