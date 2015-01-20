### Introduction

Sinatra is a simple web-framework written in Ruby. I've just created a simple Sinatra app to demonstrate how you could
use neo4j with sinatra. This [neo4j gist](http://gist.neo4j.org/?8748719) was chosen as a scenario for this application.
The [application(Doctor Finder)](https://sinatra-demo-app.herokuapp.com/) will find adequate drugs and doctors by symptoms.

I will describe how I created this app step by step.

### Setup Sinatra and Neo4j

#### Sinatra

At first create a Gemfile and add Sinatra, Neo4j and Haml to it:

**Gemfile**

~~~ruby
source 'https://rubygems.org'

gem 'sinatra'
gem 'neo4j', '~> 4.1.0'
gem 'haml'
~~~

The run `bundle` to install it.

Then we need a ruby script for our application. Let's call it `app.rb`. We have to require sinatra in this application
to be able to use sinatra's DSL:

**app.rb**

~~~ruby
require 'bundler'
Bundler.setup

require 'sinatra'
~~~

Let's also define some settings for sinatra, port 80 for the server in production environment and a template engine
[Haml](http://haml.info/) for our views.

**app.rb**

~~~ruby
set :haml, format: :html5
set :port, 80 if Sinatra::Base.environment == 'production'
~~~

#### Neo4j

We haven't setup the database yet. To connect the application with neo4j database require neo4j and create a new session:

**app.rb**

~~~ruby
require 'neo4j'

Neo4j::Session.open(:server_db, 'http://localhost:7474/')
~~~

It's also useful if we create model classes for all entities.

According to the database diagram from the [neo4j gist](http://gist.neo4j.org/?8748719) there are 7 models.

![data model](/images/800451GraphGist.png)

Creating a model is also pretty simple. For example:

**models/drug.rb**

~~~ruby
class Drug
  include Neo4j::ActiveNode

  property :name, index: :exact
end
~~~

Neo4j gem by default generates UUID's for each node but I wanted to use simple integer ids. That's why I created a
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

**models/drug.rb**

~~~ruby
class Drug
  include Neo4j::ActiveNode
  include IntegerId

  property :name, index: :exact
end
~~~

This id generation isn't concurrency-safe but it's enough for our simple demo.

In order to work with the models we must load them:

**app.rb**

~~~ruby
Dir["models/concerns/*.rb"].each do |concern|
  load concern
end

Dir["models/**/*.rb"].each do |model|
  load model
end
~~~

So, we set up the models but the database is empty.

Luckily there is a query in the [neo4j gist](http://gist.neo4j.org/?8748719) that we can use to populate the database.
I modified it a little so the Node labels in the database match model class names. Let's make a seeds file where this query is executed.

**db/seeds.rb**

~~~ruby
Neo4j::Session.current._query(<<query)
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
~~~

I also created rake tasks to seed the db and to clear it from command line:

**Rakefile**

~~~ruby
load 'neo4j/tasks/neo4j_server.rake'

namespace :db do
  task :seed do
    seed_file = File.join('db/seeds.rb')
    load(seed_file) if File.exist?(seed_file)
  end

  task :clear do
    Neo4j::Session.current.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
  end
end
~~~

The first line will also load some rake tasks from neo4j-core. But
these rake tasks still won't work because neo4j gem should be loaded before the definition just like we did it in the `app.rb`.
So lets extract environment initialization into `environment.rb` and require this file from `app.rb` and `Rakefile`.

**environment.rb**

~~~ruby
require 'bundler'
Bundler.setup
require 'neo4j'

Neo4j::Session.open(:server_db, 'http://localhost:7474/')

Dir["models/concerns/*.rb"].each do |concern|
  load concern
end

Dir["models/**/*.rb"].each do |model|
  load model
end
~~~

After running `rake db:seed` the database will be populated with some data.

### Routes and views

There will be 3 routes in the application:

~~~
/       - page with form
/drug   - should return found drugs
/doctor - should return found doctors and distances to them
~~~

Let's begin with the root route `/`. It should load all symptoms and allergies from the database and render a form with
one text field for age and two dropdowns with symptoms and allergies.

Addinionally we can split up the page into 2 views: `layout.haml` and `index.haml` to make it more readable.

**app.rb**

~~~ruby
get '/' do
  @symptoms  = Symptom.all
  @allergies = Allergy.all
  haml :index
end
~~~

**views/layout.haml**

~~~haml
%html
  %head
    %meta(charset='utf-8')
    %meta(http-equiv='X-UA-Compatible' content='IE=Edge,chrome=1')
    %meta(name='viewport' content='initial-scale=1.0')
    %title Sinatra Demo App. Doctor Finder
    %script(src='//code.jquery.com/jquery-1.11.2.min.js')
    %script(src='//code.jquery.com/jquery-migrate-1.2.1.min.js')
    %link(href='bootstrap.min.css' rel='stylesheet')/
    %link(href='bootstrap-theme.min.css' rel='stylesheet')/
    %script(src='bootstrap.min.js')
    %script(src='bootstrap-multiselect/bootstrap-multiselect.js' type='text/javascript')
    %link(href='bootstrap-multiselect/bootstrap-multiselect.css' rel='stylesheet' type='text/css')/
    %link(href='app.css' rel='stylesheet')/
    %script(src='app.js')
  %body
    %header
    = yield
~~~

**views/index.haml**

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

As you can see from `layout.haml` I added [Bootstrap](http://getbootstrap.com/) and [jQuery](http://jquery.com/)
frameworks together with [Bootstrap Multiselect](https://github.com/davidstutz/bootstrap-multiselect) library which makes nice dropdowns from html selects.

### Use cases

The user now should be able to input his age, symptoms and allergies. The other two routes have to be implemented to find adequate drugs and doctors.

Let's create 2 classes: DrugAdvisor and DoctorAdvisor. We put the queries from [neo4j gist](http://gist.neo4j.org/?8748719) with some changes into this classes.

**advisors/drug_advisor.rb**

~~~ruby
class DrugAdvisor
  def find(symptoms, age, allergies = [])
    Neo4j::Session.current.query.
        match('(patho:Pathology)-[:may_manifest_symptoms]->(symptoms:Symptom)').
        where('symptoms.name' => symptoms).
        with('patho').
        match('(drug_class:DrugClass)-[cures:cures]->(patho)').
        where('cures.age_min <= {age} AND {age} < cures.age_max').
        params(age: age).
        with('drug_class').
        match('(drug:Drug)-[:belongs_to_class]->(drug_class), (allergy:Allergy)').
        where('NOT (drug)-[:may_cause_allergy]->(allergy) OR NOT(allergy.name IN {allergies})').
        params(allergies: allergies).
        return('DISTINCT(drug) AS drug').
        to_a.map(&:drug)
  end
end
~~~

**advisors/doctor_advisor.rb**

~~~ruby
class DoctorAdvisor
  def find(symptoms, age, allergies = [], latitude = nil, longitude = nil)
    Neo4j::Session.current.query.
        match('(patho:Pathology)-[:may_manifest_symptoms]->(symptoms:Symptom)').
        where('symptoms.name' => symptoms).
        with('patho').
        match('(drug_class:DrugClass)-[cures:cures]->(patho)').
        where('cures.age_min <= {age} AND {age} < cures.age_max').
        params(age: age).
        with('drug_class').
        match('(drug:Drug)-[:belongs_to_class]->(drug_class), (allergy:Allergy)').
        where('NOT (drug)-[:may_cause_allergy]->(allergy) OR NOT(allergy.name IN {allergies})').
        params(allergies: allergies).
        with('drug_class, drug').
        match('(doctor:Doctor)-->(spe:DoctorSpecialization)-[:can_prescribe]->(drug_class)').
        return('DISTINCT(doctor) AS doctor, 2 * 6371 * asin(sqrt(haversin(radians({lat} - COALESCE(doctor.latitude,{lat}))) + cos(radians({lat})) * cos(radians(COALESCE(doctor.latitude,90)))* haversin(radians({long} - COALESCE(doctor.longitude,{long}))))) AS distance').
        params(lat: latitude, long: longitude).
        order('distance ASC').
        inject({}) do |hash, result|
          hash.merge!(result.doctor => result.distance)
        end
  end
end
~~~

They expect symptoms, age and allergies as input. DoctorAdvisor is also able to calculate distance to each doctor from given coordinates.
DoctorAdvisor builds a hash where doctors are keys and distances are values.

Now we can render found drugs and doctors as json in our routes.

**app.rb**

~~~ruby
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

get '/' do
  @symptoms  = Symptom.all
  @allergies = Allergy.all
  haml :index
end

get '/drug' do
  @drugs = DrugAdvisor.new.find(symptoms, age, allergies)
  @drugs.map(&:name).to_json
end

get '/doctor' do
  results = DoctorAdvisor.new.find(symptoms, age, allergies, latitude, longitude)
  results.inject({}) do |hash, pair|
    doctor, distance = pair
    hash.merge!(doctor.name => distance.round(2))
  end.to_json
end
~~~

The `drug` routes will return an array with drug names and the `/doctor` route will return a hash with doctor names and distances as json.

All we have to do now is to send ajax requests to the server to find drugs and doctors and insert the returned data into the page when user changes inputs.
But wait a minute. Geolocation should be send to the `/doctor` routes and we still don't have any way to get it from the user.
This javascript will request coordinates from browser and save them in the global namespace:

**public/app.js**

~~~javascript
window.onload = function(){
    if(navigator.geolocation) navigator.geolocation.getCurrentPosition(handleGetCurrentPosition);
};

function handleGetCurrentPosition(location){
    window.latitude     = location.coords.latitude;
    window.longitude    = location.coords.longitude;
}
~~~

And the last step. Here is the javascript which will make nice dropdowns using bootstrap-multiselect and update drug and doctor lists upon changing the user inputs:

**public/app.js**

~~~javascript
$(document).ready(function(){
    var adviseDrug = function(symptoms, age, allergies){
        $.getJSON('/drug', {"symptoms": symptoms, "allergies": allergies, age: age, latitude: window.latitude, longitude: window.longitude}).done(function(json){
            $(".suggestion .drugs").empty();
            $.each(json, function(key, value){
                $(".suggestion .drugs").append('<li class="list-group-item">' + value + '</li>');
            });
        });
    };

    var adviseDoctor = function(symptoms, age, allergies){
        $.getJSON('/doctor', {"symptoms": symptoms, "allergies": allergies, age: age, latitude: window.latitude, longitude: window.longitude}).done(function(json){
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

Please take a look at the complete source code of the application at [https://github.com/megorei/sinatra-neo4j-demo](https://github.com/megorei/sinatra-neo4j-demo) if something was not clear.
