class CreateWorkouts < ActiveRecord::Migration
  def change
    create_table :workouts do |t|
      t.text :name
      t.integer :duration_minutes
      t.text :content
      t.integer :user_id
    end
  end
end
