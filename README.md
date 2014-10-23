icinga-db-diagram
=================

The ./schema\_spy\_to\_graph.pl script generates a diagram
of the icinga database schema.

It uses the graphviz \*.dot output of SchemaSpy, tries to
guess which of the icinga's tables' columns are foreign keys
and produces a connected dot diagram that can be fed to
graphviz to produce a diagram image.

### Examples

You can a generated icinga2 databse diagram
<a href="https://github.com/tpo/icinga-db-diagram/raw/master/diagram.png">
here</a> - it's quite large! It has been generated from
<a href="https://github.com/tpo/icinga-db-diagram/raw/master/concatenated.dot">
this dot file</a>.

### Requirements

* graphviz
* perl
* SchemaSpy (http://schemaspy.sourceforge.net/)

The script has been tested on Debian wheezy Linux with
perl 5.14.2, graphviz 2.26.3 and SchemaSpy 5.0.0.

Under Debian you'll need to additionally install the 'libpostgresql-jdbc-java'
package, which is the JDBC driver required by SchemaSpy.

### How to use

* use SchemaSpy as described on its homepage to produce
  the dot files, that can be found in the diagram directory.

    $ java -jar schemaSpy_5.0.0.jar -t pgsql -db icinga -host host.running.icinga:5432 -u icinga -p password -o output/ -dp /usr/share/java/postgresql-jdbc3-9.1.jar -s public

* concatenate the \*.dot files

    $ cat output/diagrams/*.dot > concatenated.dot

* edit the concatenated dot file, so that it only has one
  diagram definition in it. Delete all the other diagram
  preambles. That is, leave only one of these in the concatenated
  dot file:

    digraph "icinga_acknowledgements" {
      graph [
        rankdir="RL"
        bgcolor="#f7f7f7"
        nodesep="0.18"
        ranksep="0.46"
        fontname="Helvetica"
        fontsize="11"
      ];
      node [
        fontname="Helvetica"
        fontsize="11"
        shape="plaintext"
      ];
      edge [
        arrowsize="0.8"
      ];

* don't forget to only leave one closing parenthesis in the dot file:

    };

* feed the edited dot file to the script:

    $ cat concatenated.dot | ./schema_spy_to_graph.pl > diagram.dot

* use graphviz to create the image:

    $ dot diagram.dot -Tpng > diagram.png
    cat concatenated.dot | ./schema_spy_to_graph.pl > diagram.dot

### License

GPL 2+

### Author and Contact

Tomas Pospisek <tpo_deb@sourcepole.ch>
