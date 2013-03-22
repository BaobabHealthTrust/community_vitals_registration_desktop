class GenericRelationshipsController < ApplicationController
  before_filter :find_patient, :except => [:void]
  
  def new
    #raise'new'
    render :layout => 'application'
    # render :template => 'dashboards/relationships_dashboard', :layout => false
  end

  def search
    session[:return_to] = nil
    session[:return_to] = params[:return_to] unless params[:return_to].blank?
    session[:guardian_added] = nil
    session[:guardian_added] = params[:guardian_added] unless params[:guardian_added].blank?
    render :layout => 'relationships'
  end

  def create
    relationship_id = params[:relationship].to_i rescue nil
    if relationship_id == RelationshipType.find_by_b_is_to_a('TB Index Person').id
      person_id = params[:person].to_i
      if person_id == 0 #if the person does not exist in db
        person = PatientService.create_from_form({'names' => 
                                           {'family_name' => params[:family_name],
                                            'given_name' => params[:given_name]
                                         },'gender' => params[:gender]
                                        } 
                                        )

        person_id = person.id
      end
      @relationship = Relationship.new(
        :person_a => @patient.patient_id,
        :person_b => params[:relation],
        :relationship => params[:relationship])
      if @relationship.save
        redirect_to session[:return_to] and return unless session[:return_to].blank?
        redirect_to :controller => :patients, :action => :guardians_dashboard, :patient_id => @patient.patient_id
      else
        render :action => "new"
      end

    else

      relationship_type = RelationshipType.find_by_relationship_type_id(params[:relationship]).a_is_to_b
      relationship_a_id = RelationshipType.find_by_a_is_to_b(relationship_type).id
      relationship_b_id = RelationshipType.find_by_b_is_to_a(relationship_type).id

      @relationship = Relationship.new(
        :person_a => @patient.patient_id,
        :person_b => params[:relation],
        :relationship => relationship_a_id)
      if @relationship.save
            @reverse_relationship = Relationship.new(
            :person_a =>  params[:relation] ,
            :person_b => @patient.patient_id,
            :relationship => relationship_b_id)

             if  @reverse_relationship.save
               redirect_to session[:return_to] and return unless session[:return_to].blank?
               redirect_to :controller => :patients, :action => :guardians_dashboard, :patient_id => @patient.patient_id
             else
                render :action => "new"
             end
      else 
           render :action => "new"
      end
   end
  end

  def void
    @relationship = Relationship.find(params[:id])
    @relationship_a = Relationship.find_by_person_a_and_person_b(@relationship.person_a,@relationship.person_b)
    @relationship_b = Relationship.find_by_person_b_and_person_a(@relationship.person_a,@relationship.person_b)
    @relationship_a.void unless @relationship_a.blank?
    @relationship_b.void unless @relationship_b.blank?
    head :ok
  end  
end
