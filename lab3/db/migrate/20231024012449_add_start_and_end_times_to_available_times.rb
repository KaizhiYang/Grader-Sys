class AddStartAndEndTimesToAvailableTimes < ActiveRecord::Migration[7.0]
  def change
    add_column :available_times, :start_time, :time
    add_column :available_times, :end_time, :time
  end
end
