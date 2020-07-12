class Workout < ActiveRecord::Base
    validates_presence_of :name, :duration_minutes, :content
    has_many :user_workouts
    has_many :users, through: :user_workouts
    belongs_to :user
end