# This controller acts as the API for all the DataSets
# It is only accessable through JSON POST requests
class ApiController < ApplicationController

	class Criteria
		include Origin::Queryable
	end

	class Location
		attr_accessor :latitude, :longitude
		def initialize(latitude, longitude)
			@latitude = latitude
			@longitude = longitude
		end
		def eql?(location)
			if @latitude == location.latitude and
				@longitude == location.longitude
				return true
			end
			return false
		end
		def hash
			[@latitude, @longitude].hash
		end
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
			if (attrHash["id"] == filter_attribute)
				return index
			end
		end
		return (0-1)
	end
	
	def filter_documents(filters)
		return
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
				query = query.lt(:row["#{attributeIndex}"] =>  filter_value)
			elsif filter_sign == "<="
				query = query.lte(:"row[#{attributeIndex}]" => filter_value)
			elsif filter_sign == ">"
				query = query.gt(:"row[#{attributeIndex}]" => filter_value)
			elsif filter_sign == ">="
				query = query.gte(:"row[#{attributeIndex}]" => filter_value)
			elsif filter_sign == "!="
				query = query.ne(row[attributeIndex] => filter_value)
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

	def meetsCriteria(doc)
		return true if params[:filters].nil?

		# Iterate through the objects in the filter to build the query
		params[:filters].each do |filter|

			# When we build the query, if we have multiple things fulfilling
			# the same pattern (eg. two attributes that are both equals) the
			# default is to apply an OR clause on the two statements. There
			# is currently no override for this. This should be the behavior
			# that is expected by the user.

			# Pull the correct values out from the filter
			filter_attribute = filter[1]["attribute"]
			filter_sign = filter[1]["sign"]
			filter_value = filter[1]["value"]

			attributeIndex = attrNameToIndex(@dataset.attrs, filter_attribute)
			# Cast for numerics
			if @dataset.attrs[attributeIndex]['type'] == 'number'
				filter_value = filter_value.to_f
				doc.row[attributeIndex] = doc.row[attributeIndex].to_f
			elsif @dataset.attrs[attributeIndex]['type'] == 'datetime'
				filter_value = Chronic.parse(filter_value)
				doc.row[attributeIndex] = Chronic.parse(doc.row[attributeIndex])

			end

			# Start building our query filter
			if filter_sign == "="
				return false if not doc.row[attributeIndex] == filter_value
			elsif filter_sign == "<"
				return false if not doc.row[attributeIndex] < filter_value
			elsif filter_sign == "<="
				return false if not doc.row[attributeIndex] <= filter_value
			elsif filter_sign == ">"
				return false if not doc.row[attributeIndex] > filter_value
			elsif filter_sign == ">="
				return false if not doc.row[attributeIndex] >= filter_value
			elsif filter_sign == "!="
				return false if not doc.row[attributeIndex] != filter_value
			elsif filter_sign == "Contains" 
				return false if not Regexp.new(filter_value).match doc.row[attributeIndex]
			end

		end
		return true
	end

	def fullDatasetGoogleData()
		dataTableHash = Hash.new
	 	dataTableHash["cols"] = @dataset.attrs
	 	dataTableHash["cols"].each_with_index do |colHash, index|
	 		colHash["label"] = colHash["id"]
	 	end
 		dataTableHash["rows"] = Array.new
 		@dataset.datadocs.each do |doc|
 			next if not meetsCriteria(doc)

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

		# POST requests are typically associated with some chart
 		if request.post?

 			# Figure out what sort of chart it is
 			chart = params[:chart]

 			# Handles pie chart data requests
 			if chart == 'pie'

				# Get the key and the aggregate
				key = params[:chart_options]['key']
				aggregate = params[:chart_options]['value']

				# Limit to only one aggregate value in pie charts
				aggregate = aggregate.slice(0, 1);

	 			# Render as JSON data
	 			render json: getGoogleData(key, aggregate)

	 		# Handles bar chart data requests
	 		elsif chart == 'bar'

	 			# Get the key and aggregate
	 			key_values = params[:chart_options]['key']
	 			aggregate_values = params[:chart_options]['value']

	 			render json: getGoogleData(key_values, aggregate_values)

	 		# Handles line chart data requests
	 		elsif chart == 'line'

	 			# Get the key and aggregate
	 			key = params[:chart_options]['key']
	 			aggregate = params[:chart_options]['value']

	 			render json: getGoogleData(key, aggregate)


	 		# Handles the geo chart data request
	 		elsif chart == 'geo'

	 			latitude = params[:chart_options]['latitude']
	 			longitude = params[:chart_options]['longitude']
	 			aggregate = params[:chart_options]['value']

	 			render json: getGeoData(latitude, longitude, aggregate)

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
 			keyAttrs['type'] = 'string'
 			dataTableHash["cols"] << keyAttrs
 		end

 		# Adds all the corresponding values to cols
 		aggregate_values.each do |aggregate_value|
 			index = attrNameToIndex(@dataset.attrs, aggregate_value)
 			dataTableValueIndices << index
 			colAttrs = @dataset.attrs[index]
 			colAttrs['label'] = colAttrs['id']
 			dataTableHash["cols"] << colAttrs
 		end

 		# Complete aggregate hashing
 		dataTableAggregateHash = Hash.new

 		# Iterate over all datadocs
 		@dataset.datadocs.each do |datadoc|
 			next if ! meetsCriteria(datadoc)

 			if !dataTableAggregateHash.has_key?(datadoc.row[dataTableKeyIndex])

 				dataTableAggregateHash[datadoc.row[dataTableKeyIndex]] = Array.new(dataTableValueIndices.length, 0)

 			end

 			dataTableValueIndices.each_with_index do |rowIndex, index| 

 				dataTableAggregateHash[datadoc.row[dataTableKeyIndex]][index]

 				dataTableAggregateHash[datadoc.row[dataTableKeyIndex]][index] += datadoc.row[rowIndex].to_f

 			end

 		end

 		# Add our aggregated values as rows into the table hash
 		dataTableHash["rows"] = Array.new

 		# Access the hash by order of sorted keys
 		dataTableAggregateHash.keys.sort.each do |key|
 			values = dataTableAggregateHash[key]
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

	def getGeoData(latitude, longitude, aggregate_values)

		dataTableHash = Hash.new

 		dataTableLatitudeIndex = attrNameToIndex(@dataset.attrs, latitude[0])
 		dataTableLongitudeIndex = attrNameToIndex(@dataset.attrs, longitude[0])
		dataTableValueIndices = Array.new

 		# Adds all the corresponding values to cols
 		aggregate_values.each do |aggregate_value|
 			index = attrNameToIndex(@dataset.attrs, aggregate_value)
 			dataTableValueIndices << index
 		end

 		@dataset.datadocs.each do |datadoc|
 			next if not meetsCriteria(datadoc)
 			latitude = datadoc.row[dataTableLatitudeIndex]
 			longitude = datadoc.row[dataTableLongitudeIndex]

 			location = Location.new(latitude, longitude)

 			if !dataTableHash.has_key?(location)
 				dataTableHash[location] = Array.new(dataTableValueIndices.length, 0)
 			end

  			dataTableValueIndices.each_with_index do |rowIndex, index| 

  				dataTableHash[location][index] += datadoc.row[rowIndex].to_f

 			end

 		end
 		returnArray = Array.new
 		dataTableHash.each do |location, valArray|
 			rowArr = Array.new
 			rowArr << location.latitude
 			rowArr << location.longitude
 			returnArray << (rowArr + valArray)
 		end

 		return returnArray

	end

end
