class AttendanceTracksController < ApplicationController
  before_action :set_attendance_track, only: [:destroy, :register_end_at, :edit, :update]
  before_action :authenticate_user!
  before_action :set_q, only: [:index, :search]
  authorize_resource

  # GET /attendance_tracks
  def index
    @attendance_tracks = @user_project.attendance_tracks.all
    @user_projects = current_user.user_projects.all
    @yearly_tracks = @attendance_tracks.group_by{|p| p.start_at_ja.year }
    if @yearly_tracks != nil && @yearly_tracks.length > 0
      @monthly_tracks = @yearly_tracks[Time.now.year].group_by{|p| p.start_at_ja.month }
    end
  end

  def search
    @results = @q.result
  end

  def new
    @user_project = UserProject.find(params[:user_project_id])
    @attendance_track = @user_project.attendance_tracks.new
  end

  def create
    @user_project = UserProject.find(params[:user_project_id])
    @attendance_track = @user_project.attendance_tracks.create(attendance_track_params)

    respond_to do |format|
      if @attendance_track.save
        flash[:success] = t('.success')
        format.html { redirect_to search_user_project_attendance_tracks_url(@user_project) }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end
  
  def edit
  end

  def update
    respond_to do |format|
      if @attendance_track.update(attendance_track_params)
        flash[:success] = t('.success')
        format.html { redirect_to user_project_attendance_tracks_url(@user_project) }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attendance_tracks/1
  def destroy
    @attendance_track.destroy

    respond_to do |format|
      flash[:success] = t('.success')
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  def top 
    @user_project = UserProject.find(params[:user_project_id])
    @user_projects = current_user.user_projects
    recentTrack = @user_project.attendance_tracks.last
    if recentTrack.nil? || recentTrack.end_at != nil
      @attendance_track = @user_project.attendance_tracks.new
    else
      @attendance_track = recentTrack
    end
  end

  # 開始時刻を記録する
  def register_start_at
    @user_project = UserProject.find(params[:user_project_id])
    # タイムゾーンを日本に統一したいのでTime.currentを使用
    # to_s(:db)を付けてUTCにして、DBに入る形と同じにしている　秒は保存されない
    @attendance_track = @user_project.attendance_tracks.new(start_at: Time.now.to_s(:db))

    respond_to do |format|
      if @attendance_track.save
        flash[:success] = t('.success')
        format.html { redirect_to top_user_project_attendance_tracks_url }
      else
        flash[:danger] = t('.failure')
        format.html { render :top, status: :unprocessable_entityS }
      end
    end
  end

  # 終了時刻を記録する
  def register_end_at
    respond_to do |format|
      if @attendance_track.update(end_at: Time.now.to_s(:db))
        flash[:success] = t('.success')
        format.html { redirect_to top_user_project_attendance_tracks_url}
      else
        flash[:danger] = t('.failure')
        format.html { render :top, status: :unprocessable_entity}
      end
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_attendance_track
      @user_project = UserProject.find(params[:user_project_id])
      @attendance_track = @user_project.attendance_tracks.find(params[:id])
    end

    def set_q
      @user_project = UserProject.find(params[:user_project_id])
      @q = @user_project.attendance_tracks.ransack(params[:q])
    end

    def attendance_track_params
      params.require(:attendance_track).permit(:start_at, :end_at)
    end

end
