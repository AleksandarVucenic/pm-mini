class ProjectSearchQuery
  def initialize(relation: Project.all, term: nil)
    @relation = relation
    @term = term
  end

  def call
    return relation unless term.present?

    relation.where("projects.name LIKE :term", term: "%#{term}%")
  end

  private

  attr_reader :relation, :term
end
