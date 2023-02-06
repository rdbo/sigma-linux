# svkbd - simple virtual keyboard
# See LICENSE file for copyright and license details.
.POSIX:

NAME = svkbd
VERSION = 0.4.1

include config.mk

BIN = ${NAME}-${LAYOUT}
SRC = drw.c ${NAME}.c util.c
OBJ = drw.o ${NAME}-${LAYOUT}.o util.o
MAN1 = ${NAME}.1

all: ${BIN}

options:
	@echo svkbd build options:
	@echo "CFLAGS   = ${SVKBD_CFLAGS}"
	@echo "CPPLAGS  = ${SVKBD_CPPFLAGS}"
	@echo "LDFLAGS  = ${SVKBD_LDFLAGS}"
	@echo "CC       = ${CC}"

config.h:
	cp config.def.h $@

svkbd-${LAYOUT}.o: config.h layout.${LAYOUT}.h
	${CC} ${SVKBD_CFLAGS} ${SVKBD_CPPFLAGS} -c svkbd.c -o $@

.c.o:
	${CC} ${SVKBD_CFLAGS} ${SVKBD_CPPFLAGS} -c $<

${OBJ}: config.h config.mk

${BIN}: ${OBJ}
	${CC} -o ${BIN} ${OBJ} ${SVKBD_LDFLAGS}

clean:
	rm -f ${NAME}-?? ${NAME}-*.o ${OBJ} ${BIN}

dist:
	rm -rf "${NAME}-${VERSION}"
	mkdir -p "${NAME}-${VERSION}"
	cp LICENSE Makefile README.md config.def.h config.mk ${MAN1} \
		drw.h util.h ${SRC} ${NAME}-${VERSION}
	for i in layout.*.h; \
	do \
		cp $$i ${NAME}-${VERSION}; \
	done
	tar -cf - "${NAME}-${VERSION}" | \
		gzip -c > "${NAME}-${VERSION}.tar.gz"
	rm -rf "${NAME}-${VERSION}"

install: all
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -f ${NAME}-${LAYOUT} ${DESTDIR}${PREFIX}/bin
	chmod 755 ${DESTDIR}${PREFIX}/bin/${NAME}-${LAYOUT}
	mkdir -p "${DESTDIR}${MANPREFIX}/man1"
	sed "s/VERSION/${VERSION}/g" < ${MAN1} > ${DESTDIR}${MANPREFIX}/man1/${MAN1}
	chmod 644 ${DESTDIR}${MANPREFIX}/man1/${MAN1}

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/${NAME}-??
	rm -f ${DESTDIR}${MANPREFIX}/man1/${MAN1}

.PHONY: all clean dist options install uninstall
