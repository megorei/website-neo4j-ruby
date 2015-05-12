After we had migrated a project from a relational database to Neo4j using [neo4j](https://github.com/neo4jrb/neo4j) gem, the pagination was broken.

We tried existing addons for will_paginate such as [https://github.com/dnagir/neo4j-will_paginate](https://github.com/dnagir/neo4j-will_paginate) and [https://github.com/neo4jrb/neo4j-will_paginate_redux](https://github.com/neo4jrb/neo4j-will_paginate_redux) or using [Neo4j::Paginated](http://www.rubydoc.info/github/neo4jrb/neo4j/Neo4j/Paginated).
But they were oudated or didn't work as expected.

Moreover in original project we used [kaminari](https://github.com/amatsuda/kaminari) gem for pagination because it has nice active_record-like query syntax and easily integrates with bootstrap framework with [kaminari-bootstrap](https://github.com/mcasimir/kaminari-bootstrap).

So we decided to add neo4j support for kaminari.

You can give it a try by adding in your Gemfile:

~~~ruby
gem 'kaminari', github: 'dpisarewski/kaminari', branch: 'neo4j'
~~~

## Update

I created a new gem 'kaminari-neo4j' which adds neo4j support to kaminari. It's available on [rubygems](https://rubygems.org/gems/kaminari-neo4j) and on [github](https://github.com/megorei/kaminari-neo4j).