class TasksController < ApplicationController
  require 'google/apis/calendar_v3'
  require 'google/api_client/client_secrets'

  before_action :set_task, only: %i[ show edit update destroy ]
  CALENDAR_ID = 'primary'
  # GET /tasks or /tasks.json
  def index
    @tasks = Task.all
    # client = get_google_calendar_client

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
    # Task.create!(task_params)
    @task = Task.new(task_params.merge(google_event_id: ge.id))
    @task.user = current_user
    @task.save!
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
          oauth_expires_at: Time.at(client.authorization.expires_at)
        )
      end
    rescue StandardError => e
      puts e.message
    end

    client
  end

  # PATCH/PUT /tasks/1 or /tasks/1.json
  def update

    client = get_google_calendar_client
    @events = current_user.tasks
    @events.each do |event|
      ge = event.get_google_event(@event.google_event_id, @event.user)
      guests = ge.attendees.map {|at| at.email}.join(", ")
      event.update(guest_list: guests)
    end
    g_event = client.get_event(Event::CALENDAR_ID, @task.google_event_id)
    task = params[:task]
    ge = get_event task
    # binding.pry
    client.update_event(Event::CALENDAR_ID, @task.google_event_id, ge)

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
    # @task.destroy
    client = get_google_calendar_client
    @tasks = current_user.tasks
    @tasks.each do |event|
      g_event = client.get_event(Event::CALENDAR_ID, event.google_event_id)
      guests = g_event.attendees.map {|at| at.email}.join(", ")
      event.update(members: guests, title: g_event.summary)
    end

    # client.delete_event(Event::CALENDAR_ID, @task.google_event_id)
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

      attendees = task[:members].split(',').map{ |t|  Google::Apis::CalendarV3::EventAttendee.new(
                                                    email: t.strip
                                                ) }
      # binding.pry
      # event = {
      #   summary: task[:title],
      #   description: task[:description],
      #   start: {
      #     date_time: task[:start_date].to_datetime.to_s,
      #     time_zone: 'Asia/Tokyo', 
      #   },
      #   end:  {
      #     date_time: task[:end_date].to_datetime.to_s,
      #     time_zone: 'Asia/Tokyo', 
      #   },
      #   sendNotifications: true,
      #   attendees: attendees,
      #   reminders: {
      #     use_default: true
      #   }
      # }
# binding.pry
      event = Google::Apis::CalendarV3::Event.new(
        summary: task[:title],
        location: '800 Howard St., San Francisco, CA 94103',
        description: task[:description],
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: task[:start_date].to_datetime.to_s.gsub('+00:00',''),
          time_zone: 'Asia/Ho_Chi_Minh'
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: task[:end_date].to_datetime.to_s.gsub('+00:00',''),
          time_zone: 'Asia/Ho_Chi_Minh'
        ),
        # recurrence: [
        #   'RRULE:FREQ=DAILY;COUNT=3'
        # ],
        attendees: attendees,
        sendNotifications: true,
        sendUpdates: 'all',
        reminders: Google::Apis::CalendarV3::Event::Reminders.new(
          use_default: true,
        )
      )
      # binding.pry
      event
    end
end
