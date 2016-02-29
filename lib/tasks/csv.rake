namespace :csv do
  desc "Export question data to csv"
  task :question_export, [:question_id, :type, :filename] => [:environment] do |t, args|
    q = Question.find(args[:question_id])
    File.open(args[:filename], 'w', :external_encoding => Encoding::UTF_8) do |file|
      q.to_csv(args[:type]).each do |row|
        file.write(row)
        file.flush
      end
    end
  end
end
