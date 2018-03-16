#!/usr/bin/env python
# Copyright (c) 2018, Johns Hopkins University (Jonathan Wintrode <jonathan.wintrode@gmail.com>)
# License: Apache 2.0

import sys
import os
from shutil import copyfile

# recursively rewrite a config file an its dependencies
def rewrite(file, confdir, fdir) :
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

                    
        if (os.path.isfile(val)) :
            name = os.path.basename(val)
            if ( val.endswith(".conf")) :
                out.write("%s=__confdir__/%s\n" % (flag, name))
                rewrite(val, confdir, fdir)
            else :
                if (not os.path.isfile(fdir + "/" + name)) :
                    copyfile(val, fdir + "/" + name)
                out.write("%s=__modeldir__/%s\n" % (flag, name))
        else :
            out.write(l + "\n")

    f.close()
    out.close()

if (len(sys.argv) < 3) :
    sys.err.write("Usage: rewrite_config.py config-file output-dir\n")
    sys.exit(1)

    
(config, confdir, filedir) = sys.argv[1:]

name = os.path.basename(config)

print("# rewriting %s\n" % (config))

rewrite(config, confdir, filedir)


