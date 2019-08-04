#!/bin/bash

$1/bin/matlab -nodesktop -nodisplay -r "cd test/matlab/shared; a2mslaTests(); exit;"
