#!/usr/bin/env perl

use v5.10.1;

use warnings;
use strict;
no warnings 'experimental::smartmatch';

use Data::Dumper;
use Template;
use File::Basename;
use File::Spec::Functions;
use Cwd 'abs_path';

use DatabaseConfig;

my $dir = dirname(abs_path($0));

my $db_config = load_database_config('config.xml');

# say Dumper($db_config);

# setup tempalte
my $tt = Template->new({
    INCLUDE_PATH => catfile($dir, 'template'),
    TRIM => 1,
}) || die "$Template::ERROR", "\n";

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

sub gen_sql {
    my $template = shift;
    my $vars = shift;

    my $output = '';

    $tt->process("sql/${template}.sql.tt", $vars, \$output) || die $tt->error(), "\n";

    return $output;
}

# generate create database sql
foreach my $db (values %{$db_config->{databases}}) {
    foreach my $idx (0 .. $db->{num} - 1) {
        my $vars = { name => get_name($db->{name}, $idx, $db->{num}) };

        push @sqls, gen_sql('create_database', $vars);
    }
}

# generate create table sql
foreach my $tbl (values %{$db_config->{tables}}) {
    my $db = $db_config->{databases}{$tbl->{database}};

    foreach my $db_idx (0 .. $db->{num} - 1) {
        foreach my $tbl_idx (0 .. $tbl->{num} - 1) {
            my $vars = $tbl;

            $vars->{engine} = 'innodb';
            $vars->{charset} = 'utf8';
            $vars->{db} = get_name($db->{name}, $db_idx, $db->{num});
            $vars->{table} = get_name($tbl->{name}, $tbl_idx, $tbl->{num});

            push @sqls, gen_sql('create_table', $vars);
        }
    }
}

open FILE, '>', 'create.sql';
say FILE "$_\n" foreach @sqls;
close FILE;
