#!/usr/bin/env perl

use 5.10.0;
use warnings;
use strict;
use Data::Dumper;

use DatabaseConfig;

my $db_config = load_database_config('config.xml');

say Dumper($db_config);
