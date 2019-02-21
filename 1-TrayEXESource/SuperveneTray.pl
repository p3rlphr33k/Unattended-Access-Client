#!perl
use Win32;
use PerlTray;
use LWP::Simple;
use Tk;			# GUI Module
use Tk::PNG;		# GUI Image Module

$host    = 'supervene.com';
$username = Win32::LoginName;
$pcname = $ENV{'ComputerName'};
$ip = get('http://supervene.com/cgi-bin/getmyip/frontIP.pl');
$offline = 'offline';

open(ACCT, "< acct.cfg");
$ACCTDATA = <ACCT>;
close(ACCT);

($account,$password) = split(/::/, $ACCTDATA);

sub UserInput {
$file2   = 'finalize.png';	# Window logo
$mw  = MainWindow->new;		# Create window
$mw -> minsize( qw(300 300) );	# Minimum WxL size
$mw -> maxsize( qw(300 300) );	# Minimum WxL size
$mw -> title('Supervene Remote Access Settings');	# windows title
$mw -> geometry('400x600');			# Starting WxL
$fav = $mw->Photo(-file=>'sv.png', -format=>'png');	# Favicon image
$mw->Icon(-image => $fav);					# set favicon

$can = $mw->Canvas( -width => 300, -height => 100 )->pack();	# Create image canvas for blue banner
$img2 = $mw->Photo( -file => $file2, -format => 'png', -palette => '256/256/256' );	# logo palette
$can->createImage( 0, 0, -image => $img2, -anchor => 'nw',-tags=>['button'] );		# display logo
$Buttons = $mw->Frame()->pack(-side=>'bottom', -fill=>'both');		# create frame botton buttons

#####################
##connect tab data
#####################
$f1 = $mw->Frame()->pack(-side =>'top', -fill=>'both', -pady=>20, -padx=>20);				# create connect tab frame						# server input grid right
$f1->Label(-text => 'Username:')->grid($f1->Entry(-background=>'#ffffff',-textvariable => \$account),  # user lable grid left
	-sticky => 'w', -padx => 2, -pady => 5);							# user input grid right
$f1->Label(-text => 'Password:')->grid($f1->Entry(-show =>'*',-background=>'#ffffff',-textvariable => \$password), 	# password label grid left
	-sticky => 'w', -padx => 2, -pady => 5);									# password input grid right
$f1->Button(-text => 'Save', -command=>\&checkData)->grid( -pady => 25, -padx=>5);			# connect button blank grid right

##################
##START MAIN LOOP
##################
MainLoop;	# start program
}

# check connect data
sub checkData {
open(ACCT, "> acct.cfg");
print ACCT $account."::".$password;
close(ACCT);

$mw -> messageBox(-type=>"ok", -message=>"Settings Saved.\n");
}

sub PopupMenu {
    return [
		["*Supervene.com - Home", "Execute 'http://supervene.com'"],
		["Remote Support Website", "Execute 'http://supervene.com/rs'"],
		["My IP: $ip", "Execute 'http://supervene.com/getmyip'"],
		["--------"],
		["Remote Access Settings", sub { &UserInput; }],
		["Force Check Status", sub { $offline='offline'; &Service; }],
	    ["--------"],
	    ["  E&xit", "exit"],
	   ];
}

sub ToolTip { $time = localtime, "Supervene Remote Access\n$time\n" }

sub TimeChange {
    Balloon(scalar localtime, "System Time Changed", "Info", 5);
}

sub show_online {
	$offline = 'online';
	SetIcon('online');
    Balloon("Online with Supervene.com", "Supervene Status", "Information", 5);
}

sub show_offline {
	$offline = 'offline';
	SetIcon('offline');
    Balloon("Failed to reach Supervene.com", "Supervene Status", "Error", 15);
}

sub Service {
	$data = "hostname=$pcname&username=$username&email=$account&pwd=$password";
	$p = get("http://www.supervene.com/cgi-bin/rs/checkin.pl?$data");
	if ($p) { 
		
		@p = split(/&/, $p);
		foreach $kv (@p)
			{
			($k, $v) = split(/=/, $kv);
			if($k =~ /status/) {
				if($v =~ /ONLINE/) {
					if($offline eq 'offline') {
						&show_online;
					} 
				}
				else {
						&show_offline;
					}
				}
				if($k =~ /execute/) {
					$pid = fork();
					if( $pid == 0 ) {
						$job = `$v`;
						return 1;
						exit 0;
					}				
				}
			}
	}
	else {
		&show_offline;
	}
}

SetIcon('wait');

&Service;

SetTimer (":60", \&Service);