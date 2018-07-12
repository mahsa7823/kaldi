#!/usr/bin/env python
# Copyright (c) 2018, Johns Hopkins University (Jonathan Wintrode <jonathan.wintrode@gmail.com>)
# License: Apache 2.0

import sys
import os
from shutil import copyfile
import argparse



# recursively rewrite a config file an its dependencies
def rewrite(file, confdir, fdir, root=None) :
    name = os.path.basename(file)    
    out = open(confdir+ "/" + name, 'w')
    f=open(file, 'r')
    
    for l in f :
        if (l.startswith('#')) :
            out.write(l);
            continue

        l = l.strip()
        x = l.split("=",1)
        if (len(x) != 2) :
            sys.stderr.write("Invalid config file, %s: expecting key=val\n"%(file));
            return False
        (flag, val)=x

                    
        if (os.path.isfile(val) or (root is not None and os.path.isfile(root + "/" + val))) :
            if root is not None and not val.startswith("/") :
                val = root + "/" + val
                        
            name = os.path.basename(val)
            if ( val.endswith(".conf")) :
                out.write("%s=__confdir__/%s\n" % (flag, name))
                rewrite(val, confdir, fdir, root=root)
            else :
                if (not os.path.isfile(fdir + "/" + name)) :
                    copyfile(val, fdir + "/" + name)
                out.write("%s=__modeldir__/%s\n" % (flag, name))
        else :
            out.write(l + "\n")

    f.close()
    out.close()

parser = argparse.ArgumentParser()
parser.add_argument("config", help="echo the string you use here")
parser.add_argument("confdir", help="echo the string you use here")
parser.add_argument("filedir", help="echo the string you use here")
parser.add_argument("-r", "--root", help="echo the string you use here", default=None)

args=parser.parse_args()
    
name = os.path.basename(args.config)

print("# rewriting %s\n" % (args.config))

rewrite(args.config, args.confdir, args.filedir, root=args.root)


