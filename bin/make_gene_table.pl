#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  make_gene_table.pl
#
#        USAGE:  ./make_gene_table.pl  
#
#  DESCRIPTION:  Script to create a table where each gene is a row
#                   and each column is a condition.
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  07/14/16 11:46:45
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;
use Statistics::Descriptive;

my ($debug,$verbose,$help,$infile,$reps,$mean,$infofile);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "infile:s"  =>  \$infile,
    "reps:i"    =>  \$reps,
    "info:s"    =>  \$infofile,
    "mean"      =>  \$mean,
);

if ($help) {
    help();
    exit(0);
}

sub help {

    say <<HELP;
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "infile:s"  =>  \$infile,
    "reps:i"    =>  \$reps,
    "infos"
    "mean"      =>  \$mean,

HELP

}

$infile = 'infile' unless ($infile);
$reps = 2 unless ($reps);
my $outfile = $infile . "_out.txt";
my $stat = Statistics::Descriptive::Full->new();

open(my $IN, "<", $infile);
open(my $OUT, ">", $outfile);

my ($cnt, $repcnt, %table, @temparr) = (0,0);
my ($lastgene) = ();
my @header = ('gene');

my %read_group_info;
if ($infofile) {
    # open and parse read_groups.info.txt file
    open(my $INFO, "<", $infofile);
    while (<$INFO>) {
        chomp($_);
        say "parsing $infofile line: '$_'";
        my @ivals = split/\t/, $_;
        say "extracting sample name from: '$ivals[0]'";
        if($ivals[0] =~ /^(.+?)\//) {
            say "sample name can be extracted: '$1'";
            $read_group_info{$ivals[1] . "_" . $ivals[2]} = $1;
        } else {
            say "sample name cannot be extracted";
            $read_group_info{$ivals[1] . "_". $ivals[2]} = $ivals[0];
        }
    }
}

while (<$IN>) {
    chomp(my $line = $_);
    my @vals = split /\t/, $line;

    next unless (substr($vals[0],0,4) eq 'gene');
    ++$cnt;

    say "processing line: '$line'" if ($debug);
    if (scalar(@header) <= $reps) {
        #push(@header,$vals[2]);
        if ($infofile) {
            push(@header, $read_group_info{$vals[1] . "_" .$vals[2]});
        } else {
            push(@header,$vals[1] . "_" .$vals[2]);
        }
    }
    
    if (!$lastgene) {
        $lastgene = $vals[0];
        ++$repcnt;
    } else {
        if (++$repcnt == $reps) {
            push(@temparr, $vals[3]);
            if ($mean) {
                $stat->add_data(@temparr);
                push(@temparr,$stat->mean());
                $stat->clear();
            }
            $table{$vals[0]} = [@temparr];
            @temparr = ();
            $lastgene = 0;
            $repcnt = 0;
            next;
        }
    }

    push(@temparr,$vals[3]);

    last if ($debug && $cnt >= 20);

}

say "$cnt lines parsed" if ($verbose);

# generate output table
push(@header, "Mean") if ($mean);
say $OUT join "\t", @header;

for my $key (sort(keys(%table))) {
    my $datstring = join "\t", @{$table{$key}};

    say $OUT "$key\t$datstring";
    if ($debug) {
        say "key: '$key'\ndatstring: '$datstring'";
    }

}
