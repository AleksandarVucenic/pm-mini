class Tasks::Create < Tasks::Base
  def call
    persist!
  end
end
