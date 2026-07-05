class ProjectSearchQuery
  def initialize(relation: Project.all, term: nil)
    @relation = relation
    @term = term
  end

  def call
    return relation unless term.present?

    sanitized_term = ActiveRecord::Base.sanitize_sql_like(term)
    relation.where("projects.name LIKE :term", term: "%#{sanitized_term}%")
  end

  private

  attr_reader :relation, :term
end
