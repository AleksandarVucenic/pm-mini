class Api::V1::ProjectsController < Api::V1::BaseController
  before_action :set_project, only: [:show, :update, :destroy]

  def index
    projects = Project.includes(:pm)
    success(data: projects.map { |p| ProjectSerializer.call(p) })
  end

  def show
    success(data: ProjectSerializer.call(@project))
  end

  def create
    project = current_user.managed_projects.build(project_params)
    project.save!
    success(data: ProjectSerializer.call(project), message: "Project created successfully", status: :created)
  end

  def update
    @project.update!(project_params)
    success(data: ProjectSerializer.call(@project), message: "Project updated successfully")
  end

  def destroy
    @project.destroy!
    success(message: "Project deleted successfully")
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name)
  end
end
