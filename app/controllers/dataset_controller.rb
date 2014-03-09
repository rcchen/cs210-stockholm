require 'csv'
require 'json'
require 'mongo'
require 'uri'
require 'chronic'

class DatasetController < ApplicationController

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

	def create

		if request.post?

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

	 			attrNames = Array.new
	 			# Create a new Hash object of attributes
	 			@attributes = Hash.new
	 			parsed_attributes.each do |attribute|
	 				attribute_underscore = attribute.split.join('')
	 				@attributes[attribute_underscore] = "String"
	 				attrNames << attribute_underscore
	 			end


				# Now create a representation of the model we want
				@dataset = Dataset.new
				@dataset.name = params[:name]
				@dataset.attrs = @attributes.to_json
				@dataset.identifier = SecureRandom.hex(10)
				# If base_url collides, find a new random hex values
				while Dataset.where(:identifier => @dataset.identifier).exists? do
					@dataset.identifier = SecureRandom.hex(10)
				end

	 			# Generate all the hashes
	 			@hashes = Array.new
	 			rows.each do |row|

	 				# Parse into hashes
	 				h = Hash.new
	 				attrNames.each_with_index do |attribute, index|
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
 						attrType = 'Numeric'
 					elsif @hashes[0][attribute].match(/\$?\d*\.\d\d\z/)
 						attrType = 'Monetary (USD)'
 					elsif not Chronic.parse(@hashes[0][attribute]).nil?
 						attrType = 'Date'
 					end

	 				if not attrType.nil?
 						attributes_copy[attribute] = attrType
 					end
 				end
 				@attributes = attributes_copy
 				@dataset.attrs = @attributes.to_json
 				@dataset.save

	 			# We temporarily keep things in the cache to pass to the upload method
	 			Rails.cache.write("dataset", @dataset)
	 			Rails.cache.write("attributes", @attributes)
	 			Rails.cache.write("hashes", @hashes)

	 			# Redirect to the verification stage
	 			redirect_to action: 'verify'

	 		end

		end

	end

	def verify

		if request.post?

			# Recall items from the cache
	 		# TODO: deprecate the cache. We shouldn't be doing this
	 		@attributes = Rails.cache.read("attributes")
	 		@hashes = Rails.cache.read("hashes")
	 		@dataset = Rails.cache.read("dataset")

			# Write new values for the attributes
			attributes_copy = @attributes.clone
			@attributes.each do |attribute, type|
				attributes_copy.delete(attribute)
				attributes_copy[attribute] = type
			end
			@attributes = attributes_copy

			# Modify the attributes of the data model created earlier
			@dataset.attrs = @attributes.to_json
			@dataset.save

	 		# Rewrite the data types in the dataset
	 		@hashes.each_with_index do |hash, index|
	 			# Create a new Datadoc
	 			datadoc = Datadoc.new
	 			# Iterate through attributes of the hash
	 			hash.each do |attribute|

	 				# Retrieve the name and value of each attribute
	 				name = attribute[0]
	 				value = attribute[1]

	 				# Typecast if the attribute type is Numeric
	 				if @attributes[name] == 'Numeric'
	 					value = value.to_f
	 				elsif @attributes[name] == 'Date'
	 					value = Chronic.parse(value).to_s
	 				else
	 					value = value
	 				end
	 				# Dynamically create the attribute in our Datadoc
	 				datadoc["#{name}"] = value

	 			end

	 			# Add the Datadoc into our Dataset
	 			@dataset.datadocs.push(datadoc)

	 		end

	 		# Save dataset to the current user
			user = User.find(session[:id])
			user.datasets << @dataset
			user.save

			# Render the view
			redirect_to '/dataset/' + @dataset.identifier

		else

	 		@attributes = Rails.cache.read("attributes")
	 		@hashes = Rails.cache.read("hashes")
	 		@dataset = Rails.cache.read("dataset")

		end

	end

	def view

		@dataset = Dataset.find_by_identifier(params[:id])

	end

	def destroy

		@dataset = Dataset.find_by_identifier(params[:id])
		@dataset.destroy

		redirect_to '/users/profile'

	end

end
