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

	def attrNameToIndex(attrs, filter_attribute) 
		attrs.each_with_index do |attrHash, index|
			if (attrHash["id"] == filter_attribute)
				return index
			end
		end
		return (0-1)
	end

	def meetsCriteria()

		return true if params[:filters].nil? or params[:filters] == ""


		# Iterate through the objects in the filter to build the query
		params[:filters].each do |key, filter|

			# When we build the query, if we have multiple things fulfilling
			# the same pattern (eg. two attributes that are both equals) the
			# default is to apply an OR clause on the two statements. There
			# is currently no override for this. This should be the behavior
			# that is expected by the user.

			# Pull the correct values out from the filter
			filter_attribute = nil
			if filter.has_key? "key"
				filter_attribute = filter["key"]
			else
				filter_attribute = filter["attribute"]
			end

			filter_sign = nil
			if filter.has_key? "conditional"
				filter_sign = filter["conditional"]
			else
				filter_sign = filter["sign"]
			end
			# TODO: Make this consistent between vis::Create/ dataset::view


			filter_value = filter["value"]

			attributeIndex = attrNameToIndex(@dataset.attrs, filter_attribute)
			# Cast for numerics
			if @dataset.attrs[attributeIndex]['type'] == 'number'
				filter_value = filter_value.to_f
				@doc.row[attributeIndex] = @doc.row[attributeIndex].to_f
			elsif @dataset.attrs[attributeIndex]['type'] == 'datetime'
				@doc.row[attributeIndex] = Chronic.parse(@doc.row[attributeIndex])
				if filter_sign != "groupBy"
					filter_value = Chronic.parse(filter_value)
				end
			end

			# Start building our query filter
			if filter_sign == "="
				return false if not @doc.row[attributeIndex] == filter_value
			elsif filter_sign == "<"
				return false if not @doc.row[attributeIndex] < filter_value
			elsif filter_sign == "<="
				return false if not @doc.row[attributeIndex] <= filter_value
			elsif filter_sign == ">"
				return false if not @doc.row[attributeIndex] > filter_value
			elsif filter_sign == ">="
				return false if not @doc.row[attributeIndex] >= filter_value
			elsif filter_sign == "!="
				return false if not @doc.row[attributeIndex] != filter_value
			elsif filter_sign == "Contains" 
				return false if not Regexp.new(filter_value).match @doc.row[attributeIndex]
			elsif filter_sign == "groupBy"
				if @dataset.attrs[attributeIndex]['type'] != 'datetime'
					puts "Trying to goupBy a non-datetime attr"
					puts @dataset.attrs[attributeIndex]
				else
					if filter_value == "dayOfWeek"
						@doc.row[attributeIndex] = @doc.row[attributeIndex].strftime('%A')
					elsif filter_value == "month"
						@doc.row[attributeIndex] = @doc.row[attributeIndex].strftime('%B')
					elsif filter_value == "year"
						@doc.row[attributeIndex] = @doc.row[attributeIndex].strftime('%Y')
					elsif filter_value == "dayOfYear"
						@doc.row[attributeIndex] = @doc.row[attributeIndex].strftime('%j')
					elsif filter_value == "week"
						@doc.row[attributeIndex] = @doc.row[attributeIndex].strftime('%V')
					elsif filter_value == "dayOfMonth"
						@doc.row[attributeIndex] = @doc.row[attributeIndex].strftime('%-d')
					elsif filter_value == "hour"
						@doc.row[attributeIndex] = @doc.row[attributeIndex].strftime('%k')
					else
						puts "Unknown groupBy value: "
					end

				end

			else
				puts "UNRECOGNIZED conditional name:"
				puts filter_sign
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
			@doc = doc
			next if not meetsCriteria()
 			# Uses @doc reference so it can alter data if needed

 			rowHash = Hash.new
 			rowHash["c"] = Array.new
 			@doc.row.each do |attrVal|
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

	def modifyValueTypes(attrsList, keyIndex, valueIndices)
		# attr hash is an array of {"id": "name of this attr", "type" : "string or number or date"} hashes
		colList = Array.new
		colList << attrsList[keyIndex].deep_dup
		colList[0]["label"] = colList[0]["id"]
		if colList[0]["type"] == "datetime"
			# If the key of the vis is a date, see if it should be adjusted for groupBy
			groupByFilter = findGroupByFilter(attrsList, keyIndex)
			if not groupByFilter.nil?
				if groupByFilter["value"] == "dayOfWeek" or groupByFilter["value"] == "month"
					colList[0]["type"] = "string"
				elsif groupByFilter["value"] == "week" or groupByFilter["value"] == "year" or groupByFilter["value"] == "dayOfYear" or groupByFilter["value"] == "dayOfMonth" or groupByFilter["value"] == "hour"
				   # WHY THE FUCKING FUCK IS RUBY WHITESPACE DEPENDENT?!?!
				   # Using a 200 column line cause Ruby is too cool for line breaks. 
				   colList[0]["type"] = "number"
				end
			end
		end

		valueIndices.each do |valIndex|
			currCol = attrsList[valIndex].deep_dup
			currCol["type"] = "number"
			# Non-key columns will *always* be numeric...    I hope.
			currCol["label"] = currCol["id"]
			colList << currCol
		end
		return colList
	end

	def findGroupByFilter(attrsList, keyIndex)
		# XXX Demo day kludge: filters removed for demo day, add back later!
		return nil if params[:filters].nil? or params[:filters] == ""
		# If the key column is a datetime, grouping dates requires returning a
		# different data type. So find the key/datetime/groupBy filter to check
		params[:filters].each do |key, filter|

			filter_attribute = nil
			if filter.has_key? "key"
				filter_attribute = filter["key"]
			else
				filter_attribute = filter["attribute"]
			end

			filter_sign = nil
			if filter.has_key? "conditional"
				filter_sign = filter["conditional"]
			else
				filter_sign = filter["sign"]
			end
			# TODO: Make this consistent between vis::Create/ dataset::view

			if filter_attribute == attrsList[keyIndex]["id"] and filter_sign == "groupBy"
				return filter
			end
		end
		return nil
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

		# This will have to be looped if we end up supporting generalized multi-key charts
 		dataTableKeyIndex = attrNameToIndex(@dataset.attrs, key_values[0])

 		# Adds all the corresponding values to cols
 		aggregate_values.each do |aggregate_value|
 			index = attrNameToIndex(@dataset.attrs, aggregate_value)
 			dataTableValueIndices << index
 		end
 		@adjustedAttrs = modifyValueTypes(@dataset.attrs, dataTableKeyIndex, dataTableValueIndices)

 		# Complete aggregate hashing
 		dataTableAggregateHash = Hash.new

 		# Iterate over all datadocs
 		@dataset.datadocs.each do |datadoc|
 			@doc = datadoc
 			next if not meetsCriteria()
 			#uses @doc to alter doc by reference if needed

 			if !dataTableAggregateHash.has_key?(@doc.row[dataTableKeyIndex])

 				dataTableAggregateHash[@doc.row[dataTableKeyIndex]] = Array.new(dataTableValueIndices.length, 0)

 			end

 			dataTableValueIndices.each_with_index do |rowIndex, index| 

 				if @dataset.attrs[index]["type"] == "number"
 					dataTableAggregateHash[@doc.row[dataTableKeyIndex]][index] += @doc.row[rowIndex].to_f
 				else
 					dataTableAggregateHash[@doc.row[dataTableKeyIndex]][index] += 1
 					#If the value is non-numeric, jsut count the number of instances
 				end

 			end

 		end



 		dataTableHash["cols"] = @adjustedAttrs


 		# Add our aggregated values as rows into the table hash
 		dataTableHash["rows"] = Array.new

 		# Access the hash by order of sorted keys
 		dataTableAggregateHash.keys.each do |key|
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
 			@doc = datadoc
 			# Uses @doc for pass-by-reference semantics when changing row

 			next if not meetsCriteria()
 			latitude = @doc.row[dataTableLatitudeIndex]
 			longitude = @doc.row[dataTableLongitudeIndex]

 			location = Location.new(latitude, longitude)

 			if !dataTableHash.has_key?(location)
 				dataTableHash[location] = Array.new(dataTableValueIndices.length, 0)
 			end

 			dataTableValueIndices.each_with_index do |rowIndex, index| 
 				begin
 					dataTableHash[location][index] += @doc.row[rowIndex].to_f
 				rescue
  					#If it isn't numeric, just count the number of occurences
  					dataTableHash[location][index] = dataTableHash[location][index] + 1
  				else
  					puts "LOLWUT"
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

end