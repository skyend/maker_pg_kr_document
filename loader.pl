#!/usr/bin/env perl

use strict;
use 5.010;
use utf8;
use LWP::Simple;
use Encode;

my $root_url = 'http://www.postgresql.jp/document/9.1/html/';
my $root_dir = 'jp/';

my $root_page = get $root_url;

#Root page download and save to file
open my $indexfh , '>' ,'jp/index.html';
print $indexfh encode("UTF-8",$root_page);
close $indexfh;

extracter('index.html');

sub extracter {
    my $file = $_[0];
    my @addresses;

    open my $fh , '<', "$root_dir$file";
    for (<$fh>) {
	if ( /^HREF=\"(.*?)\"/ ) {
	    if (! -e "$root_dir$1" ){
		push @addresses,$1;
		web_loader($1);
	    }
	    
	}
	
    }
    close $fh;
}

sub web_loader {
    my ($filename) = @_;
    
    my $target_url = $root_url.$filename;
    my $to_save = $root_dir.$filename;

    my $file = get $target_url;
    if ( $file ) {
	say "$target_url load Completes";
	
	open my $save_fh , '>' , $to_save or die("don't open $to_save");
	print $save_fh encode("UTF-8",$file);
	close $save_fh;
	
	extracter($filename);
    }
}
