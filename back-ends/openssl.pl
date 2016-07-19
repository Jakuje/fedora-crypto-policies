#!perl

require 5.000;
use strict;

use profiles::common;

use File::Temp qw/ tempfile /;
use File::Copy;

my $print_init = 0;
my $string     = '';

sub append {
	my $arg = $_[0];
	return if $arg eq '';

	if ( $print_init != 0 ) {
		$string .= ':';
	}
	$string .= $arg;
	$print_init = 1;
}

my %cipher_not_map = (
	'SEED-CBC'  => '!SEED',
	'IDEA-CBC'  => '!IDEA',
	'DES-CBC'   => '!DES',
	'RC4-40'    => '',
	'DES40-CBC' => '',
	'3DES-CBC'  => '!3DES',
	'RC4-128'   => '!RC4',
	'RC2-CBC'   => '!RC2',
	'NULL'      => '!eNULL:!aNULL'
);

my %key_exchange_map = (
	'RSA'       => 'kRSA',
	'ECDHE'     => 'kEECDH',
	'DHE'       => 'kEDH',
	'PSK'       => 'kPSK',
	'DHE-PSK'   => 'kDHEPSK',
	'ECDHE-PSK' => 'kECDHEPSK'
);

my %key_exchange_not_map = (
	'ANON'       => '',
	'DH'         => '',
	'ECDH'       => '',
	'EXPORT' => '!EXP',
	'DHE'        => 'kEDH'
);

my %mac_not_map = ( 'HMAC-MD5' => '!MD5' );

sub generate_temp_policy() {
	my $profile = shift(@_);
	my $dir     = shift(@_);
	my $libdir  = shift(@_);

	if (!-e "$libdir/profiles/$profile.pl") {
		print STDERR "Cannot file $profile.pl in $libdir/profiles\n";
		exit 1;
	}
	do "$libdir/profiles/$profile.pl";

	$string = '';
	$print_init = 0;

	foreach (@key_exchange_list) {
		my $val = $key_exchange_map{$_};
		if ( defined($val) ) {
			append($val);
		}
		else {
			print STDERR "openssl: unknown: $_\n";
		}
	}

	foreach (@key_exchange_not_list) {
		my $val = $key_exchange_not_map{$_};
		if ( defined($val) ) {
			append($val);
		}
		else {
			print STDERR "openssl: unknown: $_\n";
		}
	}

	foreach (@cipher_not_list) {
		my $val = $cipher_not_map{$_};
		if ( defined($val) ) {
			append($val);
		}
		else {
			print STDERR "openssl: unknown: $_\n";
		}
	}

	foreach (@mac_not_list) {
		my $val = $mac_not_map{$_};
		if ( defined($val) ) {
			append($val);
		}
		else {
			print STDERR "openssl: unknown: $_\n";
		}
	}

	append('!SSLv2');

	return $string;
}

sub test_temp_policy() {
	my $profile = shift(@_);
	my $dir     = shift(@_);
	my $gstr    = shift(@_);

	if (-e "/usr/bin/openssl") {
		my ( $fh, $filename ) = tempfile();
		print $fh $gstr;
		close $fh;
		system("openssl ciphers `cat $filename` >/dev/null");
		my $ret = $?;
		unlink($filename);

		if ( $ret != 0 ) {
			print STDERR "There is an error in openssl generated policy\n";
			print STDERR "policy: $gstr\n";
			exit 1;
		}
	}
}

1;