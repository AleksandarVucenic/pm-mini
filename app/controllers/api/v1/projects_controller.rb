class Api::V1::ProjectsController < Api::V1::BaseController
  before_action :set_project, only: [ :show, :update, :destroy ]

  def index
    filtered = ProjectSearchQuery.new(relation: policy_scope(Project), term: params[:term]).call
    pagy, paginated_projects = paginate(filtered)
    results = ProjectTaskCountsQuery.new(relation: paginated_projects).call
    render json: ProjectSerializer.new(results, meta: pagination_meta(pagy), include: ["pm"]).serializable_hash
  end

  def show
    authorize @project
    render json: ProjectSerializer.new(ProjectTaskCountsQuery.for_project(@project), include: ["pm"]).serializable_hash
  end

  def create
    project = current_user.managed_projects.build(project_create_params)
    authorize project
    project.save!
    render json: ProjectSerializer.new(ProjectTaskCountsQuery.for_project(project), include: ["pm"]).serializable_hash, status: :created
  end

  def update
    authorize @project
    @project.update!(project_update_params)
    render json: ProjectSerializer.new(ProjectTaskCountsQuery.for_project(@project), include: ["pm"]).serializable_hash
  end

  def destroy
    authorize @project
    @project.destroy!
    head :no_content
  end

  private

  def set_project
    @project = policy_scope(Project).includes(:pm).find(params[:id])
  end

  def project_create_params
    params.require(:project).tap { |p| p.require(:name) }.permit(:name)
  end

  def project_update_params
    params.require(:project).permit(:name)
  end
end
