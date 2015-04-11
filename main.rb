require 'sinatra'
require 'sinatra/reloader'
require 'mongo'
require 'bcrypt'

connection = Mongo::Connection.new('localhost', 27272)
db = connection.db('pizza_colle')
coll = db.collection('test')

# session を使う
enable :sessions
set :session_secret, "My session secret"

# ページの方でもsession を使えるように
before do
  @session = session
end

# helper!!!!!!
helpers do
  def check_session
    if session[:user] == nil
      redirect '/login_form'
    end
  end
end

get '/' do
  p session
  @title = 'ピザ・コレクション'
  erb :index
end
# ---------- ログイン関連 ----------
# ログイン画面
get '/login_form' do
  @title = 'ログイン画面'
  if session[:user]
    redirect "/home"
  end
  erb :login_form
end

# ログインの時
post '/session' do
  if session[:user]
    redirect "/home"
  end
  user_name = @params[:user_name]
  password = @params[:password]

  # 照合
  tmp_user = nil
  coll.find('name' => user_name).each {|row| tmp_user = row.to_h}
  if tmp_user != nil && tmp_user['password_hash'] == BCrypt::Engine.hash_secret(password, tmp_user['user_salt'])
    session[:user] = user_name
    redirect "/home"
  else
    redirect '/login_form'
  end
end

# ログアウトの時
get '/session' do
  if session[:user] == nil
    redirect '/'
  end

  session.clear
  redirect '/'
end

# ユーザー登録画面
get '/regist_form' do
  @title = '着任式'
  erb :regist_form
end

# 登録処理
post '/regist_user' do
  user_name = @params[:user_name]
  password = @params[:password]
  
  # 重複チェック
  tmp = []
  coll.find('name' => user_name).each {|row| tmp << row}
  
  if tmp != []
    # 重複してる
    @duplicate = true
    erb :regist_form
  else
    # 登録
    user_salt = BCrypt::Engine.generate_salt
    password_hash = BCrypt::Engine.hash_secret(password, user_salt)
    doc = {
      'name' => user_name,
      'user_salt' => user_salt,
      'password_hash' => password_hash
    }
    coll.insert(doc)
    
    session[:user] = user_name
    redirect "/home"
  end
  #これで照合するらしい
end


# ---------- ユーザーページ! ----------
# ユーザーのホーム画面
get '/home' do
  check_session()
  erb :home
end

# ピッツァ
get '/pizza' do
  check_session()
  erb :pizza
end
