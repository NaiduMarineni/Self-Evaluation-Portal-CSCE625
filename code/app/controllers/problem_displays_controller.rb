class ProblemDisplaysController < ApplicationController
  def quiz
    @topics = Topic.all
  end

  def selected
    session[:topics] = params[:selected].select{|k,v| v=='1'}.keys.map{|v| v}
    session[:problems] = session[:topics].map{|v| Topic.find(v).problems.map{|w| w.id}}.flatten(1)
    session[:quiz_type] = params[:selected][:quiz_type]

    session[:current_problem] = 0


    if(session[:problems].size == 0)

    end

    if(session[:quiz_type] == "Flashcard")
      redirect_to(quiz_flashcard_question_url)
    else
      session[:answers] = Array.new(session[:problems].size,"")
      redirect_to(quiz_problem_url)
    end
  end

  def quiz_problem

    if(params[:nextid])
      @thisid = params[:nextid].to_i
    else
      @thisid = 0
      session[:tillid] = 0
    end
  
    @tillid = session[:tillid].to_i
    if(@tillid < @thisid)
      session[:tillid] = @thisid
    end
    
    session[:current_problem] = @thisid
    @lastanswer =  session[:answers][@thisid]

    @problem = Problem.find(session[:problems][@thisid])
    @option = @problem.options
  end

  def quiz_problem_answer

    if(params[:nextid])
      @thisid = params[:nextid].to_i
    else
      @thisid = 0
      session.delete(:result)                                                   #clear the result from session once a new eval is triggered
    end
  
    @tillid = session[:tillid].to_i
    
    session[:current_problem] = @thisid
    @lastanswer =  session[:answers][@thisid]
    @problem = Problem.find(session[:problems][@thisid])
    
    @correct_answers = Array.new      
    if(@problem.question_type.question_type == "MCQ")
      @correct_answers = @problem.options.where("is_answer = true").pluck(:answer)
    end
    if(@problem.question_type.question_type == "Short Answer")
      @correct_answers.push(@problem.answer)
    end
    
    @your_answers = Array.new      
    if(@problem.question_type.question_type == "MCQ")
      if(!@lastanswer.nil? && !@lastanswer.empty?)
        @lastanswer.each do |id|
          @your_answers.push(Option.find(id).answer)
        end
      end
    end
    if(@problem.question_type.question_type == "Short Answer")
      if(!@lastanswer.nil? && !@lastanswer.empty?)
        @your_answers.push(@lastanswer)
      end
    end
    
    if(!session[:result])
      i=0
      result = 0
      session[:topic_results] = Hash.new
      session[:topic_problems] = Hash.new
      session[:topic_names] = Hash.new
      session[:results] = Hash.new
      session[:topics].each do |id|
        session[:topic_names][id] = Topic.find(id).name
        session[:topic_results][id] = 0
        session[:topic_problems][id] = 0
      end
      while(i<=@tillid)
        @problem = Problem.find(session[:problems][i])
        @topic = @problem.topic
        if(@problem.question_type.question_type == "MCQ")
          @correct_answer = @problem.options.where("is_answer = true").pluck(:id)
        end
        if(@problem.question_type.question_type == "Short Answer")
          @correct_answer = @problem.answer
        end
        @your_answer = session[:answers][i]
        if(@problem.question_type.question_type == "MCQ")
          @ans = Array.new
          if(!@your_answer.nil? && !@your_answer.empty?)
            @your_answer.each do |ans|
              @ans.push(ans.to_i)
            end
          end
          if ((@correct_answer - @ans).empty? && (@ans - @correct_answer).empty?)
            result += 1
            session[:topic_results][@topic.id.to_s] += 1
            session[:results][i.to_s] = true
          else
            session[:results][i.to_s] = false
          end
        end
        if(@problem.question_type.question_type == "Short Answer")
          jarow = FuzzyStringMatch::JaroWinkler.create( :native )
          accuracy = jarow.getDistance(@correct_answer.downcase, @your_answer.downcase)
          if(accuracy >= 0.7)
            result += 1
            session[:topic_results][@topic.id.to_s] += 1
            session[:results][i.to_s] = true
          else
            session[:results][i.to_s] = false
          end
        end
        session[:topic_problems][@topic.id.to_s] += 1
        i += 1
      end
      session[:result] = result
    end
  end

  def save_answer
    @thisid = session[:current_problem]
    @problem = Problem.find(session[:problems][@thisid])
    if(@problem.question_type.question_type == "Short Answer")
      session[:answers][@thisid] = params[:student][:answer]
    end
    if(@problem.question_type.question_type == "MCQ")
      session[:answers][@thisid] = params[:options]
    end
    @lastanswer =  session[:answers][@thisid]
    @option = @problem.options
    render 'quiz_problem'
  end

  def quiz_flashcard_question
    if(params[:nextid])
      @thisid = params[:nextid].to_i
    else
      @thisid = 0
    end
    @problem = Problem.find(session[:problems][@thisid])
  end

  def quiz_flashcard_answer
    if(params[:nextid])
      @thisid = params[:nextid].to_i
    else
      @thisid = 0
    end
    @problem = Problem.find(session[:problems][@thisid])
    @correct_answers = Array.new      
    if(@problem.question_type.question_type == "MCQ")
      @correct_answers = @problem.options.where("is_answer = true").pluck(:answer)
    end
    if(@problem.question_type.question_type == "Short Answer")
      @correct_answers.push(@problem.answer)
    end
  end

end
