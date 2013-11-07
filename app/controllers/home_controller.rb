class HomeController < ApplicationController
	protect_from_forgery :except => :save
	before_filter :require_login, :only => [:list,:analytics]

	def home
		@body_class = 'home'
	end
	def save
		params[:signup][:photo_date] =  ( Time.parse( params[:signup][:photo_date] ) - 4.hours ).to_date if params[:signup] && params[:signup][:photo_date]

		signup = Signup.new( params[:signup] )
		if  signup.match_or_save
			render :json => {:success => true, :signup => params[:signup] }, :template => false
		else
			render :json => {:success => false, :signup => params[:signup], :errors => signup.errors }, :template => false, :status => 500
		end
	end


	def analytics
		@title = 'ANALYTICS'
		@by_show = Signup.all(
			:select => 'COUNT(*) as "count", COUNT(statuses) as "tweets", source, photo_date, COUNT(CASE WHEN signups.photo_path IS NOT NULL THEN 1 ELSE null END) as "has_photo"',
			:group => 'source, photo_date',
			:joins => :statuses,
			:order => "signups.photo_date desc"
		)
	end
	def list
		if ! params[:export]
			limit = { :limit => 30, :offset => params[:offset], :order => 'created_at DESC' }
		else
			limit = {}
		end

		case params[:type]
			when 'tweets'
				@type = 'tweet'
				@diclaimer = 'only includes sent tweets.'

				limit[:conditions] = 'sent IS TRUE'
				@items = Status.all(limit).sort_by(&:sent_at).reverse

				@mapping = ['target','sender','message','photo_path','sent_at','zip']
				@title_row = ['target','sender','messsage','photo','sent date','from zip']

			when 'emails'
				@type = 'email'
				@diclaimer = 'also includes friends'

				@title_row = ['email','first name','last name','zip','source','signed up at']
				@mapping = ['email','firstName','lastName','zip_code','source','photo_date']

				@items = Signup.all(limit)
				friends = []
				@items.each{ |s| (s.friends || '' ).split(',').each{ |email| friends.push( { :email => email, :source => s.source, :photo_date => s.photo_date } ) } }
				@items.concat friends


			else
				@type = 'signup'
				@items = Signup.all(limit)

				@mapping = ['firstName','lastName','email','source','photo_date','facebook_photo','photo_path','twitter','zip','tweet_count','friend_count']
				@title_row = ['first name','last name','email','source','date taken','facebook photo link','raw photo link','twitter name','zip','number of tweets','number of friends']
		end
		render :template => 'home/export', :layout => false if params[:export]
		render :template => 'home/list', :layout => false if params[:partial]
	end

end
