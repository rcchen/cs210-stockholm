class ApiController < ApplicationController

	# Pulls in a list of all of the datasets
	def index

		# Variable passed to the view
		@datasets = Dataset.all

	end

	# Shows information on a single dataset
	def explore

		# Retrieve the data set
		id = params[:id]
		@dataset = Dataset.where(:base_url => id).first

		# POST requests are typically associated with some chart
 		if request.post?

 			# Figure out what sort of chart it is
 			chart = params[:chart]

 			# Handles pie chart data requests
 			if chart == 'pie'

 				# Get the key and the aggregate
				key = params[:key]
	 			aggregate = params[:aggregate]

	 			# We're essentially doing a map/reduce operation
	 			# We collect all the keys in the data hash and 
	 			# aggregate values for the keys
	 			data = Hash.new
	 			@dataset.datadocs.each do |datadoc|
	 				
	 				# Get the key
	 				key_value = datadoc["#{key}"]

	 				# By default, we count the aggregate
	 				aggregate_value = 1
	 				if key != aggregate
	 					aggregate_value = datadoc["#{aggregate}"].to_i
	 				end

	 				# If the key does not exist yet, set it to zero
	 				if not data.key?(key_value)
	 					data[key_value] = 0
	 				end

	 				# Add in the value that we observed for the aggregate
	 				data[key_value] = data[key_value] + aggregate_value

	 			end

	 			# Compile data into format expected of pie charts
	 			json_data = Array.new
	 			data.each do |key, value|
	 				json_data_object = Hash.new
	 				json_data_object["label"] = key
	 				json_data_object["value"] = value
	 				json_data << json_data_object
	 			end

	 			# Render as JSON data
	 			render json: json_data

 			end
 			
 		end

	end

end
