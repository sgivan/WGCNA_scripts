#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  make_log_table.pl
#
#        USAGE:  ./make_log_table.pl  
#
#  DESCRIPTION:  Script to take output of make_gene_table.pl
#                   and create a table of log(fold-change).
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr. Scott A. Givan (sag), givans@missouri.edu
#      COMPANY:  University of Missouri, USA
#      VERSION:  1.0
#      CREATED:  07/14/16 13:00:22
#     REVISION:  ---
#===============================================================================

use 5.010;      # Require at least Perl version 5.10
use autodie;
use Getopt::Long; # use GetOptions function to for CL args
use warnings;
use strict;

my ($debug,$verbose,$help,$meancolumn,$infile,$log2,$limitIDfile);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "mean:i"    =>  \$meancolumn,
    "infile:s"  =>  \$infile,
    "log2"      =>  \$log2,
    "limit:s"   =>  \$limitIDfile,
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
    "mean:i"    =>  \$meancolumn, # default is last column
    "infile:s"  =>  \$infile,
    "log2"      =>  \$log2,
    "limit:s"   =>  \$limitIDfile,


HELP

}

$infile = 'infile' unless ($infile);
my $outfile = $infile . "_logFC.txt";

open(my $IN, "<", $infile);
open(my $OUT, ">", $outfile);

my (%limitIds) = ();
if ($limitIDfile) {
    open(my $ID,"<",$limitIDfile);
    my @limitIds = <$ID>;
    close($ID);
    for my $id (@limitIds) {
        chomp($id);
        ++$limitIds{$id};
    }
}

my ($cnt) = ();
my ($header,$printHeader);
while (<$IN>) {
    chomp(my $line = $_);
    my @vals = split "\t", $line;
    if (++$cnt <= 1) {
        pop(@vals);
        $header = join "\t", @vals;
        next;
    }
    #chomp(my $line = $_);
    say "line: '$line'" if ($debug);
    #my @vals = split "\t", $line;
    say "length of \@vals: '" . scalar(@vals) . "'" if ($debug);
    my $meanval = pop(@vals);
    say "meanval: '$meanval'" if ($debug);
    next unless ($meanval);

    my $gene = shift(@vals);
    if ($limitIDfile) {
        next unless $limitIds{$gene};
    }

    say "will be calculating log FC for these values: '@vals'" if ($debug);

    my @logFC = ();
    if ($log2) {
        #@logFC = map {log($_/$meanval)/log(2)} @vals;
        @logFC = map {$_ ? log($_/$meanval)/log(2) : log($meanval/$meanval)/log(2)} @vals;
    } else {
        #@logFC = map {log($_/$meanval)/log(10)} @vals;
        @logFC = map {$_ ? log($_/$meanval)/log(10) : log($meanval/$meanval)/log(10)} @vals;
    }

    say "logFC values: '@logFC'" if ($debug);

    if (!$printHeader) {
        say $OUT $header;
        ++$printHeader;
    }
    say $OUT "$gene\t" . join "\t", @logFC;

    last if ($debug && ++$cnt > 10);
}




