class SleepProcessor

	@queue = :sleep

	def self.perform

		users = User.all

		print users

	end

end