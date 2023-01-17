class TasksController < ApplicationController
  before_action :set_task, only: %i[ show edit update destroy ]
  CALENDAR_ID = 'primary'
  # GET /tasks or /tasks.json
  def index
    @tasks = Task.all
  end

  # GET /tasks/1 or /tasks/1.json
  def show
  end

  # GET /tasks/new
  def new
    @task = Task.new
  end

  # GET /tasks/1/edit
  def edit
  end

  # POST /tasks or /tasks.json
  def create
    client = get_google_calendar_client
    task = params[:task]
    event = get_event task
    ge = client.insert_event('primary', event)
    
    flash[:notice] = 'Task was successfully added.'
    redirect_to tasks_path
  end

  def get_google_calendar_client
    client = Google::Apis::CalendarV3::CalendarService.new
    return unless current_user.present? && current_user.oauth_token.present? && current_user.refresh_token.present?

    secrets = Google::APIClient::ClientSecrets.new({
                                                     'web' => {
                                                       'access_token' => current_user.oauth_token,
                                                       'refresh_token' => current_user.refresh_token,
                                                       'client_id' => ENV['GOOGLE_CLIENT_ID'],
                                                       'client_secret' => ENV['GOOGLE_SECRET']
                                                     }
                                                   })
    
    begin
      client.authorization = secrets.to_authorization
      client.authorization.grant_type = 'refresh_token'

      if current_user.expired?
        client.authorization.refresh!

        current_user.update(
          oauth_token: client.authorization.access_token,
          refresh_token: client.authorization.refresh_token,
          oauth_expires_at: Time.at(auth.credentials.expires_at)
        )
      end
    rescue StandardError => e
      puts e.message
    end
    client
  end

  # PATCH/PUT /tasks/1 or /tasks/1.json
  def update
    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to task_url(@task), notice: "Task was successfully updated." }
        format.json { render :show, status: :ok, location: @task }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1 or /tasks/1.json
  def destroy
    @task.destroy

    respond_to do |format|
      format.html { redirect_to tasks_url, notice: "Task was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_task
      @task = Task.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def task_params
      params.require(:task).permit(:title, :description, :start_date, :end_date, :event, :members)
    end

    def get_event task

      attendees = task[:members].split(',').map{ |t| {email: t.strip} }
      event = {
        summary: task[:title],
        description: task[:description],
        start: {
          date_time: task[:start_date].to_datetime.to_s,
          time_zone: 'Asia/Tokyo', 
        },
        end:  {
          date_time: task[:end_date].to_datetime.to_s,
          time_zone: 'Asia/Tokyo', 
        },
        sendNotifications: true,
        attendees: attendees,
        reminders: {
          use_default: true
        }
      }
      event
    end
end
