#!/usr/bin/env perl

use 5.010;
use strict;

use Encode;
use utf8;
binmode STDIN, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

###################################################
# 해당 파일에서 사용되는 모든 문자 종류와 갯수 파악하는 프로그램
# 중간의 두개의 while 중 아래 while은 모든 문자를 매치하며
# 위의 while은 사용자가 정해준 범위 내의 문자만을 매치한다.


my %char_collection;

while ( defined($ARGV[0]) ) 
{
    my $currentFile = shift @ARGV;
    say $currentFile;
    
    open my $fh , '<' , $currentFile or die( "can not open file : $currentFile");
    
    for (<$fh>)
    {
	$_ = decode("UTF-8",$_);

	while ( s/([…-齢])// ) {
       #while ( s/(.)// ) {
	    if ( exists $char_collection{$1} )
	    {
		$char_collection{$1}++;
	    } else {
		$char_collection{$1} = 1;
	    }
	}
    }
    close $fh;

}

for (sort keys %char_collection ) 
{
    say "< $_ >' = { $char_collection{$_} }";
}
