#!/bin/bash

export SQLITE=sqlite3:///%2Frun%2Fshm%2Fparallel.db
export PG=pg://`whoami`:`whoami`@lo/`whoami`
export MYSQL=mysql://`whoami`:`whoami`@lo/`whoami`

export DEBUG=false

p_showsqlresult() {
  SERVERURL=$1
  TABLE=$2
  sql $SERVERURL "select Host,Command,V1,V2,Stdout,Stderr from $TABLE order by seq;"
}

p_wrapper() {
  INNER=$1
  SERVERURL=$(eval echo $2)
  TABLE=TBL$RANDOM
  DBURL=$SERVERURL/$TABLE
  T1=$(tempfile)
  T2=$(tempfile)
  eval "$INNER"
  echo Exit=$?
  wait
  echo Exit=$?
  $DEBUG && sort -u $T1 $T2; 
  rm $T1 $T2
  p_showsqlresult $SERVERURL $TABLE
  $DEBUG || sql $SERVERURL "drop table $TABLE;" >/dev/null
}

p_template() {
  (sleep 2; parallel "$@" --sqlworker $DBURL sleep .3\;echo >$T1) &
  parallel "$@" --sqlandworker $DBURL sleep .3\;echo ::: {1..5} ::: {a..e} >$T2; 
}
export -f p_template

par_sqlandworker() {
  p_template
}

par_sqlandworker_lo() {
  p_template -S lo
}

par_sqlandworker_results() {
  p_template --results /tmp/out--sql
}

par_sqlandworker_linebuffer() {
  p_template --linebuffer
}

par_sqlandworker_tag() {
  p_template --tag
}

par_sqlandworker_linebuffer_tag() {
  p_template --linebuffer --tag
}

par_sqlandworker_compress_linebuffer_tag() {
  p_template --compress --linebuffer --tag
}

par_sqlandworker_unbuffer() {
  p_template -u
}


export -f $(compgen -A function | egrep 'p_|par_')
# Tested that -j0 in parallel is fastest (up to 15 jobs)
compgen -A function | grep par_ | sort |
  stdout parallel -vj5 -k --tag --joblog /tmp/jl-`basename $0` p_wrapper \
    :::: - ::: \$MYSQL \$PG \$SQLITE
