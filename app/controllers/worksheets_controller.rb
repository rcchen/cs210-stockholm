class WorksheetsController < ApplicationController

	# GET /worksheets
	def index
		@worksheets = Worksheet.all
	end

	# GET /worksheets/new
	def new

	end

	# GET /worksheets/:id
	def show
		@worksheet = Worksheet.find_by_identifier(params[:id])
		render json: @worksheet
	end

	# GET /worksheets/:id/edit
	def edit

		# Retrieve the corresponding worksheet
		@worksheet = Worksheet.find_by_identifier(params[:id])

		# Get the user's datasets
		@datasets = User.find(session[:id]).datasets

		# Render with the sparse layout
		render layout: "sparse_worksheet"

	end

	# POST /worksheets
	def create


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
		redirect_to "/worksheets/" + worksheet.identifier + "/edit"


		# Otherwise, just render the prompt to create one

	end

	# PATCH /worksheets/:id
	# PUT /worksheets/:id
	def update

		# Get the current worksheet
		worksheet = Worksheet.find_by_identifier(params[:id])

		# Update the data
		# TODO: Actually sanitize the HTML data
		worksheet.data = params[:data]

		# Save the worksheet
		worksheet.save

		render :text => ""

	end

	# DELETE /worksheets/:id
	def destroy
		@worksheet = Worksheet.find_by_identifier(params[:id])
		@worksheet.destroy
		redirect_to "/users/profile"
	end

end
