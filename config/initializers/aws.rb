AWS::S3::Base.establish_connection!(
    :access_key_id     => ENV['AWS'],
    :secret_access_key => ENV['AWS_ACCESS_KEY']
  )