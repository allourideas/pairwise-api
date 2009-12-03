class PromptsController < ApplicationController
  # GET /prompts
  # GET /prompts.xml
  def index
    @prompts = Prompt.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @prompts }
    end
  end

  # GET /prompts/1
  # GET /prompts/1.xml
  def show
    @prompt = Prompt.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @prompt }
    end
  end

  # GET /prompts/new
  # GET /prompts/new.xml
  def new
    @prompt = Prompt.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @prompt }
    end
  end

  # GET /prompts/1/edit
  def edit
    @prompt = Prompt.find(params[:id])
  end

  # POST /prompts
  # POST /prompts.xml
  def create
    @prompt = Prompt.new(params[:prompt])

    respond_to do |format|
      if @prompt.save
        flash[:notice] = 'Prompt was successfully created.'
        format.html { redirect_to(@prompt) }
        format.xml  { render :xml => @prompt, :status => :created, :location => @prompt }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @prompt.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /prompts/1
  # PUT /prompts/1.xml
  def update
    @prompt = Prompt.find(params[:id])

    respond_to do |format|
      if @prompt.update_attributes(params[:prompt])
        flash[:notice] = 'Prompt was successfully updated.'
        format.html { redirect_to(@prompt) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @prompt.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /prompts/1
  # DELETE /prompts/1.xml
  def destroy
    @prompt = Prompt.find(params[:id])
    @prompt.destroy

    respond_to do |format|
      format.html { redirect_to(prompts_url) }
      format.xml  { head :ok }
    end
  end
end
