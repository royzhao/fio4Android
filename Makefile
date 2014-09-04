ifneq ($(wildcard config-host.mak),)
all:
include config-host.mak
config-host-mak: configure
	@echo $@ is out-of-date, running configure
	@sed -n "/.*Configured with/s/[^:]*: //p" $@ | sh
else
config-host.mak:
ifneq ($(MAKECMDGOALS),clean)
	@echo "Running configure for you..."
	@echo $uname
	@echo $cross_prefix
	@./configure
endif
all:
include config-host.mak
endif

DEBUGFLAGS = -D_FORTIFY_SOURCE=2 -DFIO_INC_DEBUG
CPPFLAGS= -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DFIO_INTERNAL $(DEBUGFLAGS)
OPTFLAGS= -O3 -g -ffast-math
CFLAGS	= -std=gnu99 -Wwrite-strings -Wall -Wdeclaration-after-statement $(OPTFLAGS) $(EXTFLAGS) $(BUILD_CFLAGS)
LIBS	+= -lm $(EXTLIBS)
PROGS	= fio
SCRIPTS = tools/fio_generate_plots tools/plot/fio2gnuplot tools/genfio

ifdef CONFIG_GFIO
  PROGS += gfio
endif

SOURCE := gettime.c ioengines.c init.c stat.c log.c time.c filesetup.c \
		eta.c verify.c memory.c io_u.c parse.c mutex.c options.c \
		lib/rbtree.c smalloc.c filehash.c profile.c debug.c lib/rand.c \
		lib/num2str.c lib/ieee754.c $(wildcard crc/*.c) engines/cpu.c \
		engines/mmap.c engines/sync.c engines/null.c engines/net.c \
		memalign.c server.c client.c iolog.c backend.c libfio.c flow.c \
		cconv.c lib/prio_tree.c json.c lib/zipf.c lib/axmap.c \
		lib/lfsr.c gettime-thread.c helpers.c lib/flist_sort.c \
		lib/hweight.c lib/getrusage.c idletime.c td_error.c \
		profiles/tiobench.c profiles/act.c io_u_queue.c filelock.c \
		lib/tp.c

ifdef CONFIG_64BIT_LLP64
  CFLAGS += -DBITS_PER_LONG=32
endif
ifdef CONFIG_64BIT
  CFLAGS += -DBITS_PER_LONG=64
endif
ifdef CONFIG_32BIT
  CFLAGS += -DBITS_PER_LONG=32
endif
ifdef CONFIG_LIBAIO
  SOURCE += engines/libaio.c
endif
ifdef CONFIG_RDMA
  SOURCE += engines/rdma.c
endif
ifdef CONFIG_POSIXAIO
  SOURCE += engines/posixaio.c
endif
ifdef CONFIG_LINUX_FALLOCATE
  SOURCE += engines/falloc.c
endif
ifdef CONFIG_LINUX_EXT4_MOVE_EXTENT
  SOURCE += engines/e4defrag.c
endif
ifdef CONFIG_LINUX_SPLICE
  SOURCE += engines/splice.c
endif
ifdef CONFIG_GUASI
  SOURCE += engines/guasi.c
endif
ifdef CONFIG_FUSION_AW
  SOURCE += engines/fusion-aw.c
endif
ifdef CONFIG_SOLARISAIO
  SOURCE += engines/solarisaio.c
endif
ifdef CONFIG_WINDOWSAIO
  SOURCE += engines/windowsaio.c
endif
ifdef CONFIG_RBD
  SOURCE += engines/rbd.c
endif
ifndef CONFIG_STRSEP
  SOURCE += lib/strsep.c
endif
ifndef CONFIG_STRCASESTR
  SOURCE += lib/strcasestr.c
endif
ifndef CONFIG_GETOPT_LONG_ONLY
  SOURCE += lib/getopt_long.c
endif
ifndef CONFIG_INET_ATON
  SOURCE += lib/inet_aton.c
endif
ifdef CONFIG_GFAPI
  SOURCE += engines/glusterfs.c
  SOURCE += engines/glusterfs_sync.c
  SOURCE += engines/glusterfs_async.c
  ifdef CONFIG_GF_FADVISE
    CFLAGS += "-DGFAPI_USE_FADVISE"
  endif
endif

ifeq ($(CONFIG_TARGET_OS), Linux)
  SOURCE += diskutil.c fifo.c blktrace.c cgroup.c trim.c engines/sg.c \
		engines/binject.c
  LIBS += -lpthread -ldl
  LDFLAGS += -rdynamic
endif
ifeq ($(CONFIG_TARGET_OS), Android)
  SOURCE += diskutil.c fifo.c blktrace.c trim.c profiles/tiobench.c
  LIBS += -ldl
  LDFLAGS += -rdynamic
endif
ifeq ($(CONFIG_TARGET_OS), SunOS)
  LIBS	 += -lpthread -ldl
  CPPFLAGS += -D__EXTENSIONS__
endif
ifeq ($(CONFIG_TARGET_OS), FreeBSD)
  LIBS	 += -lpthread -lrt
  LDFLAGS += -rdynamic
endif
ifeq ($(CONFIG_TARGET_OS), OpenBSD)
  LIBS	 += -lpthread
  LDFLAGS += -rdynamic
endif
ifeq ($(CONFIG_TARGET_OS), NetBSD)
  LIBS	 += -lpthread -lrt
  LDFLAGS += -rdynamic
endif
ifeq ($(CONFIG_TARGET_OS), AIX)
  LIBS	 += -lpthread -ldl -lrt
  CPPFLAGS += -D_LARGE_FILES -D__ppc__
  LDFLAGS += -L/opt/freeware/lib -Wl,-blibpath:/opt/freeware/lib:/usr/lib:/lib -Wl,-bmaxdata:0x80000000
endif
ifeq ($(CONFIG_TARGET_OS), HP-UX)
  LIBS   += -lpthread -ldl -lrt
  CFLAGS += -D_LARGEFILE64_SOURCE -D_XOPEN_SOURCE_EXTENDED
endif
ifeq ($(CONFIG_TARGET_OS), Darwin)
  LIBS	 += -lpthread -ldl
endif
ifneq (,$(findstring CYGWIN,$(CONFIG_TARGET_OS)))
  SOURCE := $(filter-out engines/mmap.c,$(SOURCE))
  SOURCE += os/windows/posix.c
  LIBS	 += -lpthread -lpsapi -lws2_32
  CFLAGS += -DPSAPI_VERSION=1 -Ios/windows/posix/include -Wno-format -static
endif

OBJS = $(SOURCE:.c=.o)

FIO_OBJS = $(OBJS) fio.o
GFIO_OBJS = $(OBJS) gfio.o graph.o tickmarks.o ghelpers.o goptions.o gerror.o \
			gclient.o gcompat.o cairo_text_helpers.o printing.o

-include $(OBJS:.o=.d)

T_SMALLOC_OBJS = t/stest.o
T_SMALLOC_OBJS += gettime.o mutex.o smalloc.o t/log.o
T_SMALLOC_PROGS = t/stest

T_IEEE_OBJS = t/ieee754.o
T_IEEE_OBJS += lib/ieee754.o
T_IEEE_PROGS = t/ieee754

T_ZIPF_OBS = t/genzipf.o
T_ZIPF_OBJS += t/log.o lib/ieee754.o lib/rand.o lib/zipf.o t/genzipf.o
T_ZIPF_PROGS = t/genzipf

T_AXMAP_OBJS = t/axmap.o
T_AXMAP_OBJS += lib/lfsr.o lib/axmap.o
T_AXMAP_PROGS = t/axmap

T_LFSR_TEST_OBJS = t/lfsr-test.o
T_LFSR_TEST_OBJS += lib/lfsr.o
T_LFSR_TEST_PROGS = t/lfsr-test

T_OBJS = $(T_SMALLOC_OBJS)
T_OBJS += $(T_IEEE_OBJS)
T_OBJS += $(T_ZIPF_OBJS)
T_OBJS += $(T_AXMAP_OBJS)
T_OBJS += $(T_LFSR_TEST_OBJS)

T_PROGS = $(T_SMALLOC_PROGS)
T_PROGS += $(T_IEEE_PROGS)
T_PROGS += $(T_ZIPF_PROGS)
T_PROGS += $(T_AXMAP_PROGS)
T_PROGS += $(T_LFSR_TEST_PROGS)

ifneq ($(findstring $(MAKEFLAGS),s),s)
ifndef V
	QUIET_CC	= @echo '   ' CC $@;
	QUIET_LINK	= @echo '   ' LINK $@;
	QUIET_DEP	= @echo '   ' DEP $@;
endif
endif

ifeq ($(CONFIG_TARGET_OS), SunOS)
	INSTALL = ginstall
else
	INSTALL = install
endif
prefix = /usr/local
bindir = $(prefix)/bin

ifeq ($(CONFIG_TARGET_OS), Darwin)
mandir = /usr/share/man
sharedir = /usr/share/fio
else
mandir = $(prefix)/man
sharedir = $(prefix)/share/fio
endif

all: $(PROGS) $(SCRIPTS) FORCE

.PHONY: all install clean
.PHONY: FORCE cscope

FIO-VERSION-FILE: FORCE
	@$(SHELL) ./FIO-VERSION-GEN
-include FIO-VERSION-FILE

override CFLAGS += -DFIO_VERSION='"$(FIO_VERSION)"'

%.o : %.c
	$(QUIET_CC)$(CC) -o $@ $(CFLAGS) $(CPPFLAGS) -c $<
	@$(CC) -MM $(CFLAGS) $(CPPFLAGS) $*.c > $*.d
	@mv -f $*.d $*.d.tmp
	@sed -e 's|.*:|$*.o:|' < $*.d.tmp > $*.d
	@sed -e 's/.*://' -e 's/\\$$//' < $*.d.tmp | fmt -1 | \
		sed -e 's/^ *//' -e 's/$$/:/' >> $*.d
	@rm -f $*.d.tmp

init.o: FIO-VERSION-FILE init.c
	$(QUIET_CC)$(CC) -o init.o $(CFLAGS) $(CPPFLAGS) -c init.c

gcompat.o: gcompat.c gcompat.h
	$(QUIET_CC)$(CC) $(CFLAGS) $(GTK_CFLAGS) $(CPPFLAGS) -c gcompat.c

goptions.o: goptions.c goptions.h
	$(QUIET_CC)$(CC) $(CFLAGS) $(GTK_CFLAGS) $(CPPFLAGS) -c goptions.c

ghelpers.o: ghelpers.c ghelpers.h
	$(QUIET_CC)$(CC) $(CFLAGS) $(GTK_CFLAGS) $(CPPFLAGS) -c ghelpers.c

gerror.o: gerror.c gerror.h
	$(QUIET_CC)$(CC) $(CFLAGS) $(GTK_CFLAGS) $(CPPFLAGS) -c gerror.c

gclient.o: gclient.c gclient.h
	$(QUIET_CC)$(CC) $(CFLAGS) $(GTK_CFLAGS) $(CPPFLAGS) -c gclient.c

gfio.o: gfio.c ghelpers.c
	$(QUIET_CC)$(CC) $(CFLAGS) $(GTK_CFLAGS) $(CPPFLAGS) -c gfio.c

graph.o: graph.c graph.h
	$(QUIET_CC)$(CC) $(CFLAGS) $(GTK_CFLAGS) $(CPPFLAGS) -c graph.c

cairo_text_helpers.o: cairo_text_helpers.c cairo_text_helpers.h
	$(QUIET_CC)$(CC) $(CFLAGS) $(GTK_CFLAGS) $(CPPFLAGS) -c cairo_text_helpers.c

printing.o: printing.c printing.h
	$(QUIET_CC)$(CC) $(CFLAGS) $(GTK_CFLAGS) $(CPPFLAGS) -c printing.c

t/stest: $(T_SMALLOC_OBJS)
	$(QUIET_LINK)$(CC) $(LDFLAGS) $(CFLAGS) -o $@ $(T_SMALLOC_OBJS) $(LIBS)

t/ieee754: $(T_IEEE_OBJS)
	$(QUIET_LINK)$(CC) $(LDFLAGS) $(CFLAGS) -o $@ $(T_IEEE_OBJS) $(LIBS)

fio: $(FIO_OBJS)
	$(QUIET_LINK)$(CC) $(LDFLAGS) $(CFLAGS) -o $@ $(FIO_OBJS) $(LIBS)

gfio: $(GFIO_OBJS)
	$(QUIET_LINK)$(CC) $(LDFLAGS) -o gfio $(GFIO_OBJS) $(LIBS) $(GTK_LDFLAGS)

t/genzipf: $(T_ZIPF_OBJS)
	$(QUIET_LINK)$(CC) $(LDFLAGS) $(CFLAGS) -o $@ $(T_ZIPF_OBJS) $(LIBS)

t/axmap: $(T_AXMAP_OBJS)
	$(QUIET_LINK)$(CC) $(LDFLAGS) $(CFLAGS) -o $@ $(T_AXMAP_OBJS) $(LIBS)

t/lfsr-test: $(T_LFSR_TEST_OBJS)
	$(QUIET_LINK)$(CC) $(LDFLAGS) $(CFLAGS) -o $@ $(T_LFSR_TEST_OBJS) $(LIBS)

clean: FORCE
	-rm -f .depend $(FIO_OBJS) $(GFIO_OBJS) $(OBJS) $(T_OBJS) $(PROGS) $(T_PROGS) core.* core gfio FIO-VERSION-FILE *.d lib/*.d crc/*.d engines/*.d profiles/*.d t/*.d config-host.mak config-host.h

distclean: clean FORCE
	@rm -f cscope.out fio.pdf fio_generate_plots.pdf fio2gnuplot.pdf

cscope:
	@cscope -b -R

tools/plot/fio2gnuplot.1:
	@cat tools/plot/fio2gnuplot.manpage | txt2man -t fio2gnuplot >  tools/plot/fio2gnuplot.1

doc: tools/plot/fio2gnuplot.1
	@man -t ./fio.1 | ps2pdf - fio.pdf
	@man -t tools/fio_generate_plots.1 | ps2pdf - fio_generate_plots.pdf
	@man -t tools/plot/fio2gnuplot.1 | ps2pdf - fio2gnuplot.pdf

install: $(PROGS) $(SCRIPTS) tools/plot/fio2gnuplot.1 FORCE
	$(INSTALL) -m 755 -d $(DESTDIR)$(bindir)
	$(INSTALL) $(PROGS) $(SCRIPTS) $(DESTDIR)$(bindir)
	$(INSTALL) -m 755 -d $(DESTDIR)$(mandir)/man1
	$(INSTALL) -m 644 fio.1 $(DESTDIR)$(mandir)/man1
	$(INSTALL) -m 644 tools/fio_generate_plots.1 $(DESTDIR)$(mandir)/man1
	$(INSTALL) -m 644 tools/plot/fio2gnuplot.1 $(DESTDIR)$(mandir)/man1
	$(INSTALL) -m 755 -d $(DESTDIR)$(sharedir)
	$(INSTALL) -m 644 tools/plot/*gpm $(DESTDIR)$(sharedir)/
