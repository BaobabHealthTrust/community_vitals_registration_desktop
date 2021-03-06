class GenericLabController < ApplicationController
  def results
    @results = []
    @patient = Patient.find(params[:id])
    patient_ids = id_identifiers(@patient)
    @patient_bean = PatientService.get_patient(@patient.person)
    (Lab.results(@patient, patient_ids) || []).map do | short_name , test_name , range , value , test_date |
      @results << [short_name.gsub('_',' '),"/lab/view?test=#{short_name}&patient_id=#{@patient.id}"]
    end
    render :layout => 'menu'
  end

  def view
    @patient = Patient.find(params[:patient_id])
    @patient_bean = PatientService.get_patient(@patient.person)
    @test = params[:test]
    patient_ids = id_identifiers(@patient)
    @results = Lab.results_by_type(@patient, @test, patient_ids)

    @all = {}
    (@results || []).map do |key,values|
     date = key.split("::")[0].to_date rescue "1900-01-01".to_date
     name = key.split("::")[1].strip 
     value = values["TestValue"]
     next if date == "1900-01-01".to_date and value.blank?
     next if ((Date.today - 2.year) > date)
     @all[name] = [] if @all[name].blank?
     @all[name] << [date,value]
     @all[name] = @all[name].sort
    end

    @table_th = build_table(@results) unless @results.blank?
    render :layout => 'menu'
  end

  def build_table(results)
    available_dates = Array.new()
    available_test_types = Array.new()
    html_tag = Array.new()
    html_tag_to_display = nil

    results.each do | key , values |
      date = key.split("::")[0].to_date rescue 'Unknown'
      available_dates << date
      available_test_types << key.split("::")[1]
    end

    available_dates = available_dates.compact.uniq.sort.reverse rescue []
    available_test_types = available_test_types.compact.uniq rescue []
    return if available_dates.blank?


    #from the available test dates we create 
    #the top row which holds all the lab run test date  - quick hack :)
    @table_tr = "<tr><th>&nbsp;</th>" ; count = 0
    available_dates.map do | date |
      @table_tr += "<th id='#{count+=1}'>#{date}</th>"
    end ; @table_tr += "</tr>"

    #same here - we create all the row which will hold the actual 
    #lab results .. quick hack :)
    @table_tr_data = '' 
    available_test_types.map do | type |
      @table_tr_data += "<tr><td><a href = '#' onmousedown=\"graph('#{type}');\">#{type.gsub('_',' ')}</a></td>"
      count = 0
      available_dates.map do | date |
        @table_tr_data += "<td id = '#{type}_#{count+=1}' id='#{date}::#{type}'></td>"
      end
      @table_tr_data += "</tr>"
    end

    results.each do | key , values |
      value = values['Range'].to_s + ' ' + values['TestValue'].to_s
      @table_tr_data = @table_tr_data.sub(" id='#{key}'>"," class=#{}>#{value}")
    end


    return (@table_tr + @table_tr_data)
  end

  def graph
    @results = []
    params[:results].split(';').map do | result |
      date = result.split(',')[0].to_date rescue '1900-01-01'
      value = result.split(',')[1].sub('more_than','').sub('less_than','').sub('=','') rescue nil
      next if value.blank?
      value = value.to_f
      @results << [ date , value ]
    end 

    @patient = Patient.find(params[:patient_id])
    @patient_bean = PatientService.get_patient(@patient.person)
    @type = params[:type]
    @test = params[:test]
    render :layout => 'menu'
  end
  
  def id_identifiers(patient)
    identifier_type = ["Legacy Pediatric id","National id","Legacy National id"]
    identifier_types = PatientIdentifierType.find(:all,
      :conditions=>["name IN (?)",identifier_type]
    ).collect{| type |type.id }
    
    PatientIdentifier.find(:all,
      :conditions=>["patient_id=? AND identifier_type IN (?)",
        patient.id,identifier_types]).collect{| i | i.identifier }
  end
  
  def new
    @available_test = LabTestType.available_test                                
    @lab_test = ['']                                                          
    LabTestType.find(:all,                                                    
    :conditions =>["REPLACE(TestName,'_',' ') LIKE ?","%#{params[:name]}%"],  
    :order =>"TestName ASC").map{|test|                                       
      @lab_test << [test.TestName.gsub('_',' '),test.TestName]                
    }                                                                         
    @patient_id = params[:patient_id]                                                 
    @patient = Patient.find(params[:patient_id])
  end

  def create
    patient_bean = PatientService.get_patient(Person.find(params[:patient_id]))
    date = params[:test_date].to_date rescue "1900-01-01".to_date
    
    test_type = LabTestType.find(:first,
      :conditions =>["TestName = ?",params[:lab_result].to_s])

    test_modifier = params[:test_value].to_s.match(/=|>|</)[0]                  
    test_value = params[:test_value].to_s.gsub('>','').gsub('<','').gsub('=','')
    available_test_type = LabTestType.find(:all,:conditions=>["TestType IN (?)", test_type.TestType]).collect{|n|n.Panel_ID}
                                                                                
    lab_test_table = LabTestTable.new()                                         
    lab_test_table.TestOrdered = LabPanel.test_name(available_test_type)[0]     
    lab_test_table.Pat_ID = patient_bean.national_id                                 
    lab_test_table.OrderDate = date                                             
    lab_test_table.OrderTime = Time.now().strftime("%H:%M:%S")                  
    lab_test_table.OrderedBy = current_user.id                             
    lab_test_table.Location = Location.current_health_center.name
    lab_test_table.save                                                         
                                                                                
    # try                                                                       
    # lab_test_table.reload                                                     
    # sleep(1) while ltt.AccessionNum <= LabTestTable.last.AccessionNum         
    lab_test_table.reload                                                       
                                                                                
    lab_sample = LabSample.new()                                                
    lab_sample.AccessionNum = lab_test_table.AccessionNum                       
    lab_sample.USERID = current_user.id                                    
    lab_sample.TESTDATE = date                                                  
    lab_sample.PATIENTID = patient_bean.national_id                            
    lab_sample.DATE = date                                                      
    lab_sample.TIME = Time.now().strftime("%H:%M:%S")                           
    lab_sample.SOURCE = Location.current_location.id                            
    lab_sample.DeleteYN = 0                                                     
    lab_sample.Attribute = "pass"                                               
    lab_sample.TimeStamp = Time.now()                                           
    lab_sample.save                                                             
                                                                                
    lab_sample.reload                                                           
                                                                                
    lab_parameter = LabParameter.new()                                          
    lab_parameter.Sample_ID = lab_sample.Sample_ID                              
    lab_parameter.TESTTYPE =  test_type.TestType                                
    lab_parameter.TESTVALUE = test_value                                        
    lab_parameter.TimeStamp = Time.now()                                        
    lab_parameter.Range = test_modifier                                         
    lab_parameter.save


    redirect_to :action => "results" , :id => patient_bean.patient_id
  end

end
