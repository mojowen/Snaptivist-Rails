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

    form_url signup_or_email

    mail(:to => @email, :subject => "We loved meeting you - one small ask, just press a button")
  end

  def us_tweet(signup,event,facebook_photo=nil)

    @rep_list = signup.reps.map{ |r| [r['title'],r['first_name'],r['last_name'] ].join(' ') }.to_sentence
  	@event_name = event
  	@facebook_photo = facebook_photo
    @email = signup.email

    form_url signup

  	mail(:to => @email, :subject => "We loved meeting you - one small ask, just press a button")
  end

  def form_url signup=nil
    @form_url = "http://soundoffatcongress.org/direct/xy4k?"
    @form_url += "zip=#{signup.zip}" if ! signup.nil? && signup.class == Signup && signup.zip
  end
end
