class CreateController < ApplicationController

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

	# Route for creating a page. Only GET route in this entire 
	# thing, the rest of the stuff is processed with AJAX routes
	def index


	end


	# Responsible for verifying the contents of the file upload
	def verify

		# Uploaded data is located in the POST :file param
		@file_data = params[:file]

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
 				attribute_underscore = attribute.split.join('')
 				@attributes[attribute_underscore] = "String"
 			end

			# Now create a representation of the model we want
			@dataset = Dataset.new
			@dataset.name = params[:name]
			@dataset.attrs = @attributes.to_json
			@dataset.base_url = SecureRandom.hex(10)
			# If base_url collides, find a new random hex values
			while Dataset.where(:base_url => @dataset.base_url).exists? do
				@dataset.base_url = SecureRandom.hex(10)
			end

 			# Generate all the hashes
 			@hashes = Array.new
 			rows.each do |row|

 				# Parse into hashes
 				h = Hash.new
 				@attributes.each_with_index do |(attribute, type), index|
 					h[attribute] = row[index]
 				end

 				# Put it into our dataset
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

 			# We temporarily keep things in the cache to pass to the upload method
 			Rails.cache.write("dataset", @dataset)
 			Rails.cache.write("attributes", @attributes)
 			Rails.cache.write("hashes", @hashes)

 			# Return the dataset object
 			render json: @attributes

 		end

	end






end
