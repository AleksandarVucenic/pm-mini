class Api::V1::TasksController < Api::V1::BaseController
  before_action :set_task, only: [ :show, :update, :destroy ]

  def index
    scope = TaskQuery.new(relation: policy_scope(Task), params: params).call
    pagy, tasks = paginate(scope)
    render json: TaskSerializer.new(tasks, meta: pagination_meta(pagy)).serializable_hash
  end

  def show
    authorize @task
    render json: TaskSerializer.new(@task).serializable_hash
  end

  def create
    task = Task.new(task_params)
    authorize task
    task.save!
    render json: TaskSerializer.new(task).serializable_hash, status: :created
  end

  def update
    authorize @task
    @task.update!(task_params)
    render json: TaskSerializer.new(@task).serializable_hash
  end

  def destroy
    authorize @task
    @task.destroy!
    head :no_content
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :project_id, :assignee_id)
  end
end
