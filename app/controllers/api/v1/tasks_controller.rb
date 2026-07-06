class Api::V1::TasksController < Api::V1::BaseController
  before_action :set_task, only: [ :show, :update, :destroy ]

  def index
    tasks = TaskQuery.new(relation: policy_scope(Task), params: params).call
    pagy, paginated = paginate(tasks)
    render json: TaskSerializer.new(paginated, meta: pagination_meta(pagy), include: [ "project.pm", "assignee" ]).serializable_hash
  end

  def show
    authorize @task
    render json: TaskSerializer.new(@task, include: [ "project.pm", "assignee" ]).serializable_hash
  end

  def create
    task = Task.new(task_params)
    authorize task
    Tasks::Create.new(task).call
    task = Task.includes(project: :pm, assignee: []).find(task.id)
    render json: TaskSerializer.new(task, include: [ "project.pm", "assignee" ]).serializable_hash, status: :created
  end

  def update
    authorize @task
    @task.assign_attributes(permitted_attributes(@task))
    Tasks::Update.new(@task).call
    render json: TaskSerializer.new(Task.includes(project: :pm, assignee: []).find(@task.id), include: [ "project.pm", "assignee" ]).serializable_hash
  end

  def destroy
    authorize @task
    @task.destroy!
    head :no_content
  end

  private

  def set_task
    @task = policy_scope(Task).includes(project: :pm, assignee: []).find(params[:id])
  end

  def task_params
    params.require(:task).tap { |p| p.require([ :title, :project_id ]) }
          .permit(:title, :description, :closed, :project_id, :assignee_id)
  end
end
