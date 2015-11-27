#!/usr/bin/env perl
# sudo apt-get install libtext-bibtex-perl

use strict;
use warnings;
use Text::BibTeX;
use File::Basename;


# TODO
# - all inproceedings entries must have Proc. in their booktitle key
# - if inproceedings::booktitle =~ /IEEE/, comment out the publisher if the publisher eq "IEEE"
# - check for missing volume and/or number key in article entry type: not an error, but can be a problem;
#   note that there may be a pubstate entry which means there would not be a volume
# - if the entry has a DOI, use the doi2bibtex to check if the entry type is
#   the same and if the publisher has extra fields --- this returns a warning
# - if the pubstate key exists:
#     - gather all unpublished entries
#     - check that the date of publication is in the future

my $dirname = dirname(__FILE__);

# File for parsing and cleaning up
# You may change it to my $input_filename = $ARGV[1];
print $dirname;
my $input_filename = "${dirname}/thesis.bib";
print $input_filename;

# Temporary fix for bug https://rt.cpan.org/Public/Bug/Display.html?id=98806
system(qq|perl -i -pe 's/month = (\\w+),/month = \\{\$1\\},/' $input_filename|);
# Show all non unicode characters
system(qq|grep --color="auto" -P -n "[\\x80-\\xFF]" $input_filename|);

my $bibfile = Text::BibTeX::File->new($input_filename);
my $newfile = Text::BibTeX::File->new(">${dirname}/newthesis.bib"); # Output file

my @entries;

my %keys;
my $count = 0;
while (my $entry = Text::BibTeX::Entry->new( $bibfile ) ) {
	#next unless $entry->parse_ok;
	die "<Error> Could not parse : $entry->key" unless $entry->parse_ok;
	my $key = $entry->key;
	my $type = $entry->type;
	die "<Error> not defined $type @ count :  $count" if not defined $key;
	warn "Duplicate key $key @ $count" if exists $keys{ $key };
	$keys{ $key } = 1;

	#my $entry_text = $entry->print_s;
	#$entry_text =~ s/\n//gms;
	#print "$entry_text\n";
	$count = $count+1;
	push @entries, $entry;
}

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
print "Done parsing bibtex. Parsed $count entries.\n";
