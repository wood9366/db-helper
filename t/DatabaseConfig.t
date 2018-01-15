#!/usr/bin/perl

use 5.10.0;
use Test::More;

use DatabaseConfig;

my $config = load_database_config('config.xml');

is(@{$config->{databases}}, 2);

my $db1 = $config->{databases}[0];

is($db1->{name}, 'common');
is($db1->{num}, 1, "default database number");

my $db2 = $config->{databases}[1];

is($db2->{name}, 'ink_sanguo');
is($db2->{num}, 100);

is(@{$config->{tables}}, 3);

my $tbl1 = $config->{tables}[0];

is($tbl1->{name}, 'account');
is($tbl1->{num}, 100);
is($tbl1->{database}, 'ink_sanguo');

is(@{$tbl1->{fields}}, 5);

my $fld1 = $tbl1->{fields}[0];

is($fld1->{name}, 'uid');
is($fld1->{auto_increase}, 0);
is($fld1->{type}{type}, 'integer');
ok($fld1->{type}{unsigned});
is($fld1->{type}{size}, 64);

done_testing();
