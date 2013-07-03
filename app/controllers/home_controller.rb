class HomeController < ApplicationController
	protect_from_forgery :except => :save

	def home
		@signups = Signup.all
	end
	def save
		signup = Signup.new( params[:signup] )
		render :json => {:success =>  signup.save, :signup => params[:signup] }
	end
	def photo
		render :text => File.open( 'public/tmp/'+params[:photo_name]+'.png','rb' ).read
	end
end
