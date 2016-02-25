namespace :csv do
  desc "Export question data to csv"
  task :question_export, [:question_id, :type, :filename] => [:environment] do |t, args|
    q = Question.find(args[:question_id])
    csv_data = q.to_csv(args[:type])
    File.open(args[:filename], 'w', :external_encoding => Encoding::UTF_8) do |file|
      file.write(csv_data)
    end
  end
end
