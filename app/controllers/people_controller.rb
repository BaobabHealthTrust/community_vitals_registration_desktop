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

  def demographics
    person = Patient.find(params[:patient_id]  || params[:id] || session[:patient_id]).person rescue nil
    @patient = person.patient
    @patient_bean = PatientService.get_patient(person)
    
    @national_id = @patient_bean.national_id_with_dashes rescue nil

    @first_name = @patient_bean.first_name rescue nil
    @last_name = @patient_bean.last_name rescue nil
    @birthdate = @patient_bean.birth_date rescue nil

    @gender = @patient_bean.sex rescue ''

    @current_village = @patient_bean.home_village rescue ''
    @current_ta = @patient_bean.traditional_authority rescue ''
    @current_district = @patient_bean.current_district rescue ''
    @home_district = @patient_bean.home_district rescue ''
    @landmark = @patient_bean.landmark rescue ''
    @primary_phone = @patient_bean.cell_phone_number rescue ''
    @secondary_phone = @patient_bean.home_phone_number rescue ''

    @occupation = @patient_bean.occupation rescue ''
    render :template => 'people/demographics', :layout => 'menu'

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


end
 
