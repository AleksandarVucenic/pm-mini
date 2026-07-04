class Api::V1::ProjectsController < Api::V1::BaseController
  before_action :set_project, only: [ :show, :update, :destroy ]

  def index
    filtered = ProjectSearchQuery.new(relation: policy_scope(Project), term: params[:term]).call
    results = ProjectTaskCountsQuery.new(relation: filtered).call
    pagy, paginated_results = paginate(results)
    render json: ProjectSerializer.new(paginated_results, meta: pagination_meta(pagy)).serializable_hash
  end

  def show
    authorize @project
    result = ProjectTaskCountsQuery.new(relation: Project.where(id: @project.id)).call.first
    render json: ProjectSerializer.new(result).serializable_hash
  end

  def create
    project = current_user.managed_projects.build(project_params)
    authorize project
    project.save!
    render json: ProjectSerializer.new(project).serializable_hash, status: :created
  end

  def update
    authorize @project
    @project.update!(project_params)
    render json: ProjectSerializer.new(@project).serializable_hash
  end

  def destroy
    authorize @project
    @project.destroy!
    head :no_content
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name)
  end
end
