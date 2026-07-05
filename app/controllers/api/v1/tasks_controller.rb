class Api::V1::TasksController < Api::V1::BaseController
  before_action :set_task, only: [ :show, :update, :destroy ]

  def index
    tasks = TaskQuery.new(relation: policy_scope(Task), params: params).call
    pagy, paginated = paginate(tasks)
    render json: TaskSerializer.new(paginated, meta: pagination_meta(pagy)).serializable_hash
  end

  def show
    authorize @task
    render json: TaskSerializer.new(@task).serializable_hash
  end

  def create
    task = Task.new(task_params)
    authorize task
    Tasks::Save.new(task).call
    render json: TaskSerializer.new(task).serializable_hash, status: :created
  end

  def update
    authorize @task
    @task.assign_attributes(permitted_attributes(@task))
    Tasks::Save.new(@task).call
    render json: TaskSerializer.new(@task).serializable_hash
  end

  def destroy
    authorize @task
    @task.destroy!
    head :no_content
  end

  private

  def set_task
    @task = Task.includes(:project, :assignee).find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :project_id, :assignee_id)
  end
end
