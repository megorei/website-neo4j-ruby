#### Node assignment

If you tried using factory_girl with [neo4j](https://github.com/neo4jrb/neo4j), you probably got this error:

    Neo4j::ActiveNode::HasN::NonPersistedNodeError: Unable to create relationship with non-persisted nodes

Neo4j throws this error when you are assigning an association to a non-persisted node. And so works factory_girl:

A closer look at the source code of factory_girl it assigns every attribute including associations to the factory you are creating:

**https://github.com/thoughtbot/factory_girl/blob/master/lib/factory_girl/attribute_assigner.rb#L16**

~~~ruby
module FactoryGirl
  class AttributeAssigner
  ...

   def object
     @evaluator.instance = build_class_instance
     build_class_instance.tap do |instance|
       attributes_to_set_on_instance.each do |attribute|
         instance.public_send("#{attribute}=", get(attribute))
         @attribute_names_assigned << attribute
       end
     end
   end

   ...
~~~

#### Workaround

To workaround this issue I patched neo4j master branch, so it does not throw an exception in this case but just saves the non-persisted node.

This patch allows us at least to create factories using factory_girl.

You can install patched version of neo4j gem by adding into your Gemfile:

~~~ruby
gem 'neo4j', github: 'dpisarewski/neo4j', branch: 'factory_girl'
~~~


