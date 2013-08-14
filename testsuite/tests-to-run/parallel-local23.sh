#!/bin/bash

rm -rf tmp 2>/dev/null
cp -a input-files/testdir2 tmp

cat <<'EOF' | sed -e 's/;$/; /;s/$SERVER1/'$SERVER1'/;s/$SERVER2/'$SERVER2'/' | stdout parallel -j0 -k -L1
echo '### Test filenames containing UTF-8'; 
  cd tmp; 
  find . -name '*.jpg' | parallel -j +0 convert -geometry 120 {} {//}/thumb_{/}; 
  find |grep -v CVS | sort; 

echo '### bug #39554: Feature request: line buffered output'; 
  parallel -j0 --linebuffer 'echo -n start {};sleep 0.{#};echo middle -n {};sleep 1.{#}5;echo next to last {};sleep 1.{#};echo -n last {}' ::: A B C
echo

echo '### bug #39554: Feature request: line buffered output --tag'; 
  parallel --tag -j0 --linebuffer 'echo -n start {};sleep 0.{#};echo middle -n {};sleep 1.{#}5;echo next to last {};sleep 1.{#};echo -n last {}' ::: A B C
echo

echo '### test round-robin';
  seq 1000 | parallel --block 1k --pipe --round-robin wc | sort

echo '### --version must have higher priority than retired options'
   parallel --version -g -Y -U -W -T | tail

EOF

rm -rf tmp
