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

		key_index = 0
		aggregate_index = 0

		@results.attrs.each_with_index do |object, index|

			if object['id'] == key

				key_index = index

			end

			if object['id'] == aggregate

				aggregate_index = index

			end

		end

		@results.datadocs.each do |datadoc|
			
			# Get the key
			key_value = datadoc["row"][key_index]

			# By default, we count the aggregate
			aggregate_value = 1
			if key != aggregate
				aggregate_value = datadoc["row"][aggregate_index].to_i
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

	def attrNameToIndex(attrs, filter_attribute) 
		attrs.each_with_index do |attrHash, index|
			puts attrHash
			if (attrHash["id"] == filter_attribute)
				return index
			end
		end
		return (0-1)
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
		attrs = @dataset.attrs

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

			attributeIndex = attrNameToIndex(attrs, filter_attribute)
			# Cast for numerics
			if attrs[attributeIndex]['type'] == 'number'
				filter_value = filter_value.to_f
			elsif attrs[attributeIndex]['type'] == 'datetime'
				filter_value = Chronic.parse(filter_value)
			end

			# Start building our query filter
			if filter_sign == "="
				if not equals_filters.include?(filter_attribute)
					equals_filters[filter_attribute] = Array.new()
				end
	 			equals_filters[filter_attribute].push(filter_value)
			elsif filter_sign == "<"
				query = query.lt(:"row[#{attributeIndex}]" => filter_value)
			elsif filter_sign == "<="
				query = query.lte(:"row[#{attributeIndex}]" => filter_value)
			elsif filter_sign == ">"
				query = query.gt(:"row[#{attributeIndex}]" => filter_value)
			elsif filter_sign == ">="
				query = query.gte(:"row[#{attributeIndex}]" => filter_value)
			elsif filter_sign == "!="
				query = query.ne(:"row[#{attributeIndex}]" => filter_value)
			elsif filter_sign == "Contains" 
				query = query.where(:"row[#{attributeIndex}]" => Regexp.new(filter_value) )
			end

		end

		# Assemble everything with equal signs
		equals_filters.each do |key, value|
			query = query.in(:"#{key}" => value)
		end
		@results = query
	end


	def fullDatasetGoogleData()
		dataTableHash = Hash.new
	 	dataTableHash["cols"] = @dataset.attrs
	 	dataTableHash["cols"].each_with_index do |colHash, index|
	 		colHash["label"] = colHash["id"]
	 	end
 		dataTableHash["rows"] = Array.new
 		@dataset.datadocs.each do |doc|
 			rowHash = Hash.new
 			rowHash["c"] = Array.new
 			doc.row.each do |attrVal|
 				attrHash = Hash.new
 				attrHash['v'] = attrVal

 				# Add this cell to the row
 				rowHash['c'] << attrHash
			end

			# Add this row to the overall object
			dataTableHash['rows'] << rowHash
		end
		return dataTableHash
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

				# Limit to only one aggregate value in pie charts
				aggregate = aggregate.slice(0, 1);

	 			# Render as JSON data
	 			render json: getGoogleData(key, aggregate)

	 		# Handles bar chart data requests
	 		elsif chart == 'bar'

	 			puts 'THIS IS A BAR'

	 			# Get the key and aggregate
	 			key_values = params[:key]
	 			aggregate_values = params[:aggregate]

	 			render json: getGoogleData(key_values, aggregate_values)



	 		# Handles line chart data requests
	 		elsif chart == 'line'

	 			# Get the key and aggregate
	 			key = params[:key]
	 			aggregate = params[:aggregate]

	 			render json: getGoogleData(key, aggregate)


	 		# Handles the geo chart data request
	 		elsif chart == 'geo'
	 			# TODO: Make this work with google charts format

	 			# This one is special because we need latitude and longitude
	 			# TODO: Change the parameters so it's not just piggybacking on key/aggregate
	 			latitude = params[:key]
	 			longitude = params[:aggregate]

	 			# Stores the results of our iteration
	 			json_data = Array.new

	 			# Iterate through all of the datadocs for the latitude and longitude
	 			@results.each do |datadoc|

	 				# Get the latitude and longitude
					data_latitude = datadoc["#{latitude}"]
					data_longitude = datadoc["#{longitude}"]

					# Put them in an object
					# TODO: Also grab a label for the object
					location_object = Hash.new
					location_object["latitude"] = data_latitude
					location_object["longitude"] = data_longitude

					# Put this into the results array
					json_data << location_object

	 			end

	 			# Return the array as JSON data
	 			render json: json_data 

	 		# If we don't receive a chart type, handle as a filtered data request
	 		else
	 			render json: fullDatasetGoogleData()
	 		end

	 	# If it is a GET request, return basic information
	 	else

	 		render json: fullDatasetGoogleData()

	 	end

	end

	def getGoogleData(key_values, aggregate_values)
		# This method also performs a projection, stripping any columns
		# not explicitly required by key or aggregates

		# Both key_values and aggregate_values are represented as arrays
		# This supports multi-series charts

 		dataTableHash = Hash.new

 		dataTableKeyIndex = 0
		dataTableValueIndices = Array.new	
 		dataTableHash["cols"] = Array.new

 		# Adds all the corresponding keys to cols
 		# For now, this only happens once because there is only one key value
 		key_values.each do |key_value|
 			dataTableKeyIndex = attrNameToIndex(@dataset.attrs, key_value)
 			keyAttrs = @dataset.attrs[dataTableKeyIndex]
 			keyAttrs['label'] = keyAttrs['id']
 			dataTableHash["cols"] << keyAttrs
 		end

 		# Adds all the corresponding values to cols
 		aggregate_values.each do |aggregate_value|
 			index = attrNameToIndex(@dataset.attrs, aggregate_value)
 			dataTableValueIndices << index
 			dataTableHash["cols"] << @dataset.attrs[index]
 		end

 		puts dataTableValueIndices

 		# Complete aggregate hashing
 		dataTableAggregateHash = Hash.new

 		# Iterate over all datadocs
 		@dataset.datadocs.each do |datadoc|

 			if !dataTableAggregateHash.has_key?(datadoc.row[dataTableKeyIndex])

 				dataTableAggregateHash[datadoc.row[dataTableKeyIndex]] = Array.new(dataTableValueIndices.length, 0)

 			end

 			dataTableValueIndices.each_with_index do |rowIndex, index| 

 				puts dataTableValueIndices
 				puts dataTableAggregateHash[datadoc.row[dataTableKeyIndex]]
 				puts datadoc.row[rowIndex]

 				dataTableAggregateHash[datadoc.row[dataTableKeyIndex]][index]

 				dataTableAggregateHash[datadoc.row[dataTableKeyIndex]][index] += datadoc.row[rowIndex].to_f

 			end

 		end

 		# Add our aggregated values as rows into the table hash
 		dataTableHash["rows"] = Array.new
 		dataTableAggregateHash.each do |key, values|
 			rowHash = Hash.new
 			rowHash["c"] = Array.new
 			rowHash["c"] << { 'v' => key }
 			values.each do |value|
 				rowHash["c"] << { 'v' => value}
 			end
 			dataTableHash["rows"] << rowHash
 		end

 		return dataTableHash

	end

end
