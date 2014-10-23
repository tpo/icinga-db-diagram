#!/usr/bin/perl
#
# This script uses the graphviz *.dot output of SchemaSpy,
# tries to guess which of the icinga_* tables' columns
# are foreign keys and produces a *.dot diagram with
# connections between foreign keys and tables
#
# see the README.md on how to use

use constant false => 0;
use constant true  => 1;

$DEBUG=false;
$OMIT_OBJECT_REFS=true;
$OMIT_INSTANCE_REFS=true;

sub log_ {
  print STDERR "@_\n";
}

sub debug_ {
  if($DEBUG) { log_(@_); }
}

sub read_lines {
  my @lines,
     $line;

  while( <> ) {
    $line = $_;
    push(@lines, $line);
  }
  return @lines;
}

sub set_bgcolor {
  my ($line,
      $color) = @_;

  if( $line =~ /BGCOLOR/ ) {
    $line =~ s/BGCOLOR="#\w+"/BGCOLOR="$color"/;
  }
  else {
    $line =~ s/ALIGN/BGCOLOR="$color" ALIGN/;
  }

  return $line;
}

sub print_lines {
  my (@lines,
      @foreign_keys) = @_;
  my $column,
     $current_table,
     $line_copy;

  for my $line (@lines) {
    $line_copy = $line;

    # we don't want to have the same layout as SchemaSpy
    if(    ( $line_copy =~ /rankdir=/ )
        || ( $line_copy =~ /nodesep=/ )
        || ( $line_copy =~ /ranksep=/ ) ) {
      next;
    }

    # keep track of the DB table we're printing
    if( $line_copy =~ /^  "icinga_(.*)"/ ) {
      $current_table=$1;
    }

    # mark table columns with different colors
    if( $line_copy =~ /PORT="(\w*)"/ ) {
      $column = $1;

      # we only want to mark columns that contain a key
      # keep in sync with 'print_legend' below
      if( $column =~ /_id$/ ) {
        if( $foreign_keys{$current_table,$column} eq "unknown" ) {
	  $line_copy = set_bgcolor($line_copy, "#ff7070"); # red:     unknown foreign keys
	}
        elsif( $foreign_keys{$current_table,$column} eq "primary" ) {
	  $line_copy = set_bgcolor($line_copy, "#00e000"); # green:   primary keys
	}
        elsif( $column =~ /object_id$/ ) {
	  $line_copy = set_bgcolor($line_copy, "#7070ff"); # blue:    object references
	}
        elsif( $column =~ /instance_id$/ ) {
	  $line_copy = set_bgcolor($line_copy, "#00e0e0"); # magenta: instance references
	}
        elsif( $column =~ /_id$/ ) {
	  $line_copy = set_bgcolor($line_copy, "#e0e000"); # yellow:  foreign keys
	}
      }
    }
    # do not print closing parenthesis
    # we want to insert the connecting lines there
    print $line_copy unless ( $line_copy =~ /^}/ );
  }
}

sub print_legend {
  print '
  "LEGEND" [
    label=<
    <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0" BGCOLOR="#ffffff">
      <TR><TD BGCOLOR="#9bab96" ALIGN="CENTER">LEGEND</TD></TR>
      <TR><TD BGCOLOR="#ff7070" ALIGN="LEFT">unknown foreign keys</TD></TR>
      <TR><TD BGCOLOR="#7070ff" ALIGN="LEFT">object references</TD></TR>
      <TR><TD BGCOLOR="#00e0e0" ALIGN="LEFT">instance references</TD></TR>
      <TR><TD BGCOLOR="#e0e000" ALIGN="LEFT">foreign keys</TD></TR>
    </TABLE>>
    tooltip="icinga_acknowledgements"
  ];
  ';
}

sub print_relations {
  my @lines = @_;

  for my $line (@lines) {
    print "$line\n";
  }
}

sub parse_table_names {
  my @lines = @_;
  my @tables;

  debug_("TABLES");
  debug_("======");

  for my $line (@lines) {
    if ( $line =~ /^  "icinga_(.*)"/ ) {
      my $table_name=$1;
      debug_("$table_name");
      $tables{$table_name}=true;
    }
  }

  debug_("");

  return @tables;
}

sub parse_relations {
  my (@lines,
      @tables) = @_;
  my  @relation_lines,
      @foreign_keys;
  my  $current_table,
      $referred_table,
      $table_row,
      $is_foreign_key,
      $primary_key;

  debug_("COLUMNS");
  debug_("=======");

  for my $line (@lines) {

    $is_primary_key = false;
    $is_foreign_key = false;

    if ( $line =~ /^  "icinga_(.*)"/ ) {
      $current_table=$1;
      $table_row = 0;
    }
    elsif ( $line =~ /PORT="(\w*)"/ ) {
      $column_name=$1;
      if ( $table_row == 0 ) {
        $is_primary_key = true;
        $foreign_keys{$current_table,$column_name} = "primary";
      }
      else {

        if ( $column_name =~ /(.*)_id$/ ) {

          $referred_table = $1;
          $referred_table = "${referred_table}s";
          $alternative_table = $referred_table;
          $alternative_table =~ s/_object//;
          $comments_table    = $referred_table;
          $comments_table    =~ s/internal_//;

          if( $tables{$referred_table} ) {
            $is_foreign_key=true;
	  }
	  elsif( $tables{$alternative_table} ) {
            $is_foreign_key=true;
            $referred_table = $alternative_table;
          }
	  elsif( $tables{$comments_table} ) {
            $is_foreign_key=true;
            $referred_table = $comments_table;
          }
	  elsif( $referred_table =~ /_timeperiod/ ) {
            $is_foreign_key=true;
            $referred_table = "timeperiods";
          }
	  elsif( $referred_table =~ /dependent_service/ ) {
            $is_foreign_key=true;
            $referred_table = "services";
          }
	  else {
            $foreign_keys{$current_table,$column_name} = "unknown";
            log_("don't know which table $current_table:$column_name referrs to");
          }
        }
        else {
          $is_foreign_key=false;
        }

      }
      if( $is_foreign_key && ( ! $is_primary_key ) ) {
	unless(    ( $OMIT_OBJECT_REFS   && ( $column_name =~ /object_id$/   ) )
	        || ( $OMIT_INSTANCE_REFS && ( $column_name =~ /instance_id$/ ) ) )
	{
          push(@relation_lines, "icinga_$current_table:$column_name -> icinga_$referred_table;");
	}
        debug_("$current_table:$column_name ->  $referred_table");
      }
      else {
        debug_("$current_table:$column_name  ".($is_primary_key ? "P" : "")." ".($is_foreign_key ? "FK" : ""));
      }
      $table_row++;
    }
  }

  return ( @relation_lines, @foreign_keys );
}

sub print_final_closing_parenthesis {
  print "}\n";
}

my @lines     = read_lines();
my @tables    = parse_table_names(@lines);
my (@relation_lines,
    @foreign_keys )
              = parse_relations(@lines,@tables);

print_lines(@lines,@foreign_keys);
print_relations(@relation_lines);
print_legend();
print_final_closing_parenthesis();


