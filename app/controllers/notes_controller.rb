class NotesController < ApplicationController
  before_action :set_note, only: [:update, :destroy]
  before_action :authenticate_param_id!, only: [:update, :destroy]
  before_action :authenticate_param_user_id!, only: [:create]
  skip_before_action :authenticate_user!, only: [:index, :count]

  def index
    track_note if params["user_ids"] && params["user_ids"].is_a?(Array) && params["user_ids"].size == 1
    notes = Note
    notes = notes.where(id: params["ids"]) if params["ids"].present? && params["ids"].is_a?(Array)
    notes = notes.where(user_id: params["user_ids"]) if params["user_ids"].present? && params["user_ids"].is_a?(Array)
    notes = notes.where(ancestry: params["ancestry"]&.empty? ? nil : params["ancestry"]) if params.include?("ancestry")
    notes = notes.where(slug: params["slug"]) if params["slug"]
    notes = notes.where(content: params["content"]) if params["content"]

    if params["content_like"]
      notes = notes.where("lower(content) like ?", params['content_like'].downcase)
    end
    if params["except_ids"].present?
      notes = notes.where.not(id: params["except_ids"])
    end
    if params["id_lte"].present?
      notes = notes.where("notes.id <= ?", params["id_lte"])
    end
    if params["id_gte"].present?
      notes = notes.where("notes.id >= ?", params["id_gte"])
    end
    if params["except_slug"].present?
      notes = notes.where.not(slug: params["except_slug"])
    end
    if params["skip_if_no_descendants"]
      notes = notes.joins("inner join notes as t on t.ancestry = cast(notes.id as VARCHAR(255)) and t.position=1 and t.content != ''")
    end
    limit = params["limit"] ? [params["limit"].to_i, 100].min : 100
    limit = 1 if params["slug"] || (params["ids"] && params["ids"].size == 1)
    notes = notes.order(id: :desc).limit(limit)
    methods = []
    methods << :descendants if params[:include_descendants]
    methods << :ancestors if params[:include_ancestors]
    methods << :user if params[:include_user]
    render json: notes.to_json(methods: methods), status: :ok
  end

  def count
    if params['url'].present?
      url = params['url'].downcase
      # We count all non-root notes (ancestry != nil):
      count1 = Note.
        where("lower(content) like ?", "%#{url}%").
        where("ancestry is not null").limit(10).count
      # We also count root notes with a first child where content is not empty:
      count2 = Note.
        joins("inner join notes as t on t.ancestry = cast(notes.id as VARCHAR(255)) and t.position=1 and t.content != ''").
        where("notes.ancestry is null").
        where("lower(notes.content) like ?", "%#{url}%").limit(10).count
      count = [count1 + count2, 10].min
    else
      count = 0
    end
    render json: count, status: :ok
  end

  def show
    notes = Note
    notes = notes.where(id: params[:id]) if params[:id]
    notes = notes.where(slug: params[:slug].downcase) if params[:slug]
    note = notes.first

    if params[:include_descendants]
      render json: note.to_json(methods: :descendants)
    else
      render json: note
    end
  end

  def create
    args = params.require(:note).permit(:content, :ancestry, :position, :slug).merge(user_id: current_user.id)
    note = Note.new(args)
    if note.save
      track_action("Create note", note_id: note.id)
      methods = []
      methods << :descendants if params[:include_descendants]
      methods << :ancestors if params[:include_ancestors]
      methods << :user if params[:include_user]
      render json: note.to_json(methods: methods), status: :created
    else
      render json: note.errors.full_messages, status: :bad_request
    end
  end

  def update
    updator = NoteUpdator.new(@note, params[:update_notes_with_links])
    if updator.update(params.require(:note).permit(:content, :ancestry, :position, :slug))
      track_action("Update note", note_id: @note.id)
      render json: @note, status: :ok
    else
      render json: @note.errors.full_messages, status: :not_modified
    end
  end

  def destroy
    destroyer = NoteDeleter.new(@note, include_descendants: true)
    if destroyer.delete
      track_action("Delete note")
      render json: @note, status: :ok
    else
      Rails.logger.error("Error deleting note #{@note.inspect} - params: #{params.inspect}")
      render json: { errors: "Couldn't delete note or descendants" }, status: :not_modified
    end
  end

  private

  def track_note
    id = params["user_ids"].first
    blogger = User.find_by(id: id)
    if params["slug"]
      track_action("Get note", { blog_username: blogger.username, note_slug: params['slug'], blogger_id: blogger.id })
    else
      track_action("Get user notes", { blog_username: blogger.username, blogger_id: blogger.id })
    end
  end

  def set_note
    @note = Note.find(params[:id])
  end

  def authenticate_param_id!
    head :unauthorized if current_user.id != @note.user_id
  end

  def authenticate_param_user_id!
    head :unauthorized if !params[:note] || current_user.id.to_s != params[:note][:user_id].to_s
  end
end
