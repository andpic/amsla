#!/bin/bash

$1/bin/matlab -nodesktop -nodisplay -r "cd test/matlab; a2mslaTests(); exit;"
