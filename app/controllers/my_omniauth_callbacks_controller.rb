class MyOmniauthCallbacksController < Devise::OmniauthCallbacksController

	def twitter
	 	raise request.env["omniauth.auth"].to_yaml
	 	#  Will need to translate this into a user sign in
	end
	def facebook
	 	raise request.env["omniauth.auth"].to_yaml
	 	#  Will need to translate this into a user sign in
	end

end