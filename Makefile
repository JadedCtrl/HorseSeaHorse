love:
	zip -9r bin/horsehorse.love ./*

win32: love
ifeq (,$(wildcard bin/love-win32.zip))
	wget -O bin/love-win32.zip \
		https://github.com/love2d/love/releases/download/11.3/love-11.3-win32.zip
endif
	unzip -d bin/ bin/love-win32.zip
	mv bin/love-*-win32 bin/horsehorse-win32
	rm bin/horsehorse-win32/changes.txt
	rm bin/horsehorse-win32/readme.txt
	rm bin/horsehorse-win32/lovec.exe
	cat bin/horsehorse.love >> bin/horsehorse-win32/love.exe
	mv bin/horsehorse-win32/love.exe bin/horsehorse-win32/HorseHorse.exe
	cp lib/bin-license.txt bin/horsehorse-win32/license.txt
	zip -9jr bin/horsehorse-win32.zip bin/horsehorse-win32
	rm -rf bin/horsehorse-win32

test: love
	love bin/horsehorse.love

clean: 
	rm -rf ./bin/*

all: love win32
