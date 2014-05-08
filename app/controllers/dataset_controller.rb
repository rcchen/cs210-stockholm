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
	 			
	 			parsed_attributes = nil
	 			firstValRow = nil
	 			# Parse apart our CSV file and read the rows into our array
	 			rows = Array.new
	 			CSV.parse(@file_data.read) do |csv_obj|
	 				csv_obj.each_with_index do |val, index|
	 					if not csv_obj[index].nil?
	 						csv_obj[index] = csv_obj[index].force_encoding("utf-8")
	 					end
	 				end
	 				if (parsed_attributes.nil?)
	 					parsed_attributes = csv_obj
	 				elsif (firstValRow.nil?)
	 					firstValRow = csv_obj
	 					rows << csv_obj
	 				else
	 					rows << csv_obj
	 				end

	 			end
	 			# We assume that attributes are in the header of the CSV
	 			# TODO: Ask user whether these are actually the attributes

	 			
	 			colsArray = Array.new
	 			# Create a new Hash object of attributes
	 			parsed_attributes.each_with_index do |attribute, index|
	 				attribute_underscore = attribute.split.join('')
	 				attrHash = Hash.new
	 				attrHash[:id] = attribute_underscore

	 				if is_numeric?(firstValRow[index])
	 					attrHash[:type] = 'number'
	 				elsif not Chronic.parse(firstValRow[index]).nil?
	 					attrHash[:type] = 'datetime'
	 				else 
	 					attrHash[:type] = 'string'
	 				end


	 				colsArray << attrHash
	 			end


				# Now create a representation of the model we want
				@dataset = Dataset.new
				@dataset.name = params[:name]
				@dataset.attrs = colsArray
				@dataset.datadocs = Array.new
				@dataset.identifier = SecureRandom.hex(10)
				# If base_url collides, find a new random hex values
				while Dataset.where(:identifier => @dataset.identifier).exists? do
					@dataset.identifier = SecureRandom.hex(10)
				end



				@dataset.attrs = colsArray
				@dataset.expected_count = rows.count
				@dataset.save
				session[:dataset] = @dataset.id

				Rails.cache.write("rows", rows);

	 			# Redirect to the verification stage
	 			redirect_to action: 'verify'

	 		end

	 	end

	 end
	 def verify

	 	@dataset = Dataset.find(session[:dataset])
	 	rows = Rails.cache.read("rows")
	 	if request.post?
	 		Resque.enqueue(DatasetProcessor, @dataset, rows)

 			# Save dataset to the current user
 			user = User.find(session[:id])
 			user.datasets << @dataset
 			user.save

			# Render the view
			redirect_to '/dataset/' + @dataset.identifier + "/view"
		end
		
	end

	def view

		@dataset = Dataset.find_by_identifier(params[:id])

	end

	def destroy


		@dataset = Dataset.find_by_identifier(params[:id])
		@dataset.users.delete(User.find(session[:id]))

		if @dataset.users.empty?
			@dataset.destroy
		else
			@dataset.save
			#If another user is using this ds, don't destroy it.
		end

		redirect_to '/users/profile'

	end

	def get

		dataset = Dataset.find_by_identifier(params[:id])

		render json: dataset

	end

end
