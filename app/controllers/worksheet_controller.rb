class WorksheetController < ApplicationController

	def create

		# If it is a POST request, we are creating a new worksheet
		if request.post?

			# Create a new worksheet from the given information
			worksheet = Worksheet.new
			worksheet.title = params[:title]
			worksheet.description = params[:description]
			worksheet.identifier = SecureRandom.uuid

			# Check that the identifier has not been used yet
			while Worksheet.find_by_identifier(worksheet.identifier)
				worksheet.identifier = SecureRandom.uuid
			end

			# Add worksheet to the current user
			user = User.find(session[:id])
			user.worksheets << worksheet
			user.save

			# Load the edit view for the worksheet
			redirect_to "/worksheet/" + worksheet.identifier + "/edit"

		end

		# Otherwise, just render the prompt to create one

	end


	def edit

		# Retrieve the corresponding worksheet
		@worksheet = Worksheet.find_by_identifier(params[:id])

		# Render with the sparse layout
		render layout: "sparse"

	end

	def view

		# Retrieve the corresponding worksheet
		@worksheet = Worksheet.find_by_identifier(params[:id])

	end

	def destroy

		@worksheet = Worksheet.find_by_identifier(params[:id])
		@worksheet.destroy
		
		redirect_to '/users/profile'

	end

end
