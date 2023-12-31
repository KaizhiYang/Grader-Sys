class CoursesController < ApplicationController
  before_action :set_course, only: %i[ show edit update destroy ]
  before_action :authenticate_admin!, only: [:new, :edit, :create, :update, :destroy, :reset]
  # GET /courses or /courses.json
  def index
    if user_signed_in?
      @user = current_user 
      @person = Person.find(@user.email)
    else
      redirect_to root_path, notice: 'Login Please!'
      return # Add return here to prevent further execution after redirect
    end
    begin
      # only the course same as selected params
      @pagy, @courses = pagy(Course.all)
      @academic_careers = Course.pluck(:academic_career).uniq.compact
      @campus = Course.pluck(:campus).uniq.compact
      @term = Course.pluck(:term).uniq.compact

      # Fetch the set of number of grader needed from all sections
      @grader_needed = Section.where(course_id: @courses.pluck(:course_id)).pluck(:grader_needed).uniq.compact
      
      #Up to 500 items will show when searching
      if params[:academic_career].present?
        @pagy, @courses = pagy(@courses.where(academic_career: params[:academic_career]), items:500)
      end
      
      if params[:campus].present?
        @pagy, @courses = pagy(@courses.where(campus: params[:campus]), items:500)
      end
      
      if params[:term].present?
        @pagy, @courses = pagy(@courses.where(term: params[:term]), items:500)
      end
      
      if params[:search_query].present?
        @pagy, @courses = pagy(@courses.where("catalog_number LIKE ?","%#{params[:search_query]}%"), items:500)
      end 
    rescue Pagy::OverflowError
      # Handle the overflow error, e.g., by redirecting to the first page
      redirect_to courses_path(page: 1), alert: "Requested page is out of range. Showing first page instead."
    end
  end

  # GET /courses/1 or /courses/1.json
  def show
  end

  # GET /courses/new
  def new
    @course = Course.new
  end

  # GET /courses/1/edit
  def edit
    @course = Course.find(params[:id])
  end

  # POST /courses or /courses.json for adding a new course
  def create
    @course = Course.new(course_params)

    if @course.save
      redirect_to @course, notice: 'Course was successfully created.'
    else
      render 'new', notice: 'Course was NOT successfully created.'
    end
  end

  # PATCH/PUT /courses/1 or /courses/1.json for editing a course
  def update
    @course = Course.find(params[:id])
    if @course.update(course_params)
      # successful update
      redirect_to @course, notice: 'Course was successfully updated.'
    else
      # update errors
      render :edit, notice: 'Course was NOT successfully updated.'
    end
  end
  

  # DELETE /courses/1 or /courses/1.json
  def destroy
    @course = Course.find(params[:id])
    @course.destroy
    redirect_to courses_url, notice: 'Course was successfully deleted.'
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_course
      @course = Course.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to root_path, notice: 'Course not found!'
    end

    # Only allow a list of trusted parameters through.
    def course_params
      params.require(:course).permit(:course_id, :catalog_number, :course_name, :term, :campus, :credit_hour, :academic_career, :course_discription)
    end


end
