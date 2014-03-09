# This controller acts as the API for all the DataSets
# It is only accessable through JSON POST requests
class ApiController < ApplicationController

	class Criteria
		include Origin::Queryable
	end

	# Route for data aggregation
	def aggregate_data(key, aggregate)

		# We're essentially doing a map/reduce operation
		# We collect all the keys in the data hash and 
		# aggregate values for the keys
		data = Hash.new
		@results.each do |datadoc|
			
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

		# Return the aggregated data
		return json_data.sort_by { |hash| hash["label"] }

	end
	
	def filter_documents(filters)
		# Start construction our query here
		query = @dataset.datadocs

		# Construct a query with criteria
		criteria = Criteria.new

		# Keep track of equals filters
		equals_filters = {}

		puts filters

		# Get a pointer to the attributes from the dataset
		attrs = JSON.parse(@dataset.attrs)

		# Iterate through the objects in the filter to build the query
		filters.each do |filter|

			# When we build the query, if we have multiple things fulfilling
			# the same pattern (eg. two attributes that are both equals) the
			# default is to apply an OR clause on the two statements. There
			# is currently no override for this. This should be the behavior
			# that is expected by the user.

			# Pull the correct values out from the filter
			filter_attribute = filter[1]["attribute"]
			filter_sign = filter[1]["sign"]
			filter_value = filter[1]["value"]

			# Cast for numerics
			if attrs[filter_attribute] == 'Numeric'
				filter_value = filter_value.to_f
			end

			# Start building our query filter
			if filter_sign == "="
				if not equals_filters.include?(filter_attribute)
					equals_filters[filter_attribute] = Array.new()
				end
	 			equals_filters[filter_attribute].push(filter_value)
			elsif filter_sign == "<"
				query = query.lt(:"#{filter_attribute}" => filter_value)
			elsif filter_sign == "<="
				query = query.lte(:"#{filter_attribute}" => filter_value)
			elsif filter_sign == ">"
				query = query.gt(:"#{filter_attribute}" => filter_value)
			elsif filter_sign == ">="
				query = query.gte(:"#{filter_attribute}" => filter_value)
			end

		end

		# Assemble everything with equal signs
		equals_filters.each do |key, value|
			query = query.in(:"#{key}" => value)
		end
		@results = query
	end



	# Shows information on a single dataset
	def explore

		# Retrieve the data set
		id = params[:id]
		@dataset = Dataset.where(:identifier => id).first

		if not params[:filters].nil?
			filter_documents(params[:filters])
		else
			@results = @dataset
		end

		# POST requests are typically associated with some chart
 		if request.post?

 			# Figure out what sort of chart it is
 			chart = params[:chart]

 			# Handles pie chart data requests
 			if chart == 'pie'

				# Get the key and the aggregate
				key = params[:key]
				aggregate = params[:aggregate]

	 			# Render as JSON data
	 			render json: aggregate_data(key, aggregate)

	 		# Handles bar chart data requests
	 		elsif chart == 'bar'

	 			# Get the key and aggregate
	 			key = params[:key]
	 			aggregate = params[:aggregate]

	 			# Put in the format expected of bar charts
	 			bar_data = Hash.new
	 			bar_data["key"] = key
	 			bar_data["values"] = aggregate_data(key, aggregate)

	 			# Render as JSON data
	 			json_data = Array.new
	 			json_data.push(bar_data)
	 			render json: json_data

	 		# Handles line chart data requests
	 		elsif chart == 'line'

	 			# Get the key and aggregate
	 			key = params[:key]
	 			aggregate = params[:aggregate]

	 			# Line charts are slightly different because they expect many XY objects
	 			# We accomplish this by taking the results of the aggregate data and transforming it
	 			json_values = Array.new
	 			values = aggregate_data(key, aggregate);
	 			values.each do |hash|
	 				xy_pair = Hash.new
	 				xy_pair["x"] = hash["label"]
	 				xy_pair["y"] = hash["value"]
	 				json_values << xy_pair
	 			end

	 			# Construct the line chart
	 			json_object = Hash.new
	 			json_object["values"] = json_values
	 			json_object["key"] = key

	 			# TODO: Line charts need to pass the name of the line as well

	 			json_data = Array.new
	 			json_data.push(json_object)
	 			render json: json_data

	 		# If we don't receive a chart type, handle as a filtered data request
	 		else

	 			# Render the result as JSON
	 			render json: @results

	 		end

	 	# If it is a GET request, return basic information
	 	else

	 		render json: @dataset

	 	end

	end

end
