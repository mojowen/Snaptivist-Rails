# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
SnaptivistRails::Application.config.secret_token = ENV['SECRET'] || '06a955419ede82a5253e73ddec34626f95460f84697588f68f46a9798d2c886dbee8355f7afafa134d734184a9903c88e14f66676b1ff130c4fab81262178b70'
