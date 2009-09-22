version = 1.7
year = `date +%Y`

build_settings = version=$(version) year=$(year)
generated_files = English.lproj/InfoPlist.strings config.h

all: build/Release/GreaseKit.bundle

build/Release/GreaseKit.bundle: $(generated_files)
	xcodebuild -target GreaseKit -configuration Release $(build_settings)

dist: GreaseKit-$(version).dmg

GreaseKit-$(version).dmg: build/Release/GreaseKit.bundle
	-rm -r $@ tmp/
	mkdir tmp/
	mv $^ tmp/
	sed -e s/VERSION/$(version)/g < README.txt > tmp/README.txt
	cd tmp/ && svn export http://greasekit.googlecode.com/svn/trunk/ Source

	hdiutil create -srcfolder tmp/ -volname 'GreaseKit $(version)' -format UDZO -o GreaseKit-$(version).dmg

clean:
	-rm $(generated_files)
	-rm GreaseKit-$(version).dmg
	-rm -fr tmp/ build/

config.h:
	echo "#define VERSION \"$(version)\"" > $@

English.lproj/InfoPlist.strings:
	echo "NSHumanReadableCopyright=\"Copyright © 2006-$(year) KATO Kazuyoshi\";" > $@
