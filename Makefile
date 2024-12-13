
LUACLIBS := ../luaclibs
EPUB := ../epub-reader

PLAT ?= $(shell grep ^platform $(LUACLIBS)/dist/versions.txt | cut -f2)
TARGET_NAME ?= $(shell grep ^target $(LUACLIBS)/dist/versions.txt | cut -f2)

EXE_windows=.exe
EXE_linux=
EXE := $(EXE_$(PLAT))

ZIP_windows=.zip
ZIP_linux=.tar.gz
ZIP := $(ZIP_$(PLAT))

RELEASE_DATE = $(shell date '+%Y%m%d')
RELEASE_NAME ?= -$(TARGET_NAME).$(RELEASE_DATE)
RELEASE_FILES ?= epub-reader$(EXE) LICENSE README.md

STATIC_FLAGS_windows=lua/src/wlua.res -mwindows
STATIC_FLAGS_linux=

release: bin release$(ZIP)

bin:
	$(MAKE) -C $(LUACLIBS) STATIC_OPENSSL=0 \
		STATIC_RESOURCES="-R $(EPUB)/assets $(EPUB)/htdocs -l $(EPUB)/epub-reader.lua" \
		STATIC_NAME=epub-reader "STATIC_EXECUTE=require('epub-reader')" \
		STATIC_FLAGS="$(STATIC_FLAGS_$(PLAT))" static-full
	mv $(LUACLIBS)/dist/epub-reader$(EXE) .

release.tar.gz:
	-rm epub-reader$(RELEASE_NAME).tar.gz
	tar --group=jls --owner=jls -zcvf epub-reader$(RELEASE_NAME).tar.gz $(RELEASE_FILES)

release.zip:
	-rm epub-reader$(RELEASE_NAME).zip
	zip -r epub-reader$(RELEASE_NAME).zip $(RELEASE_FILES)
