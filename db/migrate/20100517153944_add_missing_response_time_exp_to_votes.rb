class AddMissingResponseTimeExpToVotes < ActiveRecord::Migration
  def self.up
	  add_column :votes, :missing_response_time_exp, :string, :default => ""
	  add_column :skips, :missing_response_time_exp, :string, :default => ""

          begin
	  recording_client_time_start_date = Vote.find(:all, :conditions => 'time_viewed IS NOT NULL', :order => 'created_at', :limit => 1).first.created_at 
          rescue
	   recording_client_time_start_date = nil
          end
	  Vote.find_each do |v|
		  if v.created_at <= recording_client_time_start_date && v.time_viewed.nil?
			  v.missing_response_time_exp = "missing"
			  v.save!
		  elsif v.time_viewed.nil?
			  v.missing_response_time_exp = "invalid"
			  v.save!
		  end
	  end
  end

  def self.down
	  remove_column :votes, :missing_response_time_exp
	  remove_column :skips, :missing_response_time_exp
  end
end
