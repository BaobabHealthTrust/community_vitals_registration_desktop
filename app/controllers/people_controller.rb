class PeopleController < GenericPeopleController
  def report_menu
    
  end

  def community_report
    @logo = CoreService.get_global_property_value('logo') rescue nil
    @location_name = Location.current_health_center.name rescue nil
    start_year = params[:start_year]
    start_month = params[:start_month]
    start_day = params[:start_day]
    start_date = (start_year + '-' + start_month + '-' + start_day).to_date
    @start_date = start_date
    end_year = params[:end_year]
    end_month = params[:end_month]
    end_day = params[:end_day]
    end_date = (end_year + '-' + end_month + '-' + end_day).to_date
    @end_date = end_date
    user_person_ids = User.all.map(&:person_id)
    @total_registered = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND person_id NOT IN(?)",start_date,
        end_date, user_person_ids])

    @total_men_registered = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND gender =? AND person_id NOT IN(?)",start_date,
        end_date,'m', user_person_ids])

    @total_women_registered = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND gender =? AND person_id NOT IN(?)",start_date,
        end_date,'f', user_person_ids])

    @children = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND DATEDIFF(Now(),birthdate)/365 <= 9 AND person_id NOT IN(?)",
        start_date,end_date, user_person_ids])#children 0 to 9

    @adolescents = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND DATEDIFF(Now(),birthdate)/365 > 9
        AND DATEDIFF(Now(),birthdate)/365 <= 19 AND person_id NOT IN(?)",start_date,
        end_date, user_person_ids])#adolescents 10 to 19

    @adults = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND DATEDIFF(Now(),birthdate)/365 > 19
        AND DATEDIFF(Now(),birthdate)/365 <= 45 AND person_id NOT IN(?)",start_date,
        end_date, user_person_ids ])#adults 20 to 45

    @middle_age = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND DATEDIFF(Now(),birthdate)/365 > 45
        AND DATEDIFF(Now(),birthdate)/365 <= 60 AND person_id NOT IN(?)",start_date,
        end_date, user_person_ids ])#middle_age 46 to 60

    @elders = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND DATEDIFF(Now(),birthdate)/365 > 60 AND person_id NOT IN(?)",
        start_date,end_date, user_person_ids ])#elders > 60

   render:layout=>"menu"
  end

  def decompose_report
    @location_name = Location.current_health_center.name rescue nil
    person_ids = params[:ids]
   
    @people = {}
    if params[:ids]
      person_ids.each do |id|
        person = Person.find(id)
        @people[id] = {}
        @people[id][:first_name] = person.names[0].given_name
        @people[id][:last_name] = person.names[0].family_name
        @people[id][:birthdate] = person.birthdate
        @people[id][:date_created] = person.date_created
      end
    end
    render:layout => "menu" and return
  end

  def edit_demographics
    @patient = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]) rescue nil
    @field = params[:field]
    render :partial => "edit_demographics", :field =>@field, :layout => true and return
  end

  def update_demographics
    PatientService.update_demographics(params)
    redirect_to :action => 'demographics', :patient_id => params['person_id'] and return
  end

  def community_vitals_report
    @logo = CoreService.get_global_property_value('logo') rescue nil
    @location_name = Location.current_health_center.name rescue nil
    start_year = params[:start_year]
    start_month = params[:start_month]
    start_day = params[:start_day]
    start_date = (start_year + '-' + start_month + '-' + start_day).to_date
    @start_date = start_date
    end_year = params[:end_year]
    end_month = params[:end_month]
    end_day = params[:end_day]
    end_date = (end_year + '-' + end_month + '-' + end_day).to_date
    @end_date = end_date
    user_person_ids = User.all.map(&:person_id)

    total_registered_people = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND person_id NOT IN(?)",start_date,
        end_date, user_person_ids])
    @data = {}
    total_registered_people.each do |person|
      next if person.addresses.blank?
      county_district = person.addresses.last.county_district rescue 'unknown'
      city_village = person.addresses.last.city_village
      if (@data[county_district].blank?)
        @data[county_district] = {}
      end
      if (@data[county_district])
        if (@data[county_district][city_village].blank?)
          @data[county_district][city_village] = {}
        end
        if (@data[county_district][city_village])
          if (@data[county_district][city_village][:total_registered].blank?)
            @data[county_district][city_village][:total_registered] = {}
          end
          if (@data[county_district][city_village][:total_registered])
            if (@data[county_district][city_village][:total_registered][:males].blank?)
              @data[county_district][city_village][:total_registered][:males] = 0
            end
            unless (@data[county_district][city_village][:total_registered][:males].blank?)
              @data[county_district][city_village][:total_registered][:males] +=1 if person.gender.upcase == 'M'
            end

            if (@data[county_district][city_village][:total_registered][:females].blank?)
              @data[county_district][city_village][:total_registered][:females] = 0
            end
            unless (@data[county_district][city_village][:total_registered][:females].blank?)
              @data[county_district][city_village][:total_registered][:females] +=1 if person.gender.upcase == 'F'
            end
            
          end
          
          if (@data[county_district][city_village][:total_birth].blank?)
            @data[county_district][city_village][:total_birth] = {}
          end
          if (@data[county_district][city_village][:total_birth])
            if (@data[county_district][city_village][:total_birth][:males].blank?)
              @data[county_district][city_village][:total_birth][:males] = 0
            end
            unless (@data[county_district][city_village][:total_birth][:males].blank?)
              if (person.birthdate >=start_date && person.birthdate <= end_date)
                @data[county_district][city_village][:total_birth][:males] +=1 if person.gender.upcase == 'M'
              end
            end

            if (@data[county_district][city_village][:total_birth][:females].blank?)
              @data[county_district][city_village][:total_birth][:females] = 0
            end
            unless (@data[county_district][city_village][:total_birth][:females].blank?)
              if (person.birthdate >=start_date && person.birthdate <= end_date)
                @data[county_district][city_village][:total_birth][:females] +=1 if person.gender.upcase == 'F'
              end
            end

          end

          #****************
          if (@data[county_district][city_village][:total_died].blank?)
            @data[county_district][city_village][:total_died] = {}
          end
          if (@data[county_district][city_village][:total_died])
            if (@data[county_district][city_village][:total_died][:males].blank?)
              @data[county_district][city_village][:total_died][:males] = 0
            end
            unless (@data[county_district][city_village][:total_died][:males].blank?)
              if (person.dead == 1 && person.gender.upcase == 'M')
                @data[county_district][city_village][:total_died][:males] +=1
              end
            end

            if (@data[county_district][city_village][:total_died][:females].blank?)
              @data[county_district][city_village][:total_died][:females] = 0
            end
            unless (@data[county_district][city_village][:total_died][:females].blank?)
              if (person.dead == 1 && person.gender.upcase == 'F')
                @data[county_district][city_village][:total_died][:females] +=1
              end
            end

          end
        end
      end
    end
  end
  
end
