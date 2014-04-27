require 'chronic'

class DatasetProcessor

	@queue = :dataset

	def self.perform(data, rows)

		# Get the correct dataset
		ds = Dataset.find_by_identifier(data['identifier'])

		# Generate all the hashes
		rows.each do |row|
			thisRow = Array.new
			row.each_with_index do |attribute, index|
				if row[index] != nil
					row[index] = row[index].force_encoding("utf-8")
				end
				thisRow << row[index]
			end
			newDoc = Datadoc.new
			newDoc.row = thisRow

			# Put it into our dataset
			ds.datadocs.push(newDoc)
			
		end
 		ds.save
	end

end
