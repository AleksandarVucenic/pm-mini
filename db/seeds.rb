# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
crew = [
  { name: "James Kirk", email: "kirk@enterprise.com" },
  { name: "Spock", email: "spock@enterprise.com" },
  { name: "Montgomery Scott", email: "scotty@enterprise.com" },
  { name: "Nyota Uhura", email: "uhura@enterprise.com" },
  { name: "Leonard McCoy", email: "mccoy@enterprise.com" },
  { name: "Hikaru Sulu", email: "sulu@enterprise.com" },
  { name: "Pavel Chekov", email: "chekov@enterprise.com" }
]

crew.each do |member|
  User.find_or_create_by!(email: member[:email]) do |user|
    user.name = member[:name]
    user.password = "starfleet123"
  end
end

puts "Seeded #{User.count} users."