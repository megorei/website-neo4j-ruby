### Installation

#### Homebrew(OS X)
    brew install neo4j
    
#### or download
    http://neo4j.com/download/
    
#### or using neo4j gem
    rake neo4j:install
    
### Run neo4j server

#### Homebrew(OS X)
    neo4j start
    
#### or dowloaded
Switch to the neo4j directory

    bin/neo4j start

#### or using neo4j gem
    rake neo4j:start

After Neo4j server has started you can open Neo4j webconsole at [http://localhost:7474/](http://localhost:7474/)