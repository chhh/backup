use File::Copy;
use File::Path;
use Cwd qw/abs_path/;
use Getopt::Std qw/getopts/;

%opts=();
getopts('hdacf:', \%opts) or usage();
#usage() if $opt{h};
#usage() if !$opt{f};

my $start_dir = $opts{f};
my $abs_dir_path = abs_path($start_dir);
if ($abs_dir_path =~ /(.*)\//) {
	$abs_dir_path = $1;
} else {
	die "Didn't do anything because of problems with absolute directroy path resolution.\n";
}

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
my $timestamp = sprintf "%4d-%02d-%02d__%02d-%02d", $year+1900,$mon+1,$mday,$hour,$min;
my $archive_filename = $start_dir.'_['.$timestamp.']';
if ($opts{s}) {
	$archive_filename .= '_['.$opts{s}.']'
}


$path = "$abs_dir_path/$archive_filename";
if (-d $path) {
	if($opts{d}) {
		print "Backup directory already exists.\n   Deleting...\n";
		rmtree($path);
	} else {
		die "Backup directory already exists. Exiting.\n";
	}
}
if (-f "$path.rar") {
	if($opts{d}) {
		print "Backup archive already exists.\n   Deleting...\n";
		unlink("$path.rar");
	} else {
		die "Backup archive already exists. Exiting.\n";
	}
}
if (!mkdir($path)) {
	die "Error: couldn't create directory '$path'\n";
}

# here we copy the whole directory structure
if ($opts{c}) {
	&traverse("$abs_dir_path/$start_dir");
}

# and archive it, if the user has so desired
if ($opts{a}) {
	use Archive::Rar;
	my $rar =new Archive::Rar();
	$rar->Add(
			-archive => $archive_filename,
			-files => $start_dir,
			-verbose => 0
	);
}
 
sub traverse() {
	my $dir = shift;
	opendir(DIR, $dir) || die "can't opendir '$dir': $!";
    my @dirs = grep { !/^\./ && -d "$dir/$_" } readdir(DIR);
	rewinddir(DIR);
	my @files = grep { !/^\./ && -f "$dir/$_" } readdir(DIR);
	closedir(DIR);
	foreach my $file (@files) {
		copy("$dir/$file", "$path/$file") or die "File\n   '$dir/$file' could not be copied to\n   $path/$file\nError: $!.";
	}
	foreach my $inner_dir (@dirs) {
		local $path = $path . '/' . $inner_dir;
		if (!mkdir($path)) {
			warn "Error: couldn't create subdirectory '$path'\n";
		}
		&traverse("$dir/$inner_dir");
	}
}



sub usage()
{

print STDERR << "EOF";

This script copies your dir and optionally archives

usage: backup.pl [-dac] [-f direcotry_path]

 -h 		  : help
 -d        	  : delete the directory and archive if they already exist
 -a        	  : archive created copy
 -c			  : create a full dir copy
 -f dir_path  : directory path to be backed up


EOF
	exit;
}