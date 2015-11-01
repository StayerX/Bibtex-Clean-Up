#!/usr/bin/env perl
# sudo apt-get install libtext-bibtex-perl

use strict;
use warnings;
use Text::BibTeX;

# File for parsing and cleaning up
# You may change it to my $input_filename = $ARGV[1];
my $input_filename = "thesis.bib";

# Temporary fix for bug https://rt.cpan.org/Public/Bug/Display.html?id=98806
system(qq|perl -i -pe 's/month = (\\w+),/month = \\{\$1\\},/' $input_filename|);


my $bibfile = Text::BibTeX::File->new($input_filename);
my $newfile = Text::BibTeX::File->new(">newthesis.bib"); # Output file

my @entries;

my %keys;
my $count = 0;
while (my $entry = Text::BibTeX::Entry->new( $bibfile ) ) {
print $entry;
	#next unless $entry->parse_ok;
	die $entry->key unless $entry->parse_ok;
	my $key = $entry->key;
	warn "Duplicate key $key" if exists $keys{ $key };
	$keys{ $key } = 1;

	#my $entry_text = $entry->print_s;
	#$entry_text =~ s/\n//gms;
	#print "$entry_text\n";
	$count = $count+1;
	push @entries, $entry;
}

print $count;
my @sorted = sort {
	my ($a_key, $a_year, $a_title, $a_author) = ($a->key, $a->get('year', 'title', 'author'));
	my ($b_key, $b_year, $b_title, $b_author) = ($b->key, $b->get('year', 'title', 'author'));
	my ( $k,  $y, $t, $a ) = (
		defined $a_key && defined $b_key ? $a_key cmp $b_key : 0,
		defined $a_year && defined $b_year ? $a_year <=> $b_year : 0,
		defined $a_title && defined $b_title ? $a_title cmp $b_title : 0,
		defined $a_author && defined $b_author ? $a_author cmp $b_author : 0,
	);
	$k or $y or $t or $a;
} @entries;

for my $entry ( @sorted ) {
	$entry->write ($newfile);
}

