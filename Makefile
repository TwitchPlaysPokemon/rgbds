# User-defined variables

Q		:= @
PREFIX		:= /usr/local
bindir		:= ${PREFIX}/bin
mandir		:= ${PREFIX}/man
STRIP		:= -s
BINMODE		:= 555
MANMODE		:= 444

# Other variables

PKG_CONFIG	:= pkg-config
PNGCFLAGS	:= `${PKG_CONFIG} --static --cflags libpng`
PNGLDFLAGS	:= `${PKG_CONFIG} --static --libs-only-L libpng`
PNGLDLIBS	:= `${PKG_CONFIG} --static --libs-only-l libpng`

WARNFLAGS	:= -Wall -Werror
CFLAGS		:= ${WARNFLAGS} -g -std=c99 -D_POSIX_C_SOURCE=200809L -Iinclude

YFLAGS		:=
LFLAGS		:= --nounistd

YACC		:= yacc
LEX		:= flex
RM		:= rm -rf

# Rules to build the RGBDS binaries

all: rgbasm rgblink rgbfix rgbgfx

rgbasm_obj := \
	src/asm/asmy.o \
	src/asm/charmap.o \
	src/asm/fstack.o \
	src/asm/globlex.o \
	src/asm/lexer.o \
	src/asm/main.o \
	src/asm/math.o \
	src/asm/output.o \
	src/asm/rpn.o \
	src/asm/symbol.o \
	src/asm/locallex.o \
	src/extern/err.o \
	src/extern/reallocarray.o \
	src/extern/strlcpy.o \
	src/extern/strlcat.o

src/asm/asmy.h: src/asm/asmy.c
src/asm/locallex.o src/asm/globlex.o src/asm/lexer.o: src/asm/asmy.h

rgblink_obj := \
	src/link/assign.o \
	src/link/lexer.o \
	src/link/library.o \
	src/link/main.o \
	src/link/mapfile.o \
	src/link/object.o \
	src/link/output.o \
	src/link/patch.o \
	src/link/parser.o \
	src/link/script.o \
	src/link/symbol.o \
	src/extern/err.o

src/link/parser.h: src/link/parser.c
src/link/lexer.o: src/link/parser.h

rgbfix_obj := \
	src/fix/main.o \
	src/extern/err.o

rgbgfx_obj := \
	src/gfx/gb.o \
	src/gfx/main.o \
	src/gfx/makepng.o \
	src/extern/err.o

rgbasm: ${rgbasm_obj}
	$Q${CC} ${CFLAGS} -o $@ ${rgbasm_obj} -lm

rgblink: ${rgblink_obj}
	$Q${CC} ${CFLAGS} -o $@ ${rgblink_obj}

rgbfix: ${rgbfix_obj}
	$Q${CC} ${CFLAGS} -o $@ ${rgbfix_obj}

rgbgfx: ${rgbgfx_obj}
	$Q${CC} ${CFLAGS} ${PNGLDFLAGS} -o $@ ${rgbgfx_obj} ${PNGLDLIBS}

# Rules to process files

.y.c:
	$Q${YACC} -d ${YFLAGS} -o $@ $<

.l.o:
	$Q${RM} $*.c
	$Q${LEX} ${LFLAGS} -o $*.c $<
	$Q${CC} ${CFLAGS} -c -o $@ $*.c
	$Q${RM} $*.c

.c.o:
	$Q${CC} ${CFLAGS} ${PNGCFLAGS} -c -o $@ $<

# Target used to remove all files generated by other Makefile targets.

clean:
	$Q${RM} rgbds.7.html gbz80.7.html rgbds.5.html
	$Q${RM} rgbasm rgbasm.exe ${rgbasm_obj} rgbasm.1.html rgbasm.5.html
	$Q${RM} rgblink rgblink.exe ${rgblink_obj} rgblink.1.html rgblink.5.html
	$Q${RM} rgbfix rgbfix.exe ${rgbfix_obj} rgbfix.1.html
	$Q${RM} rgbgfx rgbgfx.exe ${rgbgfx_obj} rgbgfx.1.html
	$Q${RM} src/asm/asmy.c src/asm/asmy.h
	$Q${RM} src/link/lexer.c src/link/parser.c src/link/parser.h

# Target used to install the binaries and man pages.

install: all
	$Qmkdir -p ${DESTDIR}${bindir}
	$Qinstall ${STRIP} -m ${BINMODE} rgbasm ${DESTDIR}${bindir}/rgbasm
	$Qinstall ${STRIP} -m ${BINMODE} rgbfix ${DESTDIR}${bindir}/rgbfix
	$Qinstall ${STRIP} -m ${BINMODE} rgblink ${DESTDIR}${bindir}/rgblink
	$Qinstall ${STRIP} -m ${BINMODE} rgbgfx ${DESTDIR}${bindir}/rgbgfx
	$Qmkdir -p ${DESTDIR}${mandir}/man1 ${DESTDIR}${mandir}/man5 ${DESTDIR}${mandir}/man7
	$Qinstall -m ${MANMODE} src/rgbds.7 ${DESTDIR}${mandir}/man7/rgbds.7
	$Qinstall -m ${MANMODE} src/gbz80.7 ${DESTDIR}${mandir}/man7/gbz80.7
	$Qinstall -m ${MANMODE} src/rgbds.5 ${DESTDIR}${mandir}/man5/rgbds.5
	$Qinstall -m ${MANMODE} src/asm/rgbasm.1 ${DESTDIR}${mandir}/man1/rgbasm.1
	$Qinstall -m ${MANMODE} src/asm/rgbasm.5 ${DESTDIR}${mandir}/man5/rgbasm.5
	$Qinstall -m ${MANMODE} src/fix/rgbfix.1 ${DESTDIR}${mandir}/man1/rgbfix.1
	$Qinstall -m ${MANMODE} src/link/rgblink.1 ${DESTDIR}${mandir}/man1/rgblink.1
	$Qinstall -m ${MANMODE} src/link/rgblink.5 ${DESTDIR}${mandir}/man5/rgblink.5
	$Qinstall -m ${MANMODE} src/gfx/rgbgfx.1 ${DESTDIR}${mandir}/man1/rgbgfx.1

# Target for the project maintainer to easily create web manuals.
# It relies on mandoc: http://mdocml.bsd.lv

MANDOC	:= -Thtml -Ios=General -Oman=%N.%S.html -Ostyle=manual.css

wwwman:
	$Qmandoc ${MANDOC} src/rgbds.7 > rgbds.7.html
	$Qmandoc ${MANDOC} src/gbz80.7 > gbz80.7.html
	$Qmandoc ${MANDOC} src/rgbds.5 > rgbds.5.html
	$Qmandoc ${MANDOC} src/asm/rgbasm.1 > rgbasm.1.html
	$Qmandoc ${MANDOC} src/asm/rgbasm.5 > rgbasm.5.html
	$Qmandoc ${MANDOC} src/fix/rgbfix.1 > rgbfix.1.html
	$Qmandoc ${MANDOC} src/link/rgblink.1 > rgblink.1.html
	$Qmandoc ${MANDOC} src/link/rgblink.5 > rgblink.5.html
	$Qmandoc ${MANDOC} src/gfx/rgbgfx.1 > rgbgfx.1.html

# Targets for the project maintainer to easily create Windows exes.
# This is not for Windows users!
# If you're building on Windows with Cygwin or Mingw, just follow the Unix
# install instructions instead.

mingw32:
	$Qenv PKG_CONFIG_PATH=/usr/i686-w64-mingw32/sys-root/mingw/lib/pkgconfig/ \
		make CC=i686-w64-mingw32-gcc YACC=bison WARNFLAGS= -j
	$Qmv rgbasm rgbasm.exe
	$Qmv rgblink rgblink.exe
	$Qmv rgbfix rgbfix.exe
	$Qmv rgbgfx rgbgfx.exe

mingw64:
	$Qenv PKG_CONFIG_PATH=/usr/x86_64-w64-mingw32/sys-root/mingw/lib/pkgconfig/ \
		make CC=x86_64-w64-mingw32-gcc YACC=bison WARNFLAGS= -j
	$Qmv rgbasm rgbasm.exe
	$Qmv rgblink rgblink.exe
	$Qmv rgbfix rgbfix.exe
	$Qmv rgbgfx rgbgfx.exe
