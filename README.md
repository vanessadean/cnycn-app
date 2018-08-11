# CNYCN Texting Demo App

A version of this app was built for a [Delta.NYC](https://www.civichalllabs.org/probonotech/) pro bono collaboration with the [Center for NYC Neighborhoods](https://cnycn.org/) to help the center stay in touch with clients.

## Setup

Run the following commands:

`gem install bundler`

`bundle`

`bundle exec rake db:migrate`

`cp .env.example .env`

Then add the username, password and Twilio credentials to the `.env` file

## Run

`ruby app.rb`

## Deployed at

https://cnycn-texting-app.herokuapp.com/
