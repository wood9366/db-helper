#!/usr/bin/perl

use 5.10.0;
use Test::More;

use DatabaseConfig;

my $config = load_database_config('config.xml');

my $db1 = $config->{databases}{common};

is($db1->{name}, 'common');
is($db1->{num}, 1, "default database number");

my $db2 = $config->{databases}{ink_sanguo};

is($db2->{name}, 'ink_sanguo');
is($db2->{num}, 100);

my $tbl1 = $config->{tables}{account};

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

my $fld2 = $tbl1->{fields}[1];

is($fld2->{name}, 'username');
is($fld2->{type}{type}, 'string');
ok($fld2->{type}{variable});
is($fld2->{type}{length}, 64);

my $fld3 = $tbl1->{fields}[3];

is($fld3->{name}, 'score');
is($fld3->{type}{type}, 'float');
is($fld3->{default}, 0);

done_testing();
