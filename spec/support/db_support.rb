module DBSupport

  # this is useful after a before :all block fills the db with stuff
  def truncate_all
    (ActiveRecord::Base.connection.tables - ["schema_migrations"]).each do |table|
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table};")
    end
  end

end
