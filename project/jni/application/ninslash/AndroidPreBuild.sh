#!/bin/sh

LOCAL_PATH=`dirname $0`
LOCAL_PATH=`cd $LOCAL_PATH && pwd`

cd $LOCAL_PATH/src

[ -n "`find datasrc/*.py -cnewer src/game/generated/protocol.cpp 2>&1`" ] && {
echo "Building autogenerated files"
python --version > /dev/null 2>&1 || { echo "Error: no Python installed" ; exit 1 ; }

mkdir -p src/game/generated
python datasrc/compile.py network_source > src/game/generated/protocol.cpp
python datasrc/compile.py network_header > src/game/generated/protocol.h
python datasrc/compile.py client_content_source > src/game/generated/client_data.cpp
python datasrc/compile.py client_content_header > src/game/generated/client_data.h
python datasrc/compile.py server_content_source > src/game/generated/server_data.cpp
python datasrc/compile.py server_content_header > src/game/generated/server_data.h

python scripts/cmd5.py src/engine/shared/protocol.h src/game/generated/protocol.h src/game/tuning.h src/game/gamecore.cpp src/game/generated/protocol.h > src/game/generated/nethash.cpp
}

[ -n "`find data *.txt *.cfg -cnewer ../AndroidData/data.zip 2>&1`" ] && {
echo "Archiving data"
mkdir -p ../AndroidData
zip -r ../AndroidData/data.zip data *.txt *.cfg >/dev/null
}

for ARCH in armeabi-v7a x86; do
	[ -e ../AndroidData/binaries-$ARCH.zip ] && continue
	rm -rf teeworlds_srv
	mkdir -p objs
	# server-sources.txt generated by running bam server_release 2>&1 | tee build.log
	# and parsing logs with grep -o ' [^ ]*[.]cp\?p\?' build.log | grep -v /zlib/ > ../server-sources.txt
	echo "Building teeworlds_srv for $ARCH"
	env BUILD_EXECUTABLE=1 NO_SHARED_LIBS=1 ../../setEnvironment-$ARCH.sh \
		sh -c '
		OBJS=
		for F in `cat ../server-sources.txt`; do
			dirname objs/$F.o | xargs mkdir -p
			echo $F
			OBJS="$OBJS objs/$F.o"
			$CXX $CFLAGS -fno-exceptions -fno-rtti --std=c++11 -flto -Wall -DCONF_RELEASE -I src -c $F -o objs/$F.o || exit 1
		done
		echo Linking teeworlds_srv
		$CXX $CFLAGS -fno-exceptions -fno-rtti $LDFLAGS -pie -flto -pthread -o teeworlds_srv $OBJS || exit 1
		$STRIP --strip-unneeded teeworlds_srv
		' || exit 1
	cp teeworlds_srv bin-$ARCH/
	cd bin-$ARCH
	zip ../../AndroidData/binaries-$ARCH.zip *
	cd ..
done

cp -f logo.png ../AndroidData/

exit 0
