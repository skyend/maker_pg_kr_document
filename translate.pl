#!/usr/bin/env perl

use strict;
use 5.010;
use utf8;
use LWP::Simple;
use Encode;
use LWP 5.64;

#my $trans = get 'http://translate.google.co.kr/translate_a/t?client=t&text=extract%20to%20brain&hl=ko&sl=en&tl=ko&ie=UTF-8&oe=UTF-8&multires=1&otf=2&ssel=3&tsel=5&sc=1';
#print $trans

open my $fh , '<' ,'jp/index.html';
my $content;
for (<$fh>) {
    $content .= $_;
}
#print $content;


my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:13.0) Gecko/20100101 Firefox/13.0.1");

#my $req = HTTP::Request->new(GET => 'http://translate.google.co.kr/translate_a/t?client=t&text="$content"&hl=ko&sl=jp&tl=ko&ie=UTF-8&oe=UTF-8&multires=1&otf=2&ssel=3&tsel=5&sc=1');

my $url = 'http://translate.google.co.kr/translate_a/t';

my $req = HTTP::Request->new (POST => $url);
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

=asd
$req->content( 'client' => "t" ,
	       'hl' => "ko" ,
	       'ie' => "UTF-8" ,
	       'multires' => "1" ,
	       'oe' => "UTF-8" ,
	       'sc' => "1" ,
	       'sl' => "jp" ,
	       'ssel' => "0" ,
	       'tl' => "ko" ,
	       'tsel' => "0" ,
	       'text' => "$content"
    );
=cut

#$req->post ( $content );
#binmode STDOUT, ':encoding(UTF-8)';
#binmode STDIN, ':encoding(UTF-8)';
my $res = $ua->post ($url,
		    ['client' => "t",
		     'hl' => "ko" ,
		     'ie' => "UTF-8" ,
		     'multires' => "1" ,
		     'oe' => "UTF-8" ,
		     'otf' => "1" ,
		     'pc' => '1',
		     'sl' => "ja" ,
		     'ssel' => "0" ,
		     'tl' => "ko" ,
		     'tsel' => "0" ,              
		     'text' => $content],
		    );#$ua->request($req);

if ($res->is_success) {
    open my $save , '>' ,'ko/index.html';
    print $save decode("UTF-8",$res->content); #encode("UTF-8",$res->content);
    close $save;
} else {
    say $res->status_line;
}
