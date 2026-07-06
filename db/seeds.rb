crew = [
  { name: "James Kirk", email: "kirk@enterprise.com" },
  { name: "Spock", email: "spock@enterprise.com" },
  { name: "Montgomery Scott", email: "scotty@enterprise.com" },
  { name: "Nyota Uhura", email: "uhura@enterprise.com" },
  { name: "Leonard McCoy", email: "mccoy@enterprise.com" },
  { name: "Hikaru Sulu", email: "sulu@enterprise.com" },
  { name: "Pavel Chekov", email: "chekov@enterprise.com" }
]

users = crew.map do |member|
  User.find_or_create_by!(email: member[:email]) do |user|
    user.name = member[:name]
    user.password = "starfleet123"
  end
end

kirk, spock, scotty, uhura, mccoy, sulu, chekov = users

# Kirk is PM on "Enterprise Refit" — Spock and McCoy are assignee on tasks, Scotty is not connected at all
enterprise = Project.find_or_create_by!(name: "Enterprise Refit") { |p| p.pm = kirk }

Task.find_or_create_by!(title: "Repair warp core", project: enterprise) do |t|
  t.description = "Warp core is running at 60% efficiency"
  t.assignee = spock
  t.closed = false
end

Task.find_or_create_by!(title: "Calibrate shields", project: enterprise) do |t|
  t.assignee = spock
  t.closed = true
end

Task.find_or_create_by!(title: "Restock sickbay", project: enterprise) do |t|
  t.assignee = mccoy
  t.closed = false
end

Task.find_or_create_by!(title: "Unassigned maintenance task", project: enterprise) do |t|
  t.closed = false
end

# Scotty is PM on "Voyager Refit" — Kirk is assignee, not PM
voyager = Project.find_or_create_by!(name: "Voyager Refit") { |p| p.pm = scotty }

Task.find_or_create_by!(title: "Fix transporter buffer", project: voyager) do |t|
  t.assignee = kirk
  t.closed = false
end

Task.find_or_create_by!(title: "Update navigation charts", project: voyager) do |t|
  t.assignee = uhura
  t.closed = false
end

puts "Seeded #{User.count} users, #{Project.count} projects, #{Task.count} tasks."
puts ""
puts "Try logging in as:"
puts "  kirk@enterprise.com   (PM of Enterprise Refit, assignee on Voyager Refit)"
puts "  spock@enterprise.com  (assignee on Enterprise Refit, no role on Voyager)"
puts "  scotty@enterprise.com (PM of Voyager Refit, no tasks on Enterprise)"
puts "All passwords: starfleet123"
