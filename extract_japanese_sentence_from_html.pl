#!/usr/bin/env perl

use utf8;
use Encode;
use strict;
use 5.010;
use Term::ANSIColor qw(:constants);
use LWP::Simple;
use URI;
#use MIME::Base64;


################################################################
#
# 일정한 법칙으로 코딩된 html문서의 일본어 문장을 추출하는 프로그램
#


## LWP init
my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:13.0) Gecko/20100101 Firefox/13.0.1");
my @header = ('Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
	           'Accept-Encoding' => 'gzip, deflate',
	           'Accept-Language' => 'ko-kr,ko;q=0.8,en-us;q=0.5,en;q=0.3',
	           'Cache-Control' => 'no-cache' ,
	           'Connection' => 'keep-alive' ,
	           #'Content-Length' => 20426 ,
	           'Content-Type' => 'application/x-www-form-urlencoded;charset=utf-8' ,
	           'Host' => 'translate.google.co.kr' ,
	           'Pragma' => 'no-cache' ,
	           'Referer' => 'http://translate.google.co.kr/' ,
	           'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:13.0) Gecko/20100101 Firefox/13.0.1'
    );
my $url = URI->new('http://translate.google.co.kr/translate_a/t');
$url->query_form (
'client'=>'t',
'hl'=>'ko',
'ie'=>'UTF-8',
'multires'=>'1',
'oe'=>'UTF-8',
'otf'=>'1',
'pc'=>'1',
'sc'=>'1',
'sl'=>'ja',
'srcrom'=>'1',
'ssel'=>'0',
'text'=>"a",
'tl'=>'ko',
'tsel'=>'0'
);


my $fileread_count = 0;

#open STDOUT , '>>' , 'result.txt';

while ( defined($ARGV[0]) )
{
    my $currentFile = shift @ARGV;

    print RED;
    say "====================\n : $currentFile\n" ;
    print RESET;

    my $line = 1;
    open my $fh , '<' , $currentFile;
    open my $fh_to_gr , '>>' , "google_results/$currentFile";
    for ( <$fh> )
    {
	$_ = decode("UTF-8",$_);
	


	state $state = undef;
	state $between_text;
	
	#chomp();
	unless ( defined( $state ) ) {
	    print BOLD;
	    if ( /((<A|<a)$)/ ) {
		$state = "open A";
		print CYAN;
		say "find Line $1:$line -> $_";
		#$between_text .= $2;
	    }
	    elsif ( /^(>[A-Za-z…-齢])|[…-齢]/ ) # 줄이 >로 시작하고 바로뒤의 문자가 영어또는 일본어이거나 , 줄자체에 일본어가 포함되어 있다면 일본어 문맥으로 판단.
	    {
		$state = "start j";
		print MAGENTA;
		say "find Line Japenses:$line -> $_";
		
	    }
	    print RESET;
	}
	if ( defined( $state ) ){

	    if ( $state eq "open A" ) 
	    {
		
		$between_text .= $_;
		if ( /<\/(A|a)$/) 
		{
		    $state = undef;
#		    say $between_text."\n";
		    
		    save_google_result($fh_to_gr,$between_text,translation($between_text));

		    $between_text = '';
		}
	    }
	    elsif ( $state eq "start j" ) 
	    {
		$between_text .= $_;
		
		if ( /。|<\/[HPT]/)
		{
		    $state = undef;
		    if ( $between_text =~ /[…-齢]/ ) {

			save_google_result($fh_to_gr,$between_text,translation($between_text));

#			say $between_text."\n";
		    } else {
			say YELLOW "Not found Japenese\n\n";
		    }
		    $between_text = '';
		}
	    }
	}

	#if ( /[…-齢]+/ ) {
	#    say "find Line :$line -> $_"; 
	#}

	$line++;
    }
    close $fh_to_gr;
    close $fh;
    
    $fileread_count ++;
#    exit if $fileread_count == 10;
}

sub translation {
    my $text = $_[0];
    my $trans_text;

    #$text = "%3EPostgreSQL%209.1.4%E6%96%87%E6%9B%B8%3C%2FTITLE";
    #$text = "文";
    $url->query_form (
	'client'=>'t',
	'hl'=>'ko',
	'ie'=>'UTF-8',
	'multires'=>'1',
	'oe'=>'UTF-8',
	'otf'=>'1',
	'pc'=>'1',
	'sc'=>'1',
	'sl'=>'ja',
	'srcrom'=>'1',
	'ssel'=>'0',
	'text'=>$text,
	'tl'=>'ko',
	'tsel'=>'0'
	);

    my $res = $ua->get ($url);

    
    if ($res->is_success) {
	say "Success Translation";
	$trans_text = $res->content;
	#print $trans_text;
	$trans_text = decode("UTF-8",$trans_text);
    }else {
	say $res->status_line;
    }

    return $trans_text;
}

sub save_google_result {
    my ($fh, $original_text, $google_result_text) = @_;
    
    $original_text = encode("UTF-8",$original_text);
    $google_result_text = encode("UTF-8",$google_result_text);
    print $fh "<PIECE>\n";
    print $fh " <ORIGINAL>\n";
    print $fh $original_text;
    print $fh " </ORIGINAL>\n";
    print $fh " <GOOGLE_RESULT>\n";
    print $fh $google_result_text;
    print $fh " </GOOGLE_RESULT>\n";
    print $fh "</PIECE>\n\n";
    
}
