require 'auction_house'
require 'utilities'
include WowArmory::AuctionHouse::Utilities

def setup
	# Initialise a usable AH object
	ah = WowArmory::AuctionHouse::Scanner.new("auctionboss.yml")
	
	# Attempt authentication
	if ah.login! then
		puts colorize("Logged in!", "1;32;40")
	elsif ah.needs_authenticator? then
		# We need to pass an authenticator code
		print colorize("Please enter the authenticator code for this account: ", "1;36;40")
		if ah.authenticate!(gets.chomp) then
			puts colorize("Logged in!", "1;32;40")
		end
	else
		puts colorize("Invalid credentials or Armory not available", "1;31;40")
	end
	ah
end

ah = setup
while true do
	# Loop through all our predefined queries
	ah.db["queries"].find().each do |row|
		# Retrieve the results for each query in turn
		auctions = ah.search(row)
		puts "Found #{colorize auctions.length, "1;33;40"} auctions\t- #{colorize(row["query"] || row.inspect, "1;37;40")}"

		# Insert each auction into the database
		auctions.each do |auction|
			# Set the date it was retrieved
			auction["date"] = Time.new
			
			# Update the record if the auction it exists already
			ah.db["auctions"].update({"auc" => auction["auc"]}, auction, {:upsert => true})
		end
		
		# Set first_seen on all auctions that we haven't seen before
		ah.db["auctions"].update({:first_seen => {:$exists => false}}, {:$set => {:first_seen => Time.new}}, {:multi => true})
	end
	puts colorize(":: Scan finished ::", "1;32;40")
	
	# Sleep an arbitrary time before running another scan
	sleep(60)
end