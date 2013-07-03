class HomeController < ApplicationController
	def home
		@signups = Signup.all
	end
	def save
		signup = Signup.new( params[:signup] )
		render :json => {:success =>  signup.save, :signup => params[:signup] }
	end
	def photo
		render :text => File.open( 'tmp/'+params[:photo_name]+'.png','rb' ).read
	end
end
