LOCAL_PATH :=$(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE :=fio
LOCAL_MODULE_TAGS :=optional

LOCAL_SRC_FILES := gettime.c ioengines.c \
	init.c stat.c log.c time.c filesetup.c \
	eta.c verify.c memory.c io_u.c parse.c \
	mutex.c options.c lib/rbtree.c smalloc.c \
	filehash.c profile.c debug.c lib/rand.c \
	lib/num2str.c lib/ieee754.c crc/crc16.c \
	crc/crc32.c crc/crc32c.c crc/crc32c-intel.c \
	crc/crc64.c crc/crc7.c crc/md5.c crc/sha1.c \
	crc/sha256.c crc/sha512.c crc/test.c crc/xxhash.c \
	engines/cpu.c engines/mmap.c engines/sync.c engines/null.c \
	engines/net.c memalign.c server.c  client.c iolog.c backend.c \
	libfio.c flow.c cconv.c lib/prio_tree.c json.c lib/zipf.c \
	lib/axmap.c lib/lfsr.c gettime-thread.c helpers.c lib/flist_sort.c \
	lib/hweight.c lib/getrusage.c idletime.c td_error.c \
	profiles/tiobench.c profiles/act.c io_u_queue.c filelock.c \
	lib/tp.c diskutil.c fifo.c blktrace.c trim.c profiles/tiobench.c fio.c
LOCAL_SHARED_LIBRARIES:=libdl
LOCAL_STATIC_LIBRARIES:=libcutils libz
LOCAL_C_INCLUDES +=external/zlib

LOCAL_CFLAGS:= -rdynamic  -std=gnu99 -Wwrite-strings -Wall -Wdeclaration-after-statement -O3 -g -ffast-math -D_GNU_SOURCE -include config-host.h -DBITS_PER_LONG=32 -DFIO_VERSION=fio-2.1.11
LOCAL_LDLIBS:=-lz  -lm  -ldl 
include $(BUILD_EXECUTABLE)
