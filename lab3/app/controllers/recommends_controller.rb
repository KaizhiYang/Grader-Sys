class RecommendsController < ApplicationController

  before_action :authenticate_instructor!, only:[:new, :create]
  before_action :authenticate_admin!, only: [:show_student, :approve_request, :deny_request]

  # GET /recommends or /recommends.json
  def index
    @recommends = Recommend.all
  end

  # GET /recommends/1 or /recommends/1.json
  def show_section
    if session[:accessed_from_edit]
      # Ensure that @request is set
      @request = Request.find_by_id(params[:id])

      if @request.present?
        @courses = Course.where(catalog_number: @request.course_id)
      else
        # Handle the case where @request is not found
        redirect_to course_path, alert: "Request not found."
      end
      # Reset the session variable
      session[:accessed_from_edit] = nil
    else
      redirect_to courses_path, notice: "Direct access is not allowed."
    end
  end

  # GET /recommends/new
  def new
    @recommend = Recommend.new
  end

  # GET /recommends/1/edit
  def edit
    #@recommend=Recommend.find(params[:id]);
  end

  # POST /recommends or /recommends.json
  def create

    session[:accessed_from_edit] = true
    choice = params[:recommend][:choice]
    # Create User, Person, and Student only if they don't exist
    user = User.find_or_create_by(email: params[:recommend][:student_email]) do |u|
      u.password = "123456" # Replace with secure password logic
    end

    Person.find_or_create_by(email: params[:recommend][:student_email]) do |p|
      p.first_name = params[:recommend][:student_first_name]
      p.last_name = params[:recommend][:student_last_name]
      p.role = "student"
      p.user_id = user.id
    end

    Student.find_or_create_by(student_email: params[:recommend][:student_email])
    
    # Processing based on the choice
    if choice == 'Future consideration'
      # Process data for future in recommends
      # Logic for option A - Save in Recommends model
       # Find or initialize a new Recommend
      @recommend = Recommend.find_or_initialize_by(recommend_params)

      if @recommend.new_record?
        if @recommend.save
          redirect_to courses_url, notice: "Recommendation was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      else
        redirect_to courses_url, notice: "The recommendation already exists."
      end
      

    elsif choice == 'Request for upcoming semester'
      # Process data for now in requests
      # Logic for option B - Save in Request model
      # Find or initialize a new Request
      @request = Request.find_or_initialize_by(request_params)

      if @request.new_record?
        if @request.save
          redirect_to show_section_recommend_path(@request), notice: "Request was successfully created and please select your section."
        else
          render :new, status: :unprocessable_entity
        end
      else
        redirect_to courses_url, notice: "The request already exists."
      end
    end

  end

  #if selected section, update request with that section num
  def choose_section

        @request = Request.find(params[:request_id])
        @section = Section.find(params[:section_id])

        if @request && @section
          @request.update(section_id: @section.id)
          redirect_to courses_url, notice: 'Section chosen successfully.' 
        else
          redirect_to courses_url, alert: 'Failed to choose section.' 
        end
  end


  # PATCH/PUT /recommends/1 or /recommends/1.json
  def update
    @request = Request.find(params[:id])
    session[:accessed_from_edit] = true
    respond_to do |format|
      if @recommend.update(recommend_params)
        format.html { redirect_to recommend_url(@recommend), notice: "Request was successfully updated." }
        format.json { render :show, status: :ok, location: @recommend }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @recommend.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /recommends/1 or /recommends/1.json
  def destroy
    @recommend.destroy

    respond_to do |format|
      format.html { redirect_to recommends_url, notice: "Recommend was successfully destroyed." }
      format.json { head :no_content }
    end
  end


  def approve_request
    # Find the request by ID
    @request = Request.find_by(id: params[:id])
  
    # Check if the request exists
    if @request.nil?
      redirect_to manage_real_applications_path, alert: 'Request not found.'
      return
    end
  
    # Update the request status to 'approved'
    if @request.update(status: 'approved')
      # Check if the request has an associated section
      if @request.section_id.present?
        section = Section.find_by(s_id: @request.section_id)
  
        if section
          # Update section details
          section.grader_needed -= 1 if section.grader_needed > 0
          section.grader = if section.grader.blank?
                             @request.student_email
                           else
                             "#{section.grader}, #{@request.student_email}"
                           end
  
          section.save
        end
      end
  
      redirect_to manage_real_applications_path, notice: 'Request approved successfully.'
    else
      redirect_to courses_path, alert: 'Failed to approve Request.'
    end
  end
  

  def deny_request
    @request = Request.find_by(id: params[:id])
  
    if @request.nil?
      redirect_to courses_path, alert: 'Request not found.'
      return
    end
  
    if @request.update(status: 'denied')
      redirect_to manage_real_applications_path, notice: 'Request denied successfully.'
    else
      redirect_to courses_path, notice: 'Failed to deny request.'
    end
  end

  def show_student
    @request = Request.find_by_id(params[:request_id])
    # First, ensure that you have a valid request object.
    # If not, redirect or handle the error appropriately.
    if @request.nil?
      redirect_to courses_url, notice: 'Student Not found.'
      return
    end
  
    # Find the student based on the email from the request.
    @student = Student.find_by(student_email: @request.student_email)
  
    # If the student is found, proceed to find their application and associated information.
    if @student
      @informationID = GraderApplication.find_by(student_email: @student.student_email)
  
      # Only fetch times and courses if a valid GraderApplication is found.
      if @informationID
        @times = AvailableTime.where(applications_id: @informationID.id)
        @courses = StudentRequestCourse.where(applications_id: @informationID.id)
      else
        # Set times and courses to empty arrays if no GraderApplication is found.
        @times = []
        @courses = []
      end
  
      # Fetch evaluations for the student.
      @evaluations = Evaluation.where(student_email: @student.student_email)
    else
      # Handle the scenario where the student is not found.
      # You can redirect or set a flash message to indicate the student was not found.
      redirect_to courses_path, alert: "Student not found."
    end
  end
  
  private
    # Only allow a list of trusted parameters through.

    def recommend_params
      params.require(:recommend).permit(:student_email, :course_id, :faculty_email)
    end
    
    def request_params
      params.require(:recommend).permit(:student_email, :course_id, :section_id, :faculty_email)
    end
    
end