#!/bin/bash
# This file is managed by puppet! Do not change!
# get parameters
CFGFILE="$1"

# do some sanity checks
if [ ! -f "${CFGFILE}" ] ; then
  # check for valid parameters
  echo "usage: $0 <configfile>" 1>&2
  exit 1
fi

########### the real workhorse
# usually nothing below needs changes
PATH="/bin:/usr/bin:/sbin:/usr/sbin"

# source config file
. ${CFGFILE}

# run repository update
log=$(mktemp)
echo $(date) >${log}

# do some sanity checks
if [ -z "${REPODESTBASE}" ] ; then
  # check for valid repository url
  echo "${REPODESTBASE} is empty" >>$log
else
  # define needed variables
  createrepo_options="--workers ${WORKERS} --update"
  for arch in ${ARCHS} ; do
    for release in ${RELEASES} ; do
      # use sha1 hash for centos <= 5
      createrepo_options_release=${createrepo_options}
      if [ "${release}" == "all" ] || [ ${release:0:1} -le 5 ] ; then
        createrepo_options_release="${createrepo_options_release} -s sha"
      fi

      # create new local repository directory
      repodest="${REPODESTBASE}/${REPONAME}/${release}/${arch}"
      if [ ! -d "${repodest}" ] ; then
        echo "INFO: creating new repository ${repodest}" >>$log
        mkdir -p ${repodest}
      fi

      # create temporary repo file
      baseurl=$(echo ${BASEURL} | sed "s/%RELEASE%/${release}/g" | sed "s/%ARCH%/${arch}/g")
      repofile=$(mktemp)
      cat << EOF > ${repofile}
[${REPONAME}]
name=${REPONAME} - temporary reposync file
baseurl=${baseurl}
gpgcheck=${GPGCHECK}
gpgkey=${GPGKEY}
EOF

      # download packages and rebuild repo
      echo "Syncing local repository ${repodest}" >>$log
      syncoptions=""
      if [ "${DOWNLOAD_COMPS}" == "true" ] ; then
        syncoptions="${syncoptions} --downloadcomps"
      fi
      if [ "${DOWNLOAD_NEWEST_ONLY}" == "true" ] ; then
        syncoptions="${syncoptions} --newest-only"
      fi
      if [ "${DELETE_NONEXISTENT}" == "true" ] ; then
        syncoptions="${syncoptions} --delete"
      fi
      if [ ! -z "${arch}" ] ; then
        syncoptions="${syncoptions} -a ${arch}"
      fi
      reposync ${syncoptions} --norepopath --download_path=${repodest} -c ${repofile} -r ${REPONAME} >>${log} 2>&1

      # create repository
      groupfile=$(find ${repodest} -name "*comps.xml")
      if [ -f "${groupfile}" ] ; then
        createrepo ${createrepo_options_release} -g ${groupfile} ${repodest} >>${log} 2>&1
      else
        createrepo ${createrepo_options_release} ${repodest} >>${log} 2>&1
      fi

      # cleanup temp file
      rm -f ${repofile}
    done
  done
fi

# mail status report
echo -e "\n\nFinished at $(date)" >>$log
mail -s "${CFGFILE} local mirror update" ${MAILTO} < ${log}

# cleanup log
rm -f ${log}

exit 0
