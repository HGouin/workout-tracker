class User < ActiveRecord::Base
    validates_presence_of :username
    has_secure_password
    has_many :user_workouts
    has_many :workouts, through: :user_workouts
end