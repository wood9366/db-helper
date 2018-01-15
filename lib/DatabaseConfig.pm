#!/usr/bin/env perl

use 5.10.0;

use base Exporter;

use warnings;
use strict;

use Log;
use XML::Twig;

our @EXPORT = qw / load_database_config /;

my @databases = ();
my @tables = ();

sub load_database_config {
    my $path = shift;
    my $xml = XML::Twig->new();

    if (-e $path) {
        $xml->parsefile($path);
    } else {
        loge("database config file [%s] doesn't exist", $path);
        return undef;
    }

    logi("load database config");
    log_indent;

    @databases = ();

    foreach my $node_db (@{&node_child_array($xml->root, 'databases', 'database')}) {
        my $database = &read_node_database($node_db);

        push @databases, $database if $database;
    }

    @tables = ();

    foreach my $node_tbl (@{&node_child_array($xml->root, 'tables', 'table')}) {
        my $table = &read_node_table($node_tbl);

        push @tables, $table if $table;
    }

    log_unindent;

    return {
        databases => { map { $_->{name} => $_ } @databases },
        tables => { map { $_->{name} => $_ } @tables },
    };
}

sub read_node_database {
    my $node = shift;

    my $err = 0;
    
    my $name = $node->field('name');

    logi("read database [%s]", $name);
    log_indent;

    if (not &is_valid_name($name)) {
        loge("invalid name [%s]", $name);
        $err = 1;
    }

    if (grep { $name eq $_->{name} } @databases) {
        loge("duplicate name [%s]", $name);
        $err = 1;
    }

    if (not &is_suggest_name($name)) {
        logw("name [%s] better declare with a-z, 0-9 and _", $name);
    }

    my $num = $node->field('num') || 1;

    if ($num <= 0) {
        loge("invalid num [%d]", $num);
        $err = 1;
    }

    log_unindent;

    return $err ? undef : { name => $name, num => $num };
}

sub read_node_table {
    my $node = shift;

    my $err = 0;

    my $name = $node->field('name');

    logi("read table [%s]", $name);
    log_indent;

    if (not &is_valid_name($name)) {
        loge("invalid name [%s]", $name);
        $err = 1;
    }

    if (grep { $name eq $_->{name} } @tables) {
        loge("duplicate name [%s]", $name);
        $err = 1;
    }

    if (not &is_suggest_name($name)) {
        logw("name [%s] better declare with a-z, 0-9 and _", $name);
    }

    my $database = $node->field('database');

    unless (grep { $_->{name} eq $database } @databases) {
        loge("belongs database [%s] don't exist", $database);
        $err = 1;
    }

    my $num = $node->field('num') || 1;

    if ($num <= 0) {
        loge("invalid num [%d]", $num);
        $err = 1;
    }

    my @fields = ();

    foreach my $node_field (@{&node_child_array($node, 'fields', 'field')}) {
        my $field = &read_node_field($node_field, \@fields);

        if ($field) {
            push @fields, $field;
        } else {
            $err = 1;
        }
    }

    my @keys = ();

    foreach my $node_key (@{&node_child_array($node, 'keys', 'key')}) {
        my $err_key = 0;
        my $key = $node_key->text;

        unless (grep { $key eq $_->{name} } @fields) {
            $err_key = 1;
            loge("invalid key [%s]", $key);
        }

        if ($err_key) {
            $err = 1;
        } else {
            push @keys, $key;
        }
    }

    log_unindent;

    return $err ? undef : {
        name => $name,
        database => $database,
        num => $num,
        fields => \@fields,
        keys => \@keys,
    };
}

sub read_node_field {
    my $node = shift;
    my $fields = shift || [];

    my $err = 0;

    my $name = $node->field('name');

    logi("field [%s]", $name);
    log_indent;

    if (not &is_valid_name($name)) {
        loge("invalid name [%s]", $name);
        $err = 1;
    }

    if (grep { $name eq $_->{name} } @$fields) {
        loge("duplicate name [%s]", $name);
        $err = 1;
    }

    if (not &is_suggest_name($name)) {
        logw("name [%s] better declare with a-z, 0-9 and _", $name);
    }

    my $type = &parse_field_type($node->field('type'));

    $err = 1 unless $type;

    my $auto_increase;

    if ($type and $type->{type} eq 'integer' and $node->has_child('auto_increase')) {
        my $text = $node->field('auto_increase');

        my $re = sprintf(qr/^%s[0-9]+$/, $type->{unsigned} ? '' : qr/-?/);

        if ($text =~ $re) {
            $auto_increase = 0 + $text;
        } else {
            loge("invalid auto increase value [%s]", $text);
            $err = 1;
        }
    }

    my $default;

    if ($type and $node->has_child('default')) {
        $default = &parse_field_value($type, $node->field('default'));

        $err = 1 unless defined($default);
    }

    log_unindent;

    my $field;

    if (not $err) {
        $field = { name => $name, type => $type };
        $field->{default} = $default if defined($default);
        $field->{auto_increase} = $auto_increase if defined($auto_increase);
    }

    return $field;
}

sub parse_field_type {
    my $type = shift || '';

    if ($type =~ /(u)?int(8|16|32|64)?/) {
        return {
            type => 'integer',
            unsigned => defined($1) ? 1 : 0,
            size => defined($2) ? 0 + $2 : 32,
        };
    } elsif ($type =~ /float/) {
        return {
            type => 'float'
        };
    } elsif ($type =~ /datetime/) {
        return {
            type => 'datetime'
        };
    } elsif ($type =~ /(var)?char(?:\(([0-9]+)\))?/) {
        return {
            type => 'string',
            variable => defined($1) ? 1 : 0,
            length => defined($2) ? 0 + $2 : 32,
        };
    } else {
        loge("invalid field type [%s]", $_);
        return undef;
    }
}

sub parse_field_value {
    my $type = shift;
    my $val = shift;

    if ($type->{type} eq 'integer') {
        if ($val =~ /[0-9]+/) {
            return $val;
        } else {
            loge("invalid integer field type value [%s]", $val);
        }
    } elsif ($type->{type} eq 'string') {
        if ($val =~ /\w+/) {
            return $val;
        } else {
            loge("invalid string field type value [%s]", $val);
        }
    } elsif ($type->{type} eq 'float') {
        if ($val =~ /[0-9]+(?:\.[0-9]+)?/) {
            return $val;
        } else {
            loge("invalid float field type value [%s]", $val);
        }
    } elsif ($type->{type} eq 'datetime') {
        if ($val =~ /NOW/) {
            return $val;
        } else {
            loge("invalid datetime field type value [%s]", $val);
        }
    } else {
        loge("can't parse field type [%s] value [%s]", $type->type, $val);
    }

    return undef;
}

sub is_valid_name {
    my $name = shift || '';

    return $name =~ /^[0-9a-zA-Z_]+$/;
}

sub is_suggest_name {
    my $name = shift || '';

    return $name =~ /^[0-9a-z_]+$/;
}

sub node_child_array {
    my $n = shift;
    my $arr = shift || '';
    my $ele = shift || '';

    my @array = ();

    @array = $n->first_child($arr)->children($ele) if $n->has_child($arr);

    return \@array;
}

sub is_valid_field_type {
    1;
}

sub is_valid_field_value {
    1;
}

1;
