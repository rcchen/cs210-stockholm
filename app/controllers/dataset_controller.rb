require 'csv'
require 'json'
require 'mongo'
require 'uri'
require 'chronic'
require 'money'
require 'monetize'




class DatasetController < ApplicationController

	SaveRowsJob = Struct.new(:datasetID) do
		def perform
			puts "I'M IN THE BACKGROUND =D"
			dataset = Dataset.find(datasetID)
			directory = "public/data"
    		# create the file path
    		path = File.join(directory, dataset.identifier)
    		# write the file
 			# Create an array to store CSV rows
	 			
			firstline = true
			CSV.foreach(path) do  |row|
				if firstline 
					firstline = false
					next
				end
				#First line is the header row

				row.each_with_index do |attribute, index|
					if row[index] != nil
						row[index] = row[index].force_encoding("utf-8")
					end

					puts dataset.attrs
					if dataset.attrs[index]["type"] == "number"
						puts "IS NUMERIC"
						if not is_numeric(row[index])
							puts "IS DATE"
							row[index] = Monetize.parse(row[index]).to_f
						end
					end
				end
				newDoc = Datadoc.new
				newDoc.row = row	

				# Put it into our dataset
				dataset.datadocs.push(newDoc)
			end
			dataset.save
			File.delete(path)
		end
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

	def create

		@dataset = Dataset.new
		@dataset.identifier = SecureRandom.hex(10)
		# If base_url collides, find a new random hex values
		while Dataset.where(:identifier => @dataset.identifier).exists? do
			@dataset.identifier = SecureRandom.hex(10)
		end

		if request.post?

			# Uploaded data is located in the POST param :csv
			file_data = params[:csv]

	 		# Check that we are able to read the data
	 		if file_data.respond_to?(:read)

	 			directory = "public/data"
    			# create the file path
    			path = File.join(directory, @dataset.identifier)
    			# write the file
    			File.open(path, "wb") { |f| f.write(file_data.read)}
	 			# Create an array to store CSV rows
	 			file_data.rewind

	 			parsed_attributes = nil
	 			firstValRow = nil
	 			# Parse apart our CSV file and read the rows into our array
	 			CSV.parse(file_data.read) do |csv_obj|

	 				if (parsed_attributes.nil?)
	 					parsed_attributes = csv_obj
	 				elsif (firstValRow.nil?)
	 					firstValRow = csv_obj
	 				else
	 					break
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
	 				elsif Monetize.parse(firstValRow[index]) != Money.empty
	 					attrHash[:type] = 'number'	 					
	 				elsif not Chronic.parse(firstValRow[index]).nil?
	 					attrHash[:type] = 'datetime'
	 				else 
	 					attrHash[:type] = 'string'
	 				end


	 				colsArray << attrHash
	 			end


				# Now create a representation of the model we want
				@dataset.name = params[:name]
				@dataset.attrs = colsArray
				@dataset.datadocs = Array.new



				@dataset.attrs = colsArray
				@dataset.save
				session[:dataset] = @dataset.id

	 			# Redirect to the verification stage
	 			redirect_to action: 'verify'

	 		end

	 	end

	 end
	 def verify

	 	@dataset = Dataset.find(session[:dataset])
	 	if request.post?
	 		#Resque.enqueue(DatasetProcessor, @dataset, rows)

 			# Save dataset to the current user
 			user = User.find(session[:id])
 			user.datasets << @dataset
 			user.save
 			@dataset.save

 			
 			Delayed::Job.enqueue SaveRowsJob.new(@dataset.id)



			# Render the view
			redirect_to '/dataset/' + @dataset.identifier + "/view"
		end
		
	end

	def view

		@dataset = Dataset.find_by_identifier(params[:id])

	end

	def destroy

		user = User.find(session[:id])
		@dataset = Dataset.find_by_identifier(params[:id])
		@dataset.users.delete(user)
		user.datasets.delete(@dataset)

		if @dataset.users.empty?
			@dataset.destroy
		else
			@dataset.save
			#If another user is using this ds, don't destroy it.
		end
		user.save

		redirect_to '/users/profile'

	end

	def get

		dataset = Dataset.find_by_identifier(params[:id])

		render json: dataset

	end

end
