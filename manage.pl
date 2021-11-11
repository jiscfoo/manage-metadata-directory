#!/usr/bin/env perl

use strict;
use warnings;
use Carp::Assert;
use Getopt::Std;
use POSIX qw(strftime);

use XML::XPath;
use XML::XPath::XMLParser;
use Digest::SHA qw(sha1_hex);

use Cwd qw(abs_path);
use File::Spec;
# use File::Temp;

use Data::Dumper;
my %opts;
my $LOGLEVEL = 4;

sub msg($;@) {
    my ($s, @vals) = @_;
    printf('[%s] ' . $s . "\n", strftime('%F %T', localtime), @vals);
}

sub error($;@)   { return unless $LOGLEVEL >= 1; my ($s, @vals) = @_; msg('ERROR   ' . $s, @vals); }
sub warning($;@) { return unless $LOGLEVEL >= 2; my ($s, @vals) = @_; msg('WARNING ' . $s, @vals); }
sub notice($;@)  { return unless $LOGLEVEL >= 3; my ($s, @vals) = @_; msg('NOTICE  ' . $s, @vals); }
sub info($;@)    { return unless $LOGLEVEL >= 4; my ($s, @vals) = @_; msg('INFO    ' . $s, @vals); }
sub debug($;@)   { return unless $LOGLEVEL >= 5; my ($s, @vals) = @_; msg('DEBUG   ' . $s, @vals); }
sub trace($;@)   { return unless $LOGLEVEL >= 6; my ($s, @vals) = @_; msg('TRACE   ' . $s, @vals); }

sub get_entityid($) {
    my $filename = shift;
    my $xp = XML::XPath->new(filename => $filename) or die "Unable to open $filename: $!";
    my $search = $xp->findvalue('/EntityDescriptor/@entityID') or warn "Unable to extract entityID from $filename";
    return $search;
}

sub hash_entityid($) {
    my $entityid = shift;
    assert($entityid);
    my $hash = sha1_hex($entityid);
    return $hash;
}

sub set_symlink($$;$) {
    my ($source, $target) = @_;
    if(-l $target) {
        if(readlink($target) eq $source) {
            trace('Skipped recreating %s <- %s', $source, $target);
            return;
        } else {
            unlink($target);
            trace('Removed existing symlink %s', $target);
        }
    }
    symlink($source, $target);
    info('Created symlink %s <-- %s', $source, $target);
}

getopts('hts:d:v:', \%opts);
if($opts{h} or !($opts{s} and $opts{d})) {
    print <<EOF;
Usage: manage.pl -s <source> -d <target> [ -t ] [ -v num ]

  -s dir   source
  -d dir   target / destination
  -t       tidy dangling files
  -v num   log level (0-6; default=4)

EOF
    exit(0);
}

assert(-d $opts{s});
assert(-d $opts{d});
$LOGLEVEL = $opts{v} if $opts{v};

my @source_files;
my %target_files;

my $source_dir = abs_path(File::Spec->canonpath($opts{s}));
trace('Source dir = %s', $source_dir);

opendir(S, $opts{s}) or die "Unable to open source directory ($opts{s}): $!";
while(my $f = readdir(S)) {
    unshift (@source_files, $f);
}
closedir(S);

if($opts{t}) {
    opendir(D, $opts{d}) or die "Unable to open source directory ($opts{d}): $!";
    while(my $f = readdir(D)) {
        $target_files{$f} = 1;
    }
    closedir(D);
}

debug('Starting to process %d files', scalar @source_files);

foreach my $filename (@source_files) {
    my $f = "$opts{s}/$filename";
    unless (-f $f) {
        debug("Skipping $f");
        next;
    }
    trace("Processing $f");

    my $entityid = get_entityid("$f");
    my $hash = hash_entityid($entityid);

    trace("%s -> %s -> %s.xml", $f, $entityid, $hash);
    set_symlink("$source_dir/$filename", "$opts{d}/$hash.xml");
    if($opts{t}) {
        delete $target_files{"$hash.xml"};
    }
}

if($opts{t}) {
    foreach my $f (keys %target_files) {
        next if $f eq '.' or $f eq '..';
        info('Tidying %s', "$opts{d}/$f");
        unlink("$opts{d}/$f") or warn "Failed to tidy $opts{d}/$f: $!";
    }
}
