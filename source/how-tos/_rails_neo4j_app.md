In this how-to I want to describe how to create a simple rails app using neo4j for the same use cases as in the [sinatra app](/how-tos/sinatra_neo4j_app/).
You can find the running demo [here](https://rails-neo4j-demo.herokuapp.com/).
[Doctor Finder gist](http://gist.neo4j.org/?8748719) served as example for this application.

### Create Rails app
Let's start by installing Rails and creating the Rails app.
Run this commands from your project directory.

~~~
gem install rails
~~~

Since the application won't use Active Record we can pass the `--skip-active-record` option.

~~~
rails new . --skip-active-record
~~~

Than add neo4j and haml gems to your `Gemfile`. We will use HAML later as a template engine.

**Gemfile**

~~~ruby
gem 'neo4j', '~> 4.1.0'
gem 'haml'
~~~

### Setup neo4j
To make the rake tasks defined in the `neo4j` gem available to rails add this line into the `application.rb`.

**config/application.rb**

~~~ruby
require "neo4j/railtie"
~~~

After that you should be able to install Neo4j database and to start the Neo4j server.

~~~
rake neo4j:install[community-2.1.6]
rake neo4j:start
~~~

### Setup database
The Neo4j server binds on port 7474 by default. So, let's configure the connection to the server in the development environment.

**config/environments/development.rb**

~~~ruby
  config.neo4j.session_type = :server_db
  config.neo4j.session_path = 'http://localhost:7474'
~~~

### Setup models
Please look into the [neo4j gist](http://gist.neo4j.org/?8748719) to understand the data model for this application.
This gist counts 7 models. So, let's define the models like this.

~~~ruby
class Pathology
  include Neo4j::ActiveNode

  property :name
  has_many :in, :drug_classes, type: :cures
end
~~~

Neo4j gem by default generates UUID's for each node but we will use simple integer ids. That's why I created a
module which we can include in the models to make them work with integer ids.

**models/concerns/integer_id.rb**

~~~ruby
module IntegerId
  def self.included(base)
    base.class_eval do
      id_property :id, on: :generate_id

      def generate_id
        self.class.order(id: :desc).first.try(:id).to_i + 1
      end
    end
  end
end
~~~

~~~ruby
class Drug
  include Neo4j::ActiveNode
  include IntegerId

  property :name
end
~~~

This id generation isn't concurrency-safe but it's enough for our simple demo.

Luckily there is a query in the [neo4j gist](http://gist.neo4j.org/?8748719) that we can use to populate the database.
I modified it a little so the Node labels in the database match model class names. Let's make a seeds file where this query is executed.

**db/seeds.rb**

~~~ruby
query_string = <<query
  create
  (_6:DrugClass  {id: 1, name:"Bronchodilators"}),
  (_7:DrugClass  {id: 2, name:"Corticosteroids"}),
  (_8:DrugClass  {id: 3, name:"Xanthine"}),
  (_9:Drug   {id: 1, name:"Salbutamol"}),
  (_10:Drug  {id: 2, name:"Terbutaline"}),
  (_11:Drug  {id: 3, name:"Bambuterol"}),
  (_12:Drug  {id: 4, name:"Formoterol"}),
  (_13:Drug  {id: 5, name:"Salmeterol"}),
  (_14:Drug  {id: 6, name:"Beclometasone"}),
  (_15:Drug  {id: 7, name:"Budesonide"}),
  (_16:Drug  {id: 8, name:"Ciclesonide"}),
  (_17:Drug  {id: 9, name:"Fluticasone"}),
  (_18:Drug  {id: 10, name:"Mometasone"}),
  (_19:Drug  {id: 11, name:"Betametasone"}),
  (_20:Drug  {id: 12, name:"Prednisolone"}),
  (_21:Drug  {id: 13, name:"Dilatrane"}),
  (_22:Allergy  {id: 1, name:"Hypersensitivity to Betametasone"}),
  (_23:Pathology  {id: 1, name:"Asthma"}),
  (_24:Symptom  {id: 1, name:"Wheezing"}),
  (_25:Symptom  {id: 2, name:"Chest tightness"}),
  (_26:Symptom  {id: 3, name:"Cough"}),
  (_27:Doctor  {id: 1, latitude:48.8573,longitude:2.35685,name:"Irving Matrix"}),
  (_28:Doctor  {id: 2, latitude:46.83144,longitude:-71.28454,name:"Jack McKee"}),
  (_29:Doctor  {id: 3, latitude:48.86982,longitude:2.32503,name:"Michaela Quinn"}),
  (_30:DoctorSpecialization  {id: 1, name:"Physician"}),
  (_31:DoctorSpecialization  {id: 2, name:"Angiologist"}),
  _6-[:cures {age_max:60,age_min:18,indication:"Adult asthma"}]->_23,
  _7-[:cures {age_max:18,age_min:5,indication:"Child asthma"}]->_23,
  _8-[:cures {age_max:60,age_min:18,indication:"Adult asthma"}]->_23,
  _9-[:belongs_to_class]->_6,
  _10-[:belongs_to_class]->_6,
  _11-[:belongs_to_class]->_6,
  _12-[:belongs_to_class]->_6,
  _13-[:belongs_to_class]->_6,
  _14-[:belongs_to_class]->_7,
  _15-[:belongs_to_class]->_7,
  _16-[:belongs_to_class]->_7,
  _17-[:belongs_to_class]->_7,
  _18-[:belongs_to_class]->_7,
  _19-[:belongs_to_class]->_6,
  _19-[:belongs_to_class]->_7,
  _19-[:may_cause_allergy]->_22,
  _20-[:belongs_to_class]->_7,
  _21-[:belongs_to_class]->_8,
  _23-[:may_manifest_symptoms]->_24,
  _23-[:may_manifest_symptoms]->_25,
  _23-[:may_manifest_symptoms]->_26,
  _27-[:specializes_in]->_31,
  _28-[:specializes_in]->_31,
  _29-[:specializes_in]->_30,
  _30-[:can_prescribe]->_7,
  _31-[:can_prescribe]->_6
query

Neo4j::Session.current.query(query_string)
~~~

Since Active Record is excluded from the application `db:seed` task is no longer available. That's why I created a rake file with a couple of tasks.

**lib/db.rake**

~~~ruby
namespace :db do
  task seed: :environment do
    seed_file = File.join('db/seeds.rb')
    load(seed_file) if File.exist?(seed_file)
  end

  task clear: :environment do
    Neo4j::Session.current.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
  end
end
~~~

After running `rake db:seed` the query from the seeds file will populate the database.

### Use cases
There are 2 use cases in the [neo4 gist](http://gist.neo4j.org/?8748719):
* user should be able to find drugs by symptoms, age, and allergies
* user should be able to find doctors by symptoms, age, and allergies and get the distance to them

Now let's create 2 classes: DrugAdvisor and DoctorAdvisor. They will be responsible for finding drugs and doctors in the database.
We put the queries from [neo4j gist](http://gist.neo4j.org/?8748719) with some changes into this classes.

**app/advisors/drug_advisor.rb**

~~~ruby
class DrugAdvisor
  def find(symptom_names, age, allergy_names = [])
    find_query(symptom_names, age, allergy_names).pluck('DISTINCT(drug)')
  end

  def find_query(symptom_names, age, allergy_names = [])
    Symptom.all.where(name: symptom_names).
      pathologies.
      drug_classes(:drug_class, :cures).where('cures.age_min <= {age} AND {age} < cures.age_max').
      params(age: age).
      drugs.query_as(:drug).
        match(allergy: :Allergy).
        where('(NOT (drug)-[:may_cause_allergy]->(allergy) OR NOT(allergy.name IN {allergy_names}))').
        params(age: age, allergy_names: allergy_names)
  end
end
~~~

**app/advisors/doctor_advisor.rb**

~~~ruby
class DoctorAdvisor
  def find(symptom_names, age, allergy_names = [], latitude = nil, longitude = nil)
    DrugAdvisor.new.find_query(symptom_names, age, allergy_names).
      match('(doctor:Doctor)-->(:DoctorSpecialization)-[:can_prescribe]->(drug_class)').
      return('DISTINCT(doctor) AS doctor',
             '2 * 6371 * asin(sqrt(haversin(radians({lat} - COALESCE(doctor.latitude,{lat}))) + cos(radians({lat})) * cos(radians(COALESCE(doctor.latitude,90)))* haversin(radians({long} - COALESCE(doctor.longitude,{long}))))) AS distance').
      params(lat: latitude, long: longitude).
      order('distance ASC').
      each_with_object({}) do |result, hash|
        hash[result.doctor] = result.distance
      end
  end
end
~~~

### Routes and controllers
The application can find drugs and doctors so far, but it doesn't handle network requests yet.
Add this routes into `routes.rb` in order to map `/`, `/drugs` and `/doctors` to `HomeController`, `DrugsController` and `DoctorsController`.

**config/routes.rb**

~~~ruby
resources :drugs,   only: :index
resources :doctors, only: :index
root to: 'home#index'
~~~

The `/` route should just render an html page with the form where user can input data and see results.
The `/drugs` route should return an array with drug names and the `/doctors` route should return a hash with doctor names and distances as json.

**app/controllers/application_controller.rb**

~~~ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def symptoms
    params[:symptoms] || []
  end

  def allergies
    params[:allergies] || []
  end

  def age
    params[:age].to_i
  end

  def latitude
    params[:latitude].to_f
  end

  def longitude
    params[:longitude].to_f
  end
end

~~~

**app/controllers/home_controller.rb**

~~~ruby
class HomeController < ApplicationController
  def index
    @symptoms  = Symptom.all
    @allergies = Allergy.all
  end
end
~~~

**app/controllers/drugs_controller.rb**

~~~ruby
class DrugsController < ApplicationController
  def index
    @drugs = DrugAdvisor.new.find(symptoms, age, allergies)
    render json: @drugs.map(&:name)
  end
end
~~~

**app/controllers/doctors_controller.rb**

~~~ruby
class DoctorsController < ApplicationController
  def index
    results = DoctorAdvisor.new.find(symptoms, age, allergies, latitude, longitude)
    @doctors = results.inject({}) do |hash, pair|
      doctor, distance = pair
      hash.merge!(doctor.name => distance.round(2))
    end
    render json: @doctors
  end
end
~~~

### Views and assets
There is only one page in this application, but we split it into layout and an index page to make it more readable.

**app/views/layouts/application.html.haml**

~~~haml
%html
  %head
    %meta(charset='utf-8')
    %meta(http-equiv='X-UA-Compatible' content='IE=Edge,chrome=1')
    %meta(name='viewport' content='initial-scale=1.0')
    %title Rails Demo App. Doctor Finder
    = stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track' => true
    = javascript_include_tag 'application', 'data-turbolinks-track' => true
  %body
    %header
    = yield
~~~

**app/views/home/index.html.haml**

~~~haml
.advisors.container
  .advisor.panel.panel-default
    .panel-heading Find drugs and doctors
    .panel-body
      %p
        Please enter age, symptoms and allergies(optional) to find drugs and doctors
      %form.form-horizontal
        .form-group
          %label.col-sm-2.control-label.required Age
          .col-sm-10
            %input.age.form-control(placeholder='Your age' type='text')/
        .form-group
          %label.col-sm-2.control-label.required Symptoms
          .col-sm-10
            %select.symptoms(multiple)
              - @symptoms.each do |symptom|
                %option{name: symptom.name, value: symptom.name}= symptom.name
        .form-group
          %label.col-sm-2.control-label Allergies
          .col-sm-10
            %select.allergies(multiple)
              - @allergies.each do |allergy|
                %option{name: allergy.name, value: allergy.name}= allergy.name
      %hr
      .suggestion
        .col-sm-6
          Drugs
          %ul.drugs.list-group

        .col-sm-6
          Doctors
          %ul.doctors.list-group
~~~

All we have to do now is to send ajax requests to the server to find drugs and doctors and insert the returned data into the page when user changes inputs.
Here is the javascript which will request coordinates from the browser, create nice dropdowns using bootstrap-multiselect and update drug and doctor lists upon changing the form inputs:

**app/assets/javascripts/application.js**

~~~javascript
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .

window.onload = function(){
    if(navigator.geolocation) navigator.geolocation.getCurrentPosition(handleGetCurrentPosition);
};

function handleGetCurrentPosition(location){
    window.latitude     = location.coords.latitude;
    window.longitude    = location.coords.longitude;
}

$(document).ready(function(){
    var adviseDrug = function(symptoms, age, allergies){
        $.getJSON('/drugs', {"symptoms": symptoms, "allergies": allergies, age: age, latitude: window.latitude, longitude: window.longitude}).done(function(json){
            $(".suggestion .drugs").empty();
            $.each(json, function(key, value){
                $(".suggestion .drugs").append('<li class="list-group-item">' + value + '</li>');
            });
        });
    };

    var adviseDoctor = function(symptoms, age, allergies){
        $.getJSON('/doctors', {"symptoms": symptoms, "allergies": allergies, age: age, latitude: window.latitude, longitude: window.longitude}).done(function(json){
            $(".suggestion .doctors").empty();
            $.each(json, function(key, value){
                $(".suggestion .doctors").append('<li class="list-group-item"><span class="badge">' + value + ' km</span>' + key + '</li>');
            });
        });
    };

    var updateSuggestions = function(element){
        var advisor     = $(element).parents('.advisor');
        var symptoms    = advisor.find('.symptoms').val();
        var allergies   = advisor.find('.allergies').val();
        var age         = advisor.find('.age').val();
        adviseDrug(symptoms, age, allergies);
        adviseDoctor(symptoms, age, allergies);
    };

    var multiselectOptions = {
        numberDisplayed: 5,
        buttonWidth: '400px',
        onChange: function(option, checked, select) {
            updateSuggestions(option);
        }
    };

    $('.advisor select.symptoms').multiselect($.extend({}, multiselectOptions, {
        nonSelectedText: 'Select symptoms'
    }));

    $('.advisor select.allergies').multiselect($.extend({}, multiselectOptions, {
        nonSelectedText: 'Select allergies'
    }));

    $('.advisor input.age').blur(function(){
        updateSuggestions(this);
    });

    $('.advisor input.age').keypress(function(e) {
        if(e.which == 13) {
            updateSuggestions(this);
            e.preventDefault();
        }
    });
});
~~~
