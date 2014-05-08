class UsersController < ApplicationController

	def login

		# If the user is logged in already, redirect them to their profile
		if session[:id]

			redirect_to action: "profile"

		end

		# Check to see if we are submitting login information
		if request.post?

			email = params[:email]
			
			user = User.find_by_email(email)
			if user && (user.password == params[:password]) 

				# Initialize a session for the current user
				session[:id] = user.id

				# Redirect to their profile
				redirect_to action: :profile

			else

				# Flash this message up
				flash.now[:error] = "Email or password is incorrect. Please try again."

			end

		end

		# Login page served if it is a GET request or the POST
		# request doesn't go anywhere

	end

	def logout

		# Resets the session variables
		session.delete(:id)

		# Redirect to the login page
		redirect_to action: :login

	end

	def register

		# Check if we are submitting a registration
		if request.post?

			# Create a user object
			user = User.new
			user.email = params[:email]
			user.password = params[:password]

			#hardcoded id of the olympians dataset so new users have something to play with

			# Validate the user
			if user.valid?
				olympians = Dataset.find_by_identifier("535eebef73796e1711010000")
				user.datasets << olympians if not olympians.nil?

				# Save if everything is ok
				user.save

				# Redirect back to the login page
				redirect_to action: :login

			else

				flash.now[:error] = "That email is already registered."

			end

		end

		# Otherwise, the registration page is served up

	end

	def profile

		# Check to see if the user is logged in
		if not session[:id]

			# Redirect to login page
			redirect_to action: :login

		end

		# Otherwise load the user corresponding to the session ID
		@user = User.find(session[:id])

	end

end
