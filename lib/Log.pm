package Log;

use strict;
our (@ISA, @EXPORT, @EXPORT_OK, $VERSION);

use Exporter;

$VERSION = 0.1;

@ISA = qw / Exporter /;
@EXPORT = qw / log_level log_indent log_unindent loge logw logi logd /;
@EXPORT_OK = qw //;

my $log_output_level = 2;

my @log_levels = qw /E W I D/;
my $log_indent = 0;

sub log_level {
    my $level = shift;
    $log_output_level = $level if defined($level);
}

sub log_indent { $log_indent++; }
sub log_unindent { $log_indent-- if $log_indent > 0; }

sub log {
    my $level = shift || 0;
    my $message = shift || '';

    return if $level > $log_output_level;

    my $leveltag = $log_levels[$level] || 'D';

    printf("  " x $log_indent . "$leveltag> $message\n", @_);
}

sub loge { &log(0, @_); }
sub logw { &log(1, @_); }
sub logi { &log(2, @_); }
sub logd { &log(3, @_); }
 
1;
