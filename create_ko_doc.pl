#!/usr/bin/env perl

use warnings;
use strict;
use 5.010;
use Encode;
use utf8;
use Data::Dump qw(dump);
use Data::Dumper;
use Term::ANSIColor qw(:constants);

########################




process();

sub process {
    #my @ja_files = ("ja/index.html");
    #my @ko_pieces_files = ("google_results/ja_ko/index.html");
    
    my @list = get_fileList();
    
    for ( @list ) {
	
	my $filename = $_;
	create_ko_html ( "ja/$filename" , "google_results/ja_ko/$filename" , "ko/$filename");
    }
}

sub get_fileList {
    opendir my $DH , 'ja/' or die ("can not open dir :$!");
    my @list;
    
    for (readdir $DH) {
	next if /^(\.)/;
	push @list,$_ ;
#	say $_;
    }
    closedir $DH;
    return @list;
}

sub create_ko_html {
    my ($jafileName,$jaKoFileName,$newfileName) = @_;
    
    my $result_text;

    my $jafile;
    open my $jafh , '<' , $jafileName or die ("can not file open:$! $jafileName");
    while ( <$jafh> ) {
	$jafile .= $_;
    }
    close $jafh;
    
    $result_text = $jafile;

    my %pieces_hash = piece_parser( $jaKoFileName );
    for ( sort keys %pieces_hash )
    {
	#say "$_ -> $pieces_hash{$_}{ORIGINAL}";	
        # TD : Translation Data
	my %TD = google_data_parser ( $pieces_hash{$_}{GOOGLE_RESULT} );
	
#	print MAGENTA "\n TD : ";
	for (keys %TD) {
	    print RED;
	    say "";
	    say "$_ -> $TD{$_}";
	    print RESET;

	   
	    my $ja_text = $_; #decode("UTF-8",$_);
	    $ja_text =~ s/\\u003e/>/;
	    $ja_text =~ s/\\u003c/</;

	    my $change_text =$TD{$_}; #decode("UTF-8",$TD{$_});
	    $change_text =~ s/\\u003e\s*/\>/;
	    $change_text =~ s/\\u003c\s*\/\s*/\<\//;
	    

	    $ja_text =~ s/\\u([A-Fa-f0-9]{4})/\x{$1}/g;
	    $change_text =~ s/\\u([A-Fa-f0-9]{4})/\x{$1}/g;
=asd
	    for ($ja_text =~ /\\u([A-Fa-f0-9]{4})/ )
	    {
		print YELLOW;
		my $char = '\x{'.$1.'}';
		say decode("UTF-8","$char");
		print RESET;
	    }
=cut
#\\x{$1}/g;
	    #$ja_text = decode("UTF-8",$ja_text);
	    $ja_text =~ s/(\(|\)|\[|\]|\*|\.|\+|\|\-|\!)/\\$1/g;
	    print BLUE;
	    say "$ja_text ->\n$change_text";
	    print RESET;
	    if ( $result_text =~ s/$ja_text/$change_text/s ){
		say "replace : \n$ja_text \n-> $change_text";
	    }
	    
	}
	print RESET;
    }
    
    #say $result_text;
    my $chapter = encode("UTF-8",'장');
    $result_text =~ s/&#31456;/ $chapter /g;
    open my $kofh , '>', "$newfileName" or die ( "can not open to file ($newfileName) :$!" );
    print CYAN;
    say "=======================================\nWrited : $newfileName";
    print RESET;
    print $kofh $result_text;# or die (" can not wrte to file ($newfileName) :$!");
    close $kofh;
    #my $a = $pieces_hash{1}{ORIGINAL};
    #if ( $jafile =~ /($a)/){
#	say "Match :$1";
 #   }
    
    #say $jafile;
}

sub piece_parser {
    my ($pieces_file) = $_[0];

    open my $fh , "<" ,  $pieces_file or die ("can not file open :$!");
    
    my %pieces_hash;
    
    while (<$fh>) {
	state $key_count = 0;
	state $cur_tag_key = undef;
	chomp();

	if ( /^<PIECE>$/ ) {
	    $key_count++;
	} 
	else
	{
	    unless ( defined($cur_tag_key) ) {
		if ( /^ <ORIGINAL>$/ ) 
		{
		    $cur_tag_key = "ORIGINAL";
		} elsif ( /^ <\/ORIGINAL>$/ )
		{
		    $cur_tag_key = undef;
		} elsif ( /^ <GOOGLE_RESULT>$/ )
		{
		    $cur_tag_key = "GOOGLE_RESULT";
		} elsif ( /<\/GOOGLE_RESULT>$/ ) 
		{
		    $cur_tag_key = undef;
		}
	    } else {
		if ( /<\/ORIGINAL>/ ) {
		    $cur_tag_key = undef;
		    next;
		}
		$pieces_hash{$key_count}{$cur_tag_key} .= $_ ;
		
		if ( /<\/GOOGLE_RESULT>$/ ) {
		    $pieces_hash{$key_count}{$cur_tag_key} =~ s/ <\/GOOGLE_RESULT>$//s ;
		    $cur_tag_key = undef;
		}
	    }
	}
    }
  
    return %pieces_hash;
    #my %translation_data = google_data_parser($pieces_hash{1}{GOOGLE_RESULT});
}

sub google_data_parser {
    my $pieces_str = $_[0];
    $_ = $pieces_str;
    
#    print MAGENTA,BOLD,"Google result :\n",RESET;
#    print MAGENTA;
#    say $_;
    

#    print YELLOW;
#    say "Extract =====================";

    #구글 데이터를 트리화 시켜 배열로 담아낸다.
    my @tree;
    extracting_to_tree($_,"",\@tree);
    #tree_Traversal(@tree);
    #dump @tree;
    #push @tree,recursive_extract($_,\@tree);
    
    #트리의 노드중 Kr Ja 짝을 가진 노드를 골라 담아낸다
    my %KrJaNodes = extract_KrJaNodes_from_tree(@tree);
#    say "$_ -> $KrJaNodes{$_}" for keys %KrJaNodes;
    
 #   say "Dumping ========= :";
#    say dump (@tree);

#    search_tree(@tree);
    #say @tree;
#    say $_->[0]."\n" for (@tree-);
    print RESET;
    return %KrJaNodes;
}

sub extract_KrJaNodes_from_tree {
    my @tree = @_;

    # 한국어와 일본어 짝을 가진 원소들을 가진 노드를 추출해 해쉬 키(일본어) 값(한국어) 로 담는다.
    my %extractedNodes;

    for ( @tree ) {
	
	my @node_elements = separation_elements_from_node($_);
	
	#print MAGENTA,BOLD,"\nNode:\n",RESET;
	#say $_ for (@node_elements);

	if (decode("UTF-8",$node_elements[0]) =~ /^[^\[].*[가-힌]/ ) {
	    if (defined($node_elements[1]) and  decode("UTF-8",$node_elements[1]) =~ /[…-齢]/ ){
		$extractedNodes{$node_elements[1]} = $node_elements[0];
	    }
	}
=test
	print MAGENTA;
	say $_ for (@node_elements);
	print RESET;
	say $node_elements[0];
	say $node_elements[1];
	print YELLOW;
=cut

    }

    return %extractedNodes;
}

sub separation_elements_from_node {
    my $node_text = shift @_;
    my $separator = ',';
    my @elements;
    
    #ECP : Elements current location pointer
    my $ECLP = 0;

    #BB  : Before Backslash
    #ODQ : Open Double Quote
    my $ODQ = 0;
    my $BB  = 0;
    while ($node_text =~ s/(.)//) {
	given ($1) {
	    when ( '\\' ) {
		$BB = $BB? 0:1;
		$elements[$ECLP] .= $1;
	    }
	    when ( '"' ) {
		unless ($BB) {
		    if ( $ODQ ) {
#			$ECLP++;
			$ODQ = 0;
		    } else {
			$ODQ = 1;
		    }
		}else {
		    $BB = 0;
		    $elements[$ECLP] .= $1;
		}
	    }
	    
	    when ( $separator ) {
		!$ODQ? $ECLP++:next;
	    }
	    
	    default {
		$BB = 0;
		$elements[$ECLP] .= $1;
	    }
	}
    }
    return @elements;
}

# round to tree elements
sub search_tree {
    my @sub_tree = @_;
    
    for (@sub_tree) {
	
	if ( defined( $_ )) {
	    say "Print:";
	    print MAGENTA;
	    say $_;
	    print RESET;
	    
	}else {
	    say "Undefined";
	}
	
    }
}


sub tree_Traversal {
    my @tree = @_;
    
    for (@tree) {
	say $_;
    }
}

sub extracting_to_tree {
    my ($text,$remaining,$tree_ref) = @_;
    my ($e,$r) = extract_text_in_bracket($text,0);
    
    if ( defined( $e ) )
    {
#	$e =~ s#^\[|\]$##g;

	my $re_e = extracting_to_tree($e,"",$tree_ref);
	if ( defined( $re_e ) ) 
	{
	    my @sub_tree = ($re_e);
	    extracting_to_tree($re_e,"",\@sub_tree);
	    unshift $tree_ref,[@sub_tree];
	} else {
	    push $tree_ref,$e;
	}
	
	# re_e_r : re extracting from remaining text
	# re_e_rr : remaining in re extracting from remaining text
	
	if ( defined( $r ) ) {
	    while ( my ($re_e_r,$re_e_rr) = extracting_to_tree($r,"",$tree_ref) ) 
	    {
		$r = $re_e_rr;
		
		if ( defined( $re_e_r ) )
		{
		    
		    my @sub_tree = ($re_e_r);
		    #extracting_to_tree($re_e_r,"",\@sub_tree);
		    unshift $tree_ref,[@sub_tree];
		} else 
		{
		    #push $tree_ref,$re_e_r;
		    last;
		}
	    }
	}
	
	return $e,$r;
    }
    
    return undef;
}


sub extract_text_in_bracket
{
    # text format : ex) [".."]
    # bracket_set : "[]" or "<>" or "()" or ..
    my ($text ,$tracker_on,$bracket_set) = @_;
    
    return (undef,undef) unless defined($text);

    my ($OB,$CB); 
    if ( defined($bracket_set) ) {
	$bracket_set =~ /(.)(.)/ or die("invalid bracket set");
	($OB,$CB) = ($1,$2);
    }else {
	($OB,$CB) = ('[',']');
    }

    # OB  : Open Braket
    # ODQ : Open Double Quotes
    # OQ  : Open Quotes
    # BB  : Before Backslash
    my ( $OB_count, $ODQ_count, $BB, $extracted_text);
    
    while ( $text =~ s/(.)// )
    {
	given ($1) {
	    when ( $OB ) {
		$OB_count++ if !$ODQ_count  and !$BB;
		$BB = 0;
		$extracted_text .= $1 if $OB_count;
		say "OB : $OB_count" if $tracker_on;
	    }
	    when ( '"' ) {
		unless ( $BB ){ 
		    if ( $ODQ_count ) {
			$ODQ_count = 0;
		    }else {
			$ODQ_count = 1;
		    }
		} else {
		    $BB = 0;
		}
		$extracted_text .= $1 if $OB_count;
		say "ODQ : $ODQ_count" if $tracker_on;
	    }
	    when ( $CB ) {
		$OB_count-- if !$ODQ_count and $BB == 0;
		$BB = 0;
		$extracted_text .= $1 if defined($OB_count);# > -1;
		#say "NANA : $OB_count";
		say "$OB_count : $OB_count"  if $tracker_on;
		last unless $OB_count;
	    }
	    when ( '\\' ) {
		if ( $BB  ){
		    $BB = 0;	    
		}else {
		    $BB = 1;
		}
		$extracted_text .= $1 if $OB_count;
	    }
	    default {
		$BB = 0 if $BB ;
		$extracted_text .= $1 if $OB_count;
	    }
	}
	state $full;
	$full .= $1;
	#say $full  if $tracker_on;
	#say $1;
    }
    
    die("is Patal Syntax") if $OB_count or $BB;# or $ODQ_count;
    my $strip_bracket_p = "^\\$OB|\\$CB\$";
    if ( defined( $extracted_text ) ) {
	$extracted_text =~ s#$strip_bracket_p##g;
	
#    say $extracted_text;
#    say $1;
	# return ( Extracted text , Remaining text )
	return ($extracted_text ,$text);
    }else {
	return (undef,undef);
    }
    
}
