#!/bin/bash

DEPLOYDEST=~/Repositories/BauDi/baudiPackages
WORKINGDIR=/tmp
BRANCH=$1

# GIT Repos on MRI git server
#LOCAL_PACKAGES=(portal-app)
REMOTE_PACKAGES=(https://github.com/Baumann-Digital/portal-app.git)

buildxar(){
    GIT_URL=$1
    git clone  --branch $BRANCH $GIT_URL
    CURRENT=$(basename "$GIT_URL" | cut -f 1 -d '.')
    cd $CURRENT
    VERSION=$(git describe)
    
    if [ -d "dataPackage" ]
    then
        sed -e "s/VERSION/$VERSION/g" -i '' dataPackage/expath-pkg.xml
    else
        sed -e "s/VERSION/$VERSION/g" -i '' expath-pkg.xml
    fi
    ant copy-xar -Dxar.destination=$DEPLOYDEST
    cd $WORKINGDIR
    rm -Rf $WORKINGDIR/$CURRENT
}

cd $WORKINGDIR

#for PACKAGE in "${LOCAL_PACKAGES[@]}"
#do
#   buildxar https://reger-max.mri.intern/git/$PACKAGE
#done

for PACKAGE in "${REMOTE_PACKAGES[@]}"
do
   buildxar $PACKAGE
done
