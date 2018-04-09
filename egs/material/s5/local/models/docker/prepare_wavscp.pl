#!/usr/bin/env perl

use File::Basename;

my ($wavscp, $dir) = @ARGV;

open F, "< $wavscp";

while (<F>) {
  chomp();

  $pipe = 0;
  if (s/\s*\|\s*$//) { # pipe
     $pipe = 1;
  }
	
  @f = split;
  $audio = pop @f;
  $name = basename($audio);
  system ("cp $audio $dir/$name");
  if ($pipe) {
    print "@f /data/audio/$name |\n";
  }
  else {
    print "@f /data/audio/$name\n";
  }
}

  
