LAYOUT = mobile-intl

# paths
PREFIX = /usr/local
MANPREFIX = ${PREFIX}/share/man

X11INC = /usr/X11R6/include
X11LIB = /usr/X11R6/lib

PKG_CONFIG = pkg-config

# Xinerama, comment if you don't want it
XINERAMALIBS = -L${X11LIB} -lXinerama
XINERAMAFLAGS = -DXINERAMA

# includes and libs
INCS = -I. -I./layouts -I${X11INC} \
	`$(PKG_CONFIG) --cflags fontconfig` \
	`$(PKG_CONFIG) --cflags freetype2`
LIBS = -L${X11LIB} -lX11 -lXtst -lXft ${XINERAMALIBS} \
	`$(PKG_CONFIG) --libs fontconfig` \
	`$(PKG_CONFIG) --libs freetype2`

# use system flags
SVKBD_CFLAGS = ${CFLAGS} ${INCS}
SVKBD_LDFLAGS = ${LDFLAGS} ${LIBS}
SVKBD_CPPFLAGS = ${CPPFLAGS} -D_DEFAULT_SOURCE -DVERSION=\"${VERSION}\" ${XINERAMAFLAGS} -DLAYOUT=\"layout.${LAYOUT}.h\"
