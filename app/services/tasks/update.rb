class Tasks::Update < Tasks::Base
  def call
    persist!
  end
end
