#!/bin/bash -x

# Argument can be substring of tests (such as 'local')

export LANG=C
SHFILE=/tmp/unittest-parallel.sh
MAX_SEC_PER_TEST=900
export TIMEOUT=$MAX_SEC_PER_TEST

run_test() {
  script="$1"
  base=`basename "$script" .sh`
  if [ "$TRIES" = "3" ] ; then
    # Try 3 times
    bash $script > actual-results/$base
    diff -Naur wanted-results/$base actual-results/$base >/dev/null ||
      bash $script > actual-results/$base
    diff -Naur wanted-results/$base actual-results/$base >/dev/null ||
      bash $script > actual-results/$base
    diff -Naur wanted-results/$base actual-results/$base ||
      (touch $script && echo touch $script)
  else
    # Run only once
    bash $script > actual-results/$base
    diff -Naur wanted-results/$base actual-results/$base ||
      (touch $script && echo touch $script)
  fi

  # Check if it was cleaned up
  find /tmp -maxdepth 1 |
    perl -ne '/\.(tmx|pac|arg|all|log|swp|loa|ssh|df|pip|tmb|chr|tms|par)$/ and ++$a and print "TMP NOT CLEAN. FOUND: $_".`touch '$script'`;'
  # May be owned by other users
  sudo rm -f /tmp/*.{tmx,pac,arg,all,log,swp,loa,ssh,df,pip,tmb,chr,tms,par}
}
export -f run_test

date
mkdir -p actual-results
ls -t tests-to-run/*${1}*.sh | grep -v ${2} |
  stdout parallel --tty -tj1 run_test | tee testsuite.log
# If testsuite.log contains @@ then there is a diff
if grep -q '@@' testsuite.log ; then
  false
else
  # No @@'s: So everything worked: Copy the source
  rm -rf src-passing-testsuite
  cp -a ../src src-passing-testsuite
fi
rm testsuite.log
date
