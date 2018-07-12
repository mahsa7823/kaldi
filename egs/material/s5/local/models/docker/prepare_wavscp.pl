#!/usr/bin/env perl

use File::Basename;
use File::Spec;

my ($wavscp, $dir) = @ARGV;

open F, "< $wavscp";

%supported = ("wav", 1, "sph", 1, "flac", 1);

while (<F>) {
  chomp();

  $pipe = 0;
  if (s/\s*\|\s*$/ |/) { # pipe
     $pipe = 1;
  }
	
  @f = split;
  ($audio, $aidx)=();
  for ($i=0; $i < @f; $i++) {
      if ($f[$i] =~ /\.([a-z]+)$/) {
	  $ext = $1;
	  if (defined($supported{$ext}) && -f $f[$i]) {
	      $audio = $f[$i];
	      $aidx = $i;
	      last;	      
	  }
      }
  }
  if (!defined($audio)) {
      print STDERR "Cannot find valid audio file: '@f'\n";
      next;
  }


  # rewrite for docker
  $name = basename($audio);
  $f[$aidx]="/data/audio/$name";

  # if the audio is already in the ingest directory, don't copy!!!!
  if (File::Spec->rel2abs( $audio ) ne File::Spec->rel2abs( "$dir/$name" ) ) {
      system ("cp $audio $dir/$name");
  }

  print "@f\n";
  $files++;
  
}

if ($files < 1) {
   exit(1);
}

  
