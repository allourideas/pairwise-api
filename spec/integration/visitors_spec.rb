require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Visitors" do
  include IntegrationSupport

  before do
    @user = self.default_user = Factory(:email_confirmed_user)
    @visitors = @user.visitors << Array.new(30){ Factory(:visitor, :site => @user) }
    @questions = Array.new(3){ Factory(:aoi_question, :site => @user, :creator => @visitors.rand) }
  end

  describe "GET 'index'" do
    it "should return an array of visitors" do
      get_auth visitors_path
      response.should be_success
      response.body.should have_tag("visitors visitor", @visitors.size)
    end

    it "should not return other sites' visitors" do
      other_user = Factory(:email_confirmed_user)
      other_visitors = other_user.visitors << Array.new(10) do
        Factory(:visitor, :site => other_user)
      end
      get_auth other_user, visitors_path

      response.should be_success
      response.body.should have_tag("visitors visitor", other_visitors.size)
    end

    it "should return the number of votes for each visitor" do
      counts = Hash.new(0)
      20.times do
        visitor = @visitors.rand
        Factory(:vote, :question => @questions.rand, :voter => visitor)
        counts[visitor.id] += 1
      end
      get_auth visitors_path, :votes_count => true

      response.should be_success
      response.should have_tag "visitor", counts.size do |nodes|
        nodes.each do |node|
          id = node.content("id").to_i
          node.should have_tag("id"), :text => id
          node.should have_tag("votes-count"), :text => counts[id]
        end
      end
    end

    it "should return the number of skips for each visitor" do
      counts = Hash.new(0)
      20.times do
        visitor = @visitors.rand
        Factory(:skip, :question => @questions.rand, :skipper => visitor)
        counts[visitor.id] += 1
      end
      get_auth visitors_path, :skips_count => true

      response.should be_success
      response.should have_tag "visitor", counts.size do |nodes|
        nodes.each do |node|
          id = node.content("id").to_i
          node.should have_tag("id"), :text => id
          node.should have_tag("skips-count"), :text => counts[id]
        end
      end
    end

    it "should return the number of user-submitted choices" do
      10.times do
        question = @questions.rand
        creator = question.creator
        Factory(:choice, :question => question, :creator => creator)
      end
      counts = Hash.new(0)
      10.times do
        question = @questions.rand
        creator = (@visitors - [question.creator]).rand
        counts[creator.id] += 1
        Factory(:choice, :question => question, :creator => creator)
      end
      get_auth visitors_path :ideas_count => true
      
      response.should be_success
      response.should have_tag "visitor", counts.size do |nodes|
        nodes.each do |node|
          id = node.content("id").to_i
          node.should have_tag("id"), :text => id
          node.should have_tag("ideas-count"), :text => counts[id]
        end
      end
    end

    it "should show which visitors are bounces" do
      bounce = {}
      @visitors.each do |v|
        if [true,false].rand
          Factory(:appearance, :question => @questions.rand, :voter => v)
          bounce[v.id] = 1
        else
          vote = Factory(:vote, :question => @questions.rand, :voter => v)
          Factory(:appearance, :question => @questions.rand,
                  :voter => v, :answerable => vote)
        end
      end
      get_auth visitors_path, :bounces => true

      response.should be_success
      response.should have_tag "visitor", bounce.size do |nodes|
        nodes.each do |node|
          id = node.content("id").to_i
          node.should have_tag "id", :text => id
          node.should have_tag "bounces", :text => 1
        end
      end
    end

    it "should return the number of questions created for each visitor" do
      count = @visitors.inject({}) do |h,v|
        n = @questions.select{ |q| q.creator == v }.size
        h[v.id] = n unless n.zero?
        h
      end
      get_auth visitors_path, :questions_created => true

      response.should be_success
      response.should have_tag "visitor", count.size do |nodes|
        nodes.each do |node|
          id = node.content("id").to_i
          node.should have_tag "id", :text => id
          node.should have_tag "questions-created", :text => count[id]
        end
      end
    end

    it "should return the visitor counts for a single question" do
      votes, skips, choices = Array.new(3){ Hash.new(0) }
      the_question = @questions.rand
      20.times do
        question = @questions.rand
        visitor = (@visitors - [question.creator]).rand
        case rand(3)
        when 0 then
          Factory(:vote, :question => question, :voter => visitor)
          votes[visitor.id] += 1 if question == the_question
        when 1 then
          Factory(:skip, :question => question, :skipper => visitor)
          skips[visitor.id] += 1 if question == the_question
        when 2 then
          Factory(:choice, :question => question, :creator => visitor)
          choices[visitor.id] += 1 if question == the_question
        end
      end
      visitors = (votes.keys | skips.keys | choices.keys)

      get_auth visitors_path, {
        :votes_count => true,
        :skips_count => true,
        :ideas_count => true,
        :question_id => the_question.id
      }

      response.should be_success
      response.should have_tag "visitor", visitors.size do |nodes|
        nodes.each do |node|
          id = node.content("id").to_i
          node.should have_tag "id", :text => id
          node.should have_tag "votes-count", :text => votes[id]
          node.should have_tag "skips-count", :text => skips[id]
          node.should have_tag "ideas-count", :text => choices[id]
        end
      end
    end

    it "should return the bounces for a single question" do
      the_question = @questions.rand
      bounces = @visitors.inject({}) do |h,v|
        if v.id.odd?  # bounce!
          question = @questions.rand
          Factory(:appearance, :question => question, :voter => v)
          h[v.id] = 1 if question == the_question
        else          # appearance w/ answerable
          vote = Factory(:vote, :question => @questions.rand, :voter => v)
          Factory(:appearance, :question => @questions.rand, :voter => v, :answerable => vote)
        end
        h
      end

      get_auth visitors_path, :bounces => true, :question_id => the_question.id
      response.should be_success
      response.should have_tag "visitor", bounces.size do |nodes|
        nodes.each do |node|
          id = node.content("id").to_i
          node.should have_tag "id", :text => id
          node.should have_tag "bounces", :text => bounces[id]
        end
      end
    end
  end
  

end
