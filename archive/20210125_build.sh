#!/bin/sh -ex

_outH1() {
    echo
    echo "# $1"
    echo
}

_pkgBuild() {
    _pwd=$(pwd)
    cd $1

    # Install compiled make dependencies
    if [ -e "makedepends" ];
	then
	sudo pacman --noconfirm -U makedepends/*.pkg.*
    fi

    makepkg --ignorearch --syncdeps --clean --cleanbuild --force --noconfirm --skipinteg

    # in case there's nothing to copy, don't fail
    cp -n *.pkg.* /build-target || true

    # Install packages separately.
    # When building multiple packages with different version numbers and in one PKGBUILD,
    # on the end makepkg tries to install all packages with the last version number
    sudo pacman --noconfirm -U *.pkg.*

    cd ${_pwd}
}

_pkgSync() {
    _pwd=$(pwd)
    _makepkg=$(realpath ${1})

    cd ${_makepkg}
    makepkg --printsrcinfo > .SRCINFO
    eval local $(grep -o -m 1 '^\s*pkgname\s*=\s*.*' PKGBUILD)

    cd ${_pwd}
    _syncPath="makepkgs-sync/${pkgname}"
    if ! git clone http://aur.archlinux.org/${pkgname}.git ${_syncPath} ;
    then
	echo "Clone failed ${pkgname}"
	return $?
    fi

    cd ${_syncPath}
    find  ./ -maxdepth 1 -mindepth 1 -not -name ".git*" -exec rm -rf {} \;
    cp -RT ${_makepkg} .
    git add -A || true
    git commit -a -m "next iteration" || true

    cd ${_pwd}
}

_pkgPush() {
    _pwd=$(pwd)
    _makepkg_sync=$(realpath ${1})

    cd ${_makepkg_sync}
    git remote set-url origin ssh://aur@aur.archlinux.org/$(basename ${_makepkg_sync}).git
    git push
    cd ${_pwd}
}

_pkgConvertToGitPackage() {
    _pkgnameDeclaration="$(grep -o -m 1 '^\s*pkgname\s*=\s*.*$' ${1}/PKGBUILD)"
    eval ${_pkgnameDeclaration}
    if [[ "${pkgname}" == *-git ]];
    then
	echo "Is already Git-Package ${1} (${pkgname})"
	return 0
    fi

    # Only first occurence
    sed -i "0,/${_pkgnameDeclaration}/s//pkgname='${pkgname}-git'/" ${1}/PKGBUILD
}

### START

_makepkgsClone=(
    'https://aur.archlinux.org/libiconv.git'
	)

_makepkgs=(
    # CORE
    'libiconv#nosync#nogit'
    'swig#nosync#nogit'
    'libvmime#nosync#alt1'
#    'kopano-libvmime#alt1'
    'kopano-core'

    # WEBAPP
# OPTIONAL 'jdk'
    'kopano-webapp'
#    'kopano-webapp-gmaps'
#    'kopano-webapp-contactfax'
#    'kopano-webapp-pimfolder'
    'kopano-webapp-nginx'
    'kopano-webapp-files'
    'kopano-webapp-files-owncloud-backend'
    'kopano-webapp-files-smb-backend'
    'kopano-webapp-filepreview'
    'kopano-webapp-desktopnotifications'
#    'kopano-webapp-htmleditor-jodit'
    'kopano-webapp-htmleditor-minimaltiny'
    'kopano-webapp-intranet'
    'kopano-webapp-smime'
    'kopano-webapp-spellchecker'
    'kopano-webapp-spellchecker-languagepack-de-at'
    'kopano-webapp-spellchecker-languagepack-de-ch'
    'kopano-webapp-spellchecker-languagepack-de-de'
    'kopano-webapp-spellchecker-languagepack-en-gb'
    'kopano-webapp-spellchecker-languagepack-en-us'
    'kopano-webapp-spellchecker-languagepack-es-es'
    'kopano-webapp-spellchecker-languagepack-fr-fr'
    'kopano-webapp-spellchecker-languagepack-italian-it'
    'kopano-webapp-spellchecker-languagepack-nl'
    'kopano-webapp-spellchecker-languagepack-pl-pl'
    'kopano-webapp-mdm'
    'kopano-webapp-mattermost'
    'kopano-webapp-meet'
    'kopano-webapp-webmeetings'
    'kopano-webapp-passwd'
    'kopano-webapp-fetchmail'
#    'kopano-webapp-google2fa'
    'z-push'
      )

_build() {
    _outH1 "CHECKOUT"
	    git clone https://aur.archlinux.org/libiconv.git makepkgs/libiconv
#	    git clone https://aur.archlinux.org/libvmime-git.git makepkgs/libvmime

	    # ARCHIVE
	    # php
	    # gcc
	    # jdk
	    # pip2pkgbuild
#	    git clone https://aur.archlinux.org/python-sleekxmpp.git makepkgs/python-sleekxmpp
	    #-git clone https://aur.archlinux.org/python2-vobject.git
	    #git clone https://aur.archlinux.org/php-xapian.git
	    #git clone https://aur.archlinux.org/python2-minimock.git
	    #git clone https://aur.archlinux.org/perl-lockfile-simple.git

	    # MAIN PACKAGES
	    #-git clone ssh://aur@aur.archlinux.org/z-push.git ; cd z-push ; git checkout -b "v2.3.3" 56db7b35459438dc6228b307f0f8855ac7fd9138 ; cd ..

    _outH1 "BUILD"
	    # CORE
	    _pkgBuild makepkgs/libiconv
	    _pkgBuild makepkgs/swig
	    _pkgBuild makepkgs/libvmime
#	    _pkgBuild makepkgs/kopano-libvmime
	    _pkgBuild makepkgs/kopano-core

	    # WEBAPP
	    # OPTIONAL _pkgBuild makepkgs/jdk
	    _pkgBuild makepkgs/kopano-webapp
#	    _pkgBuild makepkgs/kopano-webapp-gmaps
#	    _pkgBuild makepkgs/kopano-webapp-contactfax
#	    _pkgBuild makepkgs/kopano-webapp-pimfolder
	    _pkgBuild makepkgs/kopano-webapp-nginx
	    _pkgBuild makepkgs/kopano-webapp-files
	    _pkgBuild makepkgs/kopano-webapp-files-owncloud-backend
	    _pkgBuild makepkgs/kopano-webapp-files-smb-backend
	    _pkgBuild makepkgs/kopano-webapp-filepreview
	    _pkgBuild makepkgs/kopano-webapp-desktopnotifications
#	    _pkgBuild makepkgs/kopano-webapp-htmleditor-jodit
	    _pkgBuild makepkgs/kopano-webapp-htmleditor-minimaltiny
	    _pkgBuild makepkgs/kopano-webapp-intranet
	    _pkgBuild makepkgs/kopano-webapp-smime
	    _pkgBuild makepkgs/kopano-webapp-spellchecker
	    _pkgBuild makepkgs/kopano-webapp-spellchecker-languagepack-de-at
	    _pkgBuild makepkgs/kopano-webapp-spellchecker-languagepack-de-ch
	    _pkgBuild makepkgs/kopano-webapp-spellchecker-languagepack-de-de
	    _pkgBuild makepkgs/kopano-webapp-spellchecker-languagepack-en-gb
	    _pkgBuild makepkgs/kopano-webapp-spellchecker-languagepack-en-us
	    _pkgBuild makepkgs/kopano-webapp-spellchecker-languagepack-es-es
	    _pkgBuild makepkgs/kopano-webapp-spellchecker-languagepack-fr-fr
	    _pkgBuild makepkgs/kopano-webapp-spellchecker-languagepack-italian-it
	    _pkgBuild makepkgs/kopano-webapp-spellchecker-languagepack-nl
	    _pkgBuild makepkgs/kopano-webapp-spellchecker-languagepack-pl-pl
	    _pkgBuild makepkgs/kopano-webapp-mdm
	    _pkgBuild makepkgs/kopano-webapp-mattermost
	    _pkgBuild makepkgs/kopano-webapp-meet
	    _pkgBuild makepkgs/kopano-webapp-webmeetings
	    _pkgBuild makepkgs/kopano-webapp-passwd
	    _pkgBuild makepkgs/kopano-webapp-fetchmail
#	    _pkgBuild makepkgs/kopano-webapp-google2fa
	    _pkgBuild makepkgs/z-push


	    # DEPENDENCIES - KOPANO-CORE
#	    _pkgBuild makepkgs/php-xapian
#	    _pkgBuild makepkgs/python-sleekxmpp
#	    _pkgBuild makepkgs/python2-minimock
#	    #-$chroot_build ./makepkgs/python2-vobject

#	    _pkgBuild makepkgs/libical2
#	    _pkgBuild makepkgs/python2-tlslite

	    # DEPENDENCIES - KOPANO-POSTFIXADMIN
#	    _pkgBuild makepkgs/perl-lockfile-simple
	    # MAIN PACKAGES

#	    _pkgBuild makepkgs/z-push
#	    _pkgBuild makepkgs/kopano-webapp

#	    _pkgBuild makepkgs/kopano-sabre
#	    _pkgBuild makepkgs/kopano-postfixadmin
#	    _pkgBuild makepkgs/kopano-service-overview

    _outH1 "FINISHED"
}

_outH1 "CHECKOUT"
    for _makepkgClone in "${_makepkgsClone[@]}"
    do
	_makepkgCloneName=${_makepkgClone}
	_makepkgCloneName="${_makepkgCloneName//*\//}"
	_makepkgCloneName="${_makepkgCloneName//.git/}"
	git clone ${_makepkgClone} makepkgs/${_makepkgCloneName}
    done

_outH1 "PREPARE"
    _templateDir=$(realpath ./makepkgs-templates)
    ${_templateDir}/recreate-symlinks.sh
    grep  -R -l "# template " makepkgs | while read _file
    do
	echo "Replacing Template Markers: ${_file}"
	makepkg-template --template-dir ${_templateDir} --input ${_file}
    done


for _task in "$@"
do
    case "${_task}" in
	"convertToGitPackage")
	    _outH1 "CONVERT TO GIT PACKAGE"
	    for _makepkg in "${_makepkgs[@]}"
	    do
		_makepkgname="${_makepkg//#*/}"
		if [[ "${_makepkg}"  == *#nogit* ]];
		then
		    echo "NO GIT : ${_makepkgname}"
		    continue
		fi
		_pkgConvertToGitPackage makepkgs/${_makepkgname}
	    done
	;;
	"sync")
	    _outH1 "SYNC"
	    if [ -z "$(git config --global user.email)" ] \
		|| [ -z "$(git config --global user.name)" ];
	    then
		git config --global user.email "you@example.com"
		git config --global user.name "Your Name"
	    fi

	    for _makepkg in "${_makepkgs[@]}"
	    do
		_makepkgname="${_makepkg//#*/}"
		if [[ "${_makepkgpkg}"  == *#nosync* ]];
		then
		    echo "NO SYNC : ${_makepkgname}"
		    continue
		fi
		_pkgSync makepkgs/${_makepkgname}
	    done
	    cp -R makepkgs-sync /build-target/
	;;
	"push")
	    for pkg in $(ls makepkgs-sync/);
	    do
		_outH1 "PUSHING ${pkg}"
		_pkgPush makepkgs-sync/${pkg}
	    done;
	;;
	"build")
	    _outH1 "BUILD"
		for _makepkg in "${_makepkgs[@]}"
		do
		    _makepkgname="${_makepkg//#*/}"
		    _pkgBuild makepkgs/${_makepkgname}
		done
	;;
	*)
	;;
    esac
done