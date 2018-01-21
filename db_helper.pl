#!/usr/bin/env perl

use v5.10.1;

use warnings;
use strict;
no warnings 'experimental::smartmatch';

use Data::Dumper;
use Template;

use DatabaseConfig;

my $db_config = load_database_config('config.xml');

# say Dumper($db_config);

my @sqls = ();

sub get_name {
    my $name = shift || '';
    my $idx = shift || 0;
    my $num = shift || 1;

    if ($num > 1) {
        my $n = length($num - 1);

        $name .= sprintf("_%0${n}d", $idx);
    }

    return $name;
}

# generate create database sql
sub sql_create_database {
    return sprintf("CREATE DATABASE IF NOT EXISTS `%s`;", shift || '');
}

foreach my $db (values %{$db_config->{databases}}) {
    foreach my $idx (0 .. $db->{num} - 1) {
        push @sqls, sql_create_database(get_name($db->{name}, $idx, $db->{num}));
    }
}

# generate create table sql
sub sql_create_table {
    my $db_name = shift;
    my $tbl_name = shift;
    my $tbl = shift;

    my $sql = "CREATE TABLE IF NOT EXISTS `$db_name`.`$tbl_name`(";

    foreach my $field (@{$tbl->{fields}}) {
        my $is_valid_type = 1;
        my $sql_field = "\n  `$field->{name}`";

        given ($field->{type}{type}) {
            when (/^integer$/) {
                $sql_field .= ' INT';
                $sql_field .= ' UNSIGNED' if $field->{type}{unsigned};
                $sql_field .= ' NOT NULL';
                $sql_field .= ' DEFAULT ' . $field->{default} if exists $field->{default};
                $sql_field .= ' AUTO_INCREMENT' if exists $field->{auto_increase};
            }
            when (/^float$/) {
                $sql_field .= ' FLOAT';
                $sql_field .= ' NOT NULL';
                $sql_field .= ' DEFAULT ' . $field->{default} if exists $field->{default};
            }
            when (/^string$/) {
                $sql_field .= sprintf(" %sCHAR(%d)",
                                      $field->{type}{variable} ? 'VAR' : '',
                                      $field->{type}{length});
                $sql_field .= ' NOT NULL';
                $sql_field .= " DEFAULT '$field->{default}'" if exists $field->{default};
            }
            when (/^datatime$/) {
                $sql_field .= ' DATETIME';
                $sql_field .= ' NOT NULL';
                $sql_field .= ' DEFAULT NOW()' if $field->{default} eq 'NOW';
            }
            default { $is_valid_type = 0; }
        }

        $sql_field .= ",";

        $sql .= $sql_field if $is_valid_type;
    }

    $sql .= sprintf("\n  PRIMARY KEY (%s)", join(',', map { "`$_`" } @{$tbl->{keys}}));
    $sql .= "\n) ENGINE=innodb, CHARSET=utf8;";

    return $sql;
}

foreach my $tbl (values %{$db_config->{tables}}) {
    my $db = $db_config->{databases}{$tbl->{database}};

    foreach my $db_idx (0 .. $db->{num} - 1) {
        foreach my $tbl_idx (0 .. $tbl->{num} - 1) {
            push @sqls, sql_create_table(
                get_name($db->{name}, $db_idx, $db->{num}),
                get_name($tbl->{name}, $tbl_idx, $tbl->{num}),
                $tbl);
        }
    }
}

open FILE, '>', 'create.sql';
say FILE "$_\n" foreach @sqls;
close FILE;
