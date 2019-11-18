#!/bin/bash

/usr/local/bin/matlab -nodesktop -nodisplay -r "cd test/matlab/shared; runAllAmslaTests(); exit;"
