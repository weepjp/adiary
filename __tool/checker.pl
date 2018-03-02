#!/usr/bin/perl
use 5.8.0;
use strict;
use Encode;
use Encode::Guess qw(ascii euc-jp shiftjis iso-2022-jp);
###############################################################################
# Perl Compile Checker
###############################################################################
my $perl = $ARGV[0] || "/usr/bin/perl";
my $opt  = "-I./lib";

print "---adiary Compile checker-------------------------------------------\n";
#------------------------------------------------------------------------------
{
	open(my $fh, "$perl -v|");
	my @lines = <$fh>;
	close($fh);
	
	foreach(@lines) {
		if ($_ !~ /version/) { next; }
		print "$_";
		last;
	}
}
#------------------------------------------------------------------------------
{
	open(my $fh, "find plugin/ lib/ -name *.pm |");
	my @files = <$fh>;
	close($fh);

	foreach(@files) {
		chomp($_);
		system("$perl $opt $_");
	}
}
print "\n";

###############################################################################
# adiary Release checker
###############################################################################
my $errors=0;
print "---adiary Release checker-------------------------------------------\n";
#------------------------------------------------------------------------------
# Debug check
#------------------------------------------------------------------------------
{
	open(my $fh, 'grep -ERni "debug\(|#\s*debug" skel/ lib/ plugin/ |');
	my @ary = <$fh>;
	close($fh);

	foreach(@ary) {
		my ($file, $linenum, $line) = split(/:/, $_, 3);
		if ($file !~ /\.(?:pm|html)$/) { next; }
		if ($line =~ /^\s*#/) { next; }
		if ($line =~ /{DEBUG}/) { next; }
		if ($line =~ /#\s*debug-safe/) { next; }
		if ($line =~ /{Debug_mode}/) { next; }

		print "## Debug error : $file\n";
		print "$linenum:$line";
		$errors++;
	}
}
{
	open(my $fh, 'grep -ERni "alert\s*\(" js/|fgrep -v ".min.js"|');
	my @ary = <$fh>;
	close($fh);
	
	foreach(@ary) {
		my ($file, $linenum, $line) = split(/:/, $_, 3);
		if ($file !~ /\.js$/) { next; }
		if ($line =~ m!s*//!) { next; }
		if ($line =~ m!//\s*(?:alert|debug)-safe!) { next; }

		print "## Debug error : $file\n";
		print "$linenum:$line";
		$errors++;
	}
}

#------------------------------------------------------------------------------
# &nbsp; check
#------------------------------------------------------------------------------
{
	open(my $fh, "grep -ERni '&nbsp;' skel/ js/*.js plugin/ theme/|");
	my @ary = <$fh>;
	close($fh);

	my %files;
	foreach(@ary) {
		my ($file, $linenum, $line) = split(/:/, $_, 3);
		print "## '&nbsp;' warning : $file\n";
		print "$linenum:$line";
	}
	foreach(sort(keys(%files))) {
		print "## CRLF warning : $_\n";
	}
}

#------------------------------------------------------------------------------
# CRLF check
#------------------------------------------------------------------------------
{
	open(my $fh, "grep -r '\r\n' skel/ js/*.js lib/ info/ plugin/ theme/|");
	my @ary = <$fh>;
	close($fh);

	my %files;
	foreach(@ary) {
		my ($file, $line) = split(/:/, $_, 2);
		if ($line =~ /\r\n/) {
			$files{$file} = 1;
		}
	}
	foreach(sort(keys(%files))) {
		print "## CRLF warning : $_\n";
	}
}

#------------------------------------------------------------------------------
# BOM check
#------------------------------------------------------------------------------
{
	open(my $fh, "grep -r '\xEF\xBB' skel/ js/*.js lib/ info/ plugin/|");
	my @ary = <$fh>;
	close($fh);
	foreach(@ary) {
		print "## BOM warning : $_\n";
	}
}

#------------------------------------------------------------------------------
# 文字コードcheck
#------------------------------------------------------------------------------
{
	open(my $fh, "find skel/ js/ lib/ info/ plugin/ theme/|");
	my @files = <$fh>;
	close($fh);

	foreach(@files) {
		chomp($_);
		if (-d $_) { next; }
		if ($_ !~ /\.(pm|html|css|info|dat|txt)$/) { next; }

		open(my $fh, $_);
		my @lines = <$fh>;
		close($fh);
		my $str  = join('', @lines);
		my $code = guess_encoding($str);
		if (!$code) { next; }	# 推定できず
		
		if (ref($code)) { $code = $code->name(); }
		if ($code eq 'utf8' || $code eq 'ascii') { next; }

		# shiftjis or utf8 / utf8 or shiftjis
		if ($code =~ /utf8/) { next; }

		print "## code error : $code $_ \n";
		$errors++;
	}
}

#------------------------------------------------------------------------------
# CHANGES.txt check
#------------------------------------------------------------------------------
{
	open(my $fh, "CHANGES.txt");
	my @files = <$fh>;
	close($fh);

	foreach(@files) {
		chomp($_);
		if ($_ !~ m|/xx|) { next; }

		print "## CHANGES.txt error : $_ \n";
		$errors++;
	}
}

#------------------------------------------------------------------------------
# exit
#------------------------------------------------------------------------------
{
	if ($errors) {
		print "\n## Total $errors errors.\n";
	} else {
		print "## error not found.\n";
	}
}
