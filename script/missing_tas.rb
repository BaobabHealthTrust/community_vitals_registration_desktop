require "fastercsv"
require 'yaml'

LOG_FILE = RAILS_ROOT + '/log/tas.log'


def read_config
  config = YAML.load_file("config/missing_tas.yml")
  @tas_to_import = (config["config"]["list_of_tas"]).split(",")
  @files_path = config["config"]["file_location"]
end

def initialize_variables

  print_time("initialization started")
  
  read_config

  print_time("Initialization ended")
end

def log(msg)
  system("echo \"#{msg}\" >> #{LOG_FILE}")
end

def print_time(message)
  @time = Time.now
  log "T/A insert-----#{message} at - #{@time} -----"
end

def insert_missing_ta
	missing = @tas_to_import
	#@dis = District.find_by_name("lilongwe city").id	
	missing.each do |current_ta|
	  district = current_ta.split(":")[0]
	  our_ta = current_ta.split(":")[1]
	  
	  dis = District.find_by_name(district).id  
	  
		current_root = @files_path + "/" + our_ta + '.csv'
		current_ta[0] = our_ta.first.capitalize[0]
		log "Searching for T.A : #{our_ta}"
		begin
			FasterCSV.foreach("#{current_root}", :quote_char => '"', :col_sep =>';', :row_sep =>:auto) do |row|
        @ta = TraditionalAuthority.first(:conditions  => ['district_id = ? and name = ?', dis, our_ta])
				if @ta.nil?
					ta = TraditionalAuthority.new
					ta.name = our_ta.titleize
					ta.district_id = dis
					ta.date_created = Time.now
					ta.creator = 1
					ta.save
					@ta = ta.id
					puts "Added new T.A : #{our_ta}"
				else
				  @ta = @ta.traditional_authority_id	
				end
				@chief = Village.first(:conditions  => ['traditional_authority_id = ? and name = ?', @ta,row[0]])
				if @chief.nil?
					ta = Village.new
					ta.name = row[0]
					ta.traditional_authority_id = @ta
					ta.date_created = Time.now
					ta.creator = 1
					ta.save
					log "Added new village : #{row[0]}"
				end
				
			end	
		rescue
			log "No such file : #{current_root} "
		end
	end
end

initialize_variables
insert_missing_ta
