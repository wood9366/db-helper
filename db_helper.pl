#!/usr/bin/env perl

use 5.10.0;
use warnings;
use strict;
use Data::Dumper;

use XML::Twig;

sub load_database_config() {
    my $xml = XML::Twig->new();

    $xml->parsefile('config.xml');

    my @databases = ();

    foreach my $node_db (@{&node_child_array($xml->root, 'databases', 'database')}) {
        my @err = ();
        my @warn = ();
        
        my $name = $node_db->field('name');

        if ($name !~ /^[0-9a-zA-Z_]+$/) {
            push @err, sprintf("invalid name [%s]", $name);
        }

        my $num = $node_db->field('num') || 1;

        if ($name !~ /^[0-9a-z_]+$/) {
            push @warn, sprintf("name [%s] better declare with a-z, 0-9 and _", $name);
        }

        if ($num <= 0) {
            push @err, sprintf("invalid num [%d]", $num);
        }

        if (@err or @warn) {
            say "database [$name]";

            if (@err) {
                &print_info(\@err, 'E');
                next;
            }

            if (@warn) {
                &print_info(\@warn, 'W');
            }
        }

        unless (@err) {
            push @databases, { name => $name, num => $num };
        }
    }

    my @tables = ();

    foreach my $node_tbl (@{&node_child_array($xml->root, 'tables', 'table')}) {
        my @err = ();
        my @warn = ();

        my $name = $node_tbl->field('name');

        if ($name !~ /^[0-9a-zA-Z_]+$/) {
            push @err, sprintf("invalid name [%s]", $name);
        }

        if ($name !~ /^[0-9a-z_]+$/) {
            push @warn, sprintf("name [%s] better declare with a-z, 0-9 and _", $name);
        }

        my $database = $node_tbl->field('database');

        unless (grep { $_->{name} eq $database } @databases) {
            push @err, sprintf("belongs database [%s] don't exist", $database);
        }

        my $num = $node_tbl->field('num') || 1;

        if ($num <= 0) {
            push @err, sprintf("invalid num [%d]", $num);
        }

        my @fields = ();

        foreach my $node_field (@{&node_child_array($node_tbl, 'fields', 'field')}) {
            my ($field, $info) = &parse_node_field($node_field);

            if (@{$info->{err}}) {
                push @err, { "field [$info->{name}]" => $info->{err} };
            }

            if (@{$info->{warn}}) {
                push @warn, { "field [$info->{name}]" => $info->{warn} };
            }

            push @fields, $field if $field;
        }

        my @keys = ();

        foreach my $node_key (@{&node_child_array($node_tbl, 'keys', 'key')}) {
            my @key_err = ();
            my $key = $node_key->text;

            unless (grep { $key eq $_->{name} } @fields) {
                push @key_err, sprintf("invalid key [%s]", $key);
            }

            if (@key_err) {
                push @err, { "key [$key]" => \@key_err };
            } else {
                push @keys, $key;
            }
        }

        if (@err or @warn) {
            say "table [$name]";

            if (@err) {
                &print_info(\@err, 'E');
                next;
            }

            if (@warn) {
                &print_info(\@warn, 'W');
            }
        }

        unless (@err) {
            push @tables, { name => $name, num => $num, fields => \@fields };
        }
    }

    return { databases => \@databases, tables => \@tables };
}

sub node_child_array() {
    my $n = shift;
    my $arr = shift || '';
    my $ele = shift || '';

    my @array = ();

    @array = $n->first_child($arr)->children($ele) if $n->has_child($arr);

    return \@array;
}

sub parse_field_type() {
    my %type = ();

    return \%type;
}

sub print_info() {
    my $err = shift;
    my $flag = shift || 'I';

    foreach (@$err) {
        if (ref $_) {
            my ($k, $v) = each %$_;
            say "  $k";
            say "    $flag> $_" foreach @$v;
                            
        } else {
            say "  $flag> $_";
        }
    }
}

sub parse_node_field() {
    my $node = shift;

    my @err = ();
    my @warn = ();

    my $name = $node->field('name');

    if ($name !~ /^[0-9a-zA-Z_]+$/) {
        push @err, sprintf("invalid name [%s]", $name);
    }

    if ($name !~ /^[0-9a-z_]+$/) {
        push @warn, sprintf("name [%s] better declare with a-z, 0-9 and _", $name);
    }

    my $type = $node->field('type');

    if (not &is_valid_field_type($type)) {
        push @err, sprintf("invalid type [%s]", $type);
    }

    my $default;

    if ($node->has_child('default')) {
        $default = $node->field('default') || '';

        if (not &is_valid_field_value($type, $default)) {
            push @err, sprintf("invalid default value [%s]", $default);
        }
    }

    my $field;

    unless (@err) {
        $field = {
            name => $name, type => $type, default => $default
        };
    }

    return $field, { name => $name, err => \@err, warn => \@warn };
}

sub is_valid_field_type() {
    1;
}

sub is_valid_field_value() {
    1;
}

my $db_config = &load_database_config();

say Dumper($db_config);
