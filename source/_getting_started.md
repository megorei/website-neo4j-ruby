### Installation

* Homebrew(OS X)

  ```
  brew install neo4j
  ```

* or download [http://neo4j.com/download/](http://neo4j.com/download/)

* or using neo4j gem

  ```
  rake neo4j:install
  ```

### Run neo4j server

* Homebrew(OS X)

  ```
  neo4j start
  ```

* or dowloaded

  ```
  cd path/to/your/neo4j
  bin/neo4j start
  ```

* or using neo4j gem

  ```
  rake neo4j:start
  ```

### Open Neo4j Browser

After Neo4j server has started you can open Neo4j Browser at
[http://localhost:7474/](http://localhost:7474/)
