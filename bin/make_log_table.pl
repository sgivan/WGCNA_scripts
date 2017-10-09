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

my ($debug,$verbose,$help,$meancolumn,$infile,$log2,$limitIDfile,$sn,$notransf,$nomean);

my $result = GetOptions(
    "debug"     =>  \$debug,
    "verbose"   =>  \$verbose,
    "help"      =>  \$help,
    "mean:i"    =>  \$meancolumn,
    "infile:s"  =>  \$infile,
    "log2"      =>  \$log2,
    "sn"        =>  \$sn,
    "notransf"  =>  \$notransf,
    "nomean"    =>  \$nomean,
    "limit:s"   =>  \$limitIDfile,
);

if ($help) {
    help();
    exit(0);
}

sub help {

    say <<HELP;
    "debug"     
    "verbose"   
    "help"      
    "mean:i"    
    "infile:s"  
    "log2"      
    "sn"        
    "notransf"
    "nomean" 
    "limit:s"   


HELP

}

# this is how I made the input file on the command line:

#cat BPAH.read_group_tracking.txt | sed -E 's/BPAH\t0/BPAH\tBJL/' | sed -E 's/BPAH\t1/BPAH\tKNO/' | sed 's/BPAH\t2/BPAH\tAKV/' | sed 's/BPAH\t3/BPAH\tCKM/' | sed 's/BPAH\t4/BPAH\tCLP/' | cut -f 1,2,3,7 > BPAH.read_group_tracking.txt.01
#join BPAH.read_group_tracking.txt.01_out.txt EE2.read_group_tracking.txt.01_out.txt > joined.txt
#join joined.txt EtOH.read_group_tracking.txt.01_out.txt.meanonly.txt > joined2.txt 
#sed -E 's/ /\t/g' joined2.txt > joined3.txt

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
        pop(@vals) unless ($nomean);
        $header = join "\t", @vals;
        next;
    }
    #chomp(my $line = $_);
    say "line: '$line'" if ($debug);
    say "length of \@vals: '" . scalar(@vals) . "'" if ($debug);

    my $gene = shift(@vals);
    if ($limitIDfile) {
        next unless $limitIds{$gene};
    }

    if ($notransf) {

        say "will not be calculating log FC values" if ($debug);

        if (!$printHeader) {
            say $OUT $header;
            ++$printHeader;
        }

        say $OUT "$gene\t" . join "\t", @vals;


    } else {
        my @logFC = ();
        unless($nomean) {
            my $meanval = pop(@vals);
            say "meanval: '$meanval'" if ($debug);
            next unless ($meanval);

            say "will be calculating log FC for these values: '@vals'" if ($debug);

            @logFC = ();
            if ($log2) {
                #@logFC = map {log($_/$meanval)/log(2)} @vals;
                @logFC = map {$_ ? log($_/$meanval)/log(2) : log($meanval/$meanval)/log(2)} @vals;
            } else {
                #@logFC = map {log($_/$meanval)/log(10)} @vals;
                @logFC = map {$_ ? log($_/$meanval)/log(10) : log($meanval/$meanval)/log(10)} @vals;
            }

            if ($sn) {
                @logFC = map { sprintf("%.2e", $_) } @logFC;
            }

            say "logFC values: '@logFC'" if ($debug);
        } else {

            @logFC = ();
            if ($log2) {
                #@logFC = map {log($_/$meanval)/log(2)} @vals;
                @logFC = map {$_ ? log($_)/log(2) : 0} @vals;
            } else {
                #@logFC = map {log($_/$meanval)/log(10)} @vals;
                @logFC = map {$_ ? log($_)/log(10) : 0} @vals;
            }

            if ($sn) {
                @logFC = map { sprintf("%.2e", $_) } @logFC;
            }

        }

        if (!$printHeader) {
            say $OUT $header;
            ++$printHeader;
        }
        say $OUT "$gene\t" . join "\t", @logFC;
    }

    last if ($debug && ++$cnt > 10);
}

close($OUT);




