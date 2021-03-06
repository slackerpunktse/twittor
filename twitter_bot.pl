#!/usr/bin/perl

# -- stolen and appropriated at around lunchtime,
# lives in #slacker.se and serves that channel's nefarious purposes --


# Twitter IRC Bot
# This bot is one way communication with twitter.
# originally written by harper?

# to use just edit the bot and change the twitter username and pass. 
# then set it up in a channel

# then to send an update type:
# twittor: update text.

# thanks to b0iler for his page "Bare Bones IRC Bot In Perl"
# http://b0iler.eyeonsecurity.org/tutorials/ircperlbot.htm
# this script is largely based upon his barebones framework

use LWP::Simple;
use LWP::UserAgent;
use HTML::TokeParser;
use IO::Socket;
use URI::Escape;

# configure variables
my $ircserver = "irc.inet.tele.dk";

my $ircchannel = "#slacker.se";
my $nickname = "twittor";
#my $ircchannel = "#status.slacker.se";
#my $nickname = "achterr";

my $username = "SSE";
my $twituser = "slackerpunktse";
my $twitpass= "";

my $helpmessage = "jag aer cornholio!, ein twitterupdateringsbot. skriv 'twittor: hej!' och jag lovar att det hamnar haer: http://twitter.com/slackerpunktse";

my $browser = LWP::UserAgent->new;

# connect to the IRC server
$sock = IO::Socket::INET->new(
        PeerAddr => $ircserver,
        PeerPort => 6667, 
        Proto => 'tcp' ) or die "could not make the connection";
        
while($line = <$sock>){
        print $line;
        if($line =~ /(NOTICE AUTH).*(checking ident)/i){
                print $sock "NICK $nickname\nUSER $username 0 0 :twittrin\n";
                last;
        }
}

while($line = <$sock>){
        print $line;    
        #use next line if the server asks for a ping
        if($line =~ /^PING/){
                print $sock "PONG :" . (split(/ :/, $line))[1];
        }
        if($line =~ /(376|422)/i){
                #print $sock "NICKSERV :identify nick_password\n";
                last;
        }
}

sleep 3;

# join the channel
print $sock "JOIN $ircchannel \n";

# main loop
print "/------------------------------------------------------------------------\n";
print "| Twitter IRC Bot \n";
print "|----------------------------------------------\n";
print "|\n";
while ($line = <$sock>) {
        #$text is the stuff from the ping or the text from the server
        ($command, $text) = split(/ :/, $line);   
        if ($command eq 'PING'){
                #while there is a line break - many different ways to do this
                while ( (index($text,"\r") >= 0) || (index($text,"\n") >= 0) ){ chop($text); }
                print $sock "PONG $text\n";
                next;
        }
        #done with ping handling
        
        ($nick,$type,$channel) = split(/ /, $line); #split by spaces
        
        ($nick,$hostname) = split(/!/, $nick); #split by ! to get nick and hostname seperate
        
        $nick =~ s/://; #remove :'s
        #$text =~ s/://;
        
        #get rid of all line breaks.  Again, many different way of doing this.
        $/ = "\r\n";
        while($text =~ m#$/$#){ chomp($text); }
	
        
        if($channel eq $ircchannel){
                print "<$nick> $text\n";
				if($text =~ /^!twitterhelp(.*)/) {
				  print $sock "PRIVMSG $ircchannel :* ".$helpmessage."\n";
				}

				# post an update
				if ( ($text =~ /^twittor: (.*)/) or ($text =~  /^ACTION (.*)/) ){
				  my $txt = $1;

				  my $update = ""; 
				  if ($text =~ /^ACTION /) {
					# this clearly does not work.
					$update = "* ".$nick." ".$txt;
				  } else {
					$update = "[".$nick."] ".$txt;
				  }
				  
				  $update =~ s/</[/g;
				  $update =~ s/>/]/g;
				  my $delurl = "http://" . $twituser . ":" . $twitpass ."\@twitter.com/statuses/update.xml?status=". urlencode($update);
				  print "URL: $delurl";
				  my $response = $browser->post( $delurl );
				  my $responsetext = $response->content;
				  print $responsetext;
				  if ($responsetext =~ /\<created_at\>/){
					#print $sock "PRIVMSG $ircchannel :* Twitter updated: ".$update."\n";
				  }else{
					print $sock "PRIVMSG $ircchannel :* Twitter update failed\n" ;
				  }
				  $responsetext = "";
				  $update = "";
				  # end of post
                }
				
				# do not post an update, but do help moln out.
				if ( ($nick == "moln") and ($text =~ /!twittor: (.*)/) ) {
				  sleep(2); # simulate thought.
				  print $sock "PRIVMSG $ircchannel :ja men kristina, visst menar du 'twittor: "+$1+"'?";
				}
        }
}


###########
# subroutine: urlencode a string
###########

sub urlencode {

my $ask = shift @_;
my @a2 = unpack "C*", $ask;
my $s2 = "";
while (@a2) {
    $s2 .= sprintf "%%%X", shift @a2;
}
return $s2;

}
