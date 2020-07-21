require "./config/environment"
require "./app/models/user"
class ApplicationController < Sinatra::Base
  configure do
    set :views, "app/views"
    enable :sessions
    set :session_secret, "oiuiiuh"
  end

  set :public_folder, File.dirname(__FILE__) + '/public'

  get "/" do
    erb :index
  end

  get "/signup" do
    erb :signup
  end

  post "/signup" do
    if params[:username].empty?
      @error_message = "Username must not be empty"
      return erb :signup
    elsif params[:password].empty? || params[:password].length < 6
      @error_message = "Password must be at least 6 characters"
      return erb :signup
    end
    
    user = User.find_by(username: params[:username])
    if user != nil
      @error_message = "User already exists, please choose a different username"
      return erb :signup
    end

    User.create(username: params[:username], password: params[:password])
    redirect "/login"
  end

  get '/account' do
    if !logged_in?
      redirect '/'
    end
    @workouts = Workout.all
    @user_workouts = UserWorkout.where(:user_id => session[:user_id]).order(:created_at).reverse_order
    erb :account
  end


  get "/login" do
    erb :login
  end

  post "/login" do
    if params[:username].empty?
      @error_message = "Username must not be empty"
      return erb :login
    elsif params[:password].empty? || params[:password].length < 6
      @error_message = "Password must be at least 6 characters"
      return erb :login
    end
    user = User.find_by(:username => params[:username])

    if user == nil
      @error_message = "Unable to find user with that username"
      return erb :login
    end

    if !user.authenticate(params[:password])
      @error_message = "Incorrect password"
      return erb :login
    end

    session[:user_id] = user.id
    redirect to "/account"
  end

  get "/logout" do
    session.clear
    redirect "/"
  end

  get "/workouts/new" do
    return redirect "/error" if !logged_in?
    erb :'workouts/new'
  end

  get "/workouts/edit/:id" do
    return redirect "/error" if !logged_in?
    @workout = Workout.find_by_id(params[:id])
    if @workout == nil || @workout.user_id != session[:user_id]
      redirect "/error"
    end
    erb :'workouts/edit'
  end

  post "/workouts/edit/:id" do
    return redirect "/error" if !logged_in?
    @workout = Workout.find_by_id(params[:id])
    if @workout == nil || @workout.user_id != session[:user_id]
      redirect "/error"
      return
    end
    if params[:name].empty?
      @error_message = "Name must not be empty"
      return erb :'workouts/edit'
    elsif params[:content].empty?
      @error_message = "Content must not be empty"
      return erb :'workouts/edit'
    elsif params[:duration].empty? || params[:duration].to_i <= 0
      @error_message = "Duration must be a number greater than 0"
      return erb :'workouts/edit'
    end
    
    @workout.name = params[:name]
    @workout.duration_minutes = params[:duration]
    @workout.content = params[:content]
    @workout.save
    redirect "/workouts/#{params[:id]}"
  end

  post "/workouts/delete/:id" do
    return redirect "/error" if !logged_in?
    workout = Workout.find_by_id(params[:id])
    if workout == nil || workout.user_id != session[:user_id]
      redirect "/error"
      return
    end
    workout.destroy
    redirect "/account"
  end

  get "/workouts/:id" do
    return redirect "/error" if !logged_in?
    @workout = Workout.find_by_id(params[:id])
    if @workout == nil
      redirect "/error"
    end
    @is_owner = @workout.user_id == session[:user_id]
    @user_workouts = UserWorkout.where(:user_id => session[:user_id], :workout_id => params[:id]).order(:created_at).reverse_order

    user_workouts = UserWorkout.where(:workout_id => params[:id])
    @total_count = user_workouts.count
    @user_count = user_workouts.select(:user_id).distinct.count

    erb :'/workouts/show'
  end

 
  post "/user_workouts/delete/:id" do
    return redirect "/error" if !logged_in?
    user_workout = UserWorkout.find_by_id(params[:id])
    if user_workout == nil || user_workout.user_id != session[:user_id]
      redirect "/error"
    end
    user_workout.destroy
    redirect "/account"
  end

  post "/user_workouts/:id" do
    if !logged_in? || Workout.find_by_id(params[:id]) == nil
      redirect "/error"
    end
    UserWorkout.create(:user_id => session[:user_id], :workout_id => params[:id])
    redirect "/workouts/#{params[:id]}"
  end
  
  post "/workouts" do
    return redirect "/error" if !logged_in? 
    if params[:name].empty?
      @error_message = "Name must not be empty"
      return erb :'workouts/new'
    elsif params[:content].empty?
      @error_message = "Content must not be empty"
      return erb :'workouts/new'
    elsif params[:duration].empty? || params[:duration].to_i <= 0
      @error_message = "Duration must be a number greater than 0"
      return erb :'workouts/new'
    end
    Workout.create(:name => params[:name],:duration_minutes => params[:duration].to_i, :content => params[:content], :user_id => session[:user_id])
    redirect "/account"
  end

  get "/error" do
    status 500
    erb :error
  end

  get "*" do
    status 404
    erb :not_found
  end

  helpers do
    def logged_in?
      !!session[:user_id]
    end

    def current_user
      User.find_by_id(session[:user_id])
    end
  end

end