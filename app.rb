require_relative './config/environment'
require_relative './models/client'
require_relative './models/message'
require 'sinatra'
require 'sinatra/reloader' if development?

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [ENV['AUTH_USERNAME'], ENV['AUTH_PASSWORD']]
  end
end

set :public_folder, 'public'

configure :development do
  enable :reloader
  set :database, { adapter: "sqlite3", database: "./db/cnycn.sqlite3" }
end

configure :production do
 db = URI.parse(ENV['DATABASE_URL'] || 'postgres:///localhost/database')

 ActiveRecord::Base.establish_connection(
   :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
   :host     => db.host,
   :username => db.user,
   :password => db.password,
   :database => db.path[1..-1],
   :encoding => 'utf8'
 )
end

get '/' do
  protected!
  @clients = Client.all
  erb :index
end

post '/send' do
  account_sid = ENV['TWILIO_SID'] # Your Account SID from www.twilio.com/console
  auth_token = ENV['TWILIO_AUTH_TOKEN']   # Your Auth Token from www.twilio.com/console

  phone_number = "#{params['phone_number'].gsub(/\D/,'')}"

  if phone_number.length != 10
    redirect to ('/error')
  end

  @client = Client.find_or_create_by(phone_number: phone_number)
  @client.first_name = params['first_name'] if @client.first_name.blank?
  @client.last_name =  params['last_name'] if @client.last_name.blank?

  if @client.save
    @message = Message.new(text: params['message'], client_id: @client.id, outbound: true)
  end

  if @message.save
    begin
      @twilio = Twilio::REST::Client.new account_sid, auth_token
      message = @twilio.messages.create(
        body: params['message'],
        to: "+1#{@client.phone_number}",
        from: ENV['TWILIO_NUMBER'] # Replace with your Twilio number
      )

      puts message.sid
    rescue Twilio::REST::TwilioError => e
      puts e.message
      redirect to ('/error')
    end
    redirect to ("/clients/#{@client.id}")
  else
    redirect to ('/error')
  end
end

get ('/clients/:client_id') do
  protected!
  @client = Client.find(params[:client_id])
  @messages = @client.messages.order(created_at: :asc).group_by { |m| m.date }

  erb :messages
end

post '/receive' do
  phone_number = params['From'].gsub('+1','')
  @client = Client.find_by(phone_number: phone_number)
  if @client.present?
    @message = Message.create(text: params['Body'], client_id: @client.id, inbound: true)
  end
end

get '/error' do
  erb :error
end
