#require 'fastercsv'

q = Question.find(109)

the_prompts = q.prompts_hash_by_choice_ids

#hash_of_choice_ids_from_left_to_right_to_votes
the_hash = {}
the_prompts.each do |key, p|
	left_id, right_id = key.split(", ")
        if not the_hash.has_key?(left_id)
	   the_hash[left_id] = {}
	   the_hash[left_id][left_id] = 0
	end

        the_hash[left_id][right_id] = p.votes.size
end

the_hash.sort.each do |xval, row|
	rowarray = []
	row.sort.each do |yval, cell|
		rowarray << cell
	end
	puts rowarray.join(", ")
end
