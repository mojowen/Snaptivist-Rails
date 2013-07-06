class WelcomeMailer < ActionMailer::Base
  default from: "Mike White <info@theallycoalition.org>"

  def canadian(email,event,facebook_photo=nil)
  	@facebook_photo = facebook_photo
    @event = event
  	mail(:to => email, :subject => "We loved meeting you, did you see your picture?")
  end
  def us_no_tweet(signup_or_email,event,facebook_photo=nil)

    @facebook_photo = facebook_photo
    @email= signup_or_email.class == String ? signup_or_email : signup_or_email.email
    @event = event

    form_url signup_or_email, @email

    mail(:to => @email, :subject => "We loved meeting you - one small ask, just press a button")
  end

  def us_tweet(signup,event,facebook_photo=nil)

    @rep_list = signup.reps.map{ |r| [r['title'],r['first_name'],r['last_name'] ].join(' ') }.to_sentence
  	@event_name = event
  	@facebook_photo = facebook_photo
    @email = signup.email

    form_url signup, @email, signup.reps.map{ |r| [r['bioguide'] }.join(',')

  	mail(:to => @email, :subject => "We loved meeting you - one small ask, just press a button")
  end

  def form_url signup=nil,email=nil, reps=nil
    @form_url = "http://theallycoalition.org/soundoff"
    @form_url =+"?email=#{email}" unless email.nil?

    if ! signup.nil? && signup_or_email.class == Signup
      @form_url =+ "&zip=#{signup.zip}" if signup.zip
      @form_url =+ "&firstName=#{signup.firstName}" if signup.firstName
      @form_url =+ "&lastName=#{signup.lastName}" if signup.lastName
    end

  end
end
