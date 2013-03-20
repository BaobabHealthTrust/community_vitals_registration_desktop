class PeopleController < GenericPeopleController
  def report_menu
    
  end

  def community_report
    @logo = CoreService.get_global_property_value('logo') rescue nil
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
    @total_registered = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ?",start_date,end_date ])

    @total_men_registered = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND gender =?",start_date,end_date,'m' ])

    @total_women_registered = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND gender =?",start_date,end_date,'f' ])

    @children = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND DATEDIFF(Now(),birthdate)/365 >= 0
 AND DATEDIFF(Now(),birthdate)/365 <= 9",start_date,end_date ])#children 0 to 9

    @adolescents = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND DATEDIFF(Now(),birthdate)/365 >= 10
 AND DATEDIFF(Now(),birthdate)/365 <= 19",start_date,end_date ])#adolescents 10 to 19

    @adults = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND DATEDIFF(Now(),birthdate)/365 >= 20
 AND DATEDIFF(Now(),birthdate)/365 <= 45",start_date,end_date ])#adults 20 to 45

    @middle_age = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND DATEDIFF(Now(),birthdate)/365 >= 46
 AND DATEDIFF(Now(),birthdate)/365 <= 60",start_date,end_date ])#middle_age 46 to 60

    @elders = Person.find(:all, :conditions => ["DATE(date_created) >= ? AND
        DATE(date_created) <= ? AND DATEDIFF(Now(),birthdate)/365 > 60",
        start_date,end_date ])#elders > 60

   render:layout=>"menu"
  end

  def decompose_report
    person_ids = params[:ids]
    @people = {}
    person_ids.each do |id|
      person = Person.find(id)
      @people[id] = {}
      @people[id][:first_name] = person.names[0].given_name
      @people[id][:last_name] = person.names[0].family_name
      @people[id][:birthdate] = person.birthdate
      @people[id][:date_created] = person.date_created
    end
    render:layout => "menu"
  end
end
 
