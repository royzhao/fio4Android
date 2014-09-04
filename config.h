/*************************************************************************
	> File Name: config.h
	> Author: 
	> Mail: 
	> Created Time: 2014年09月04日 星期四 12时08分14秒
 ************************************************************************/

#ifndef CONFIG_BY_ZPL
#define CONFIG_BY_ZPL

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))
#endif

/* Swap bytes in 16 bit value.  */
#define __bswap_16(x) \
     ((((x) >> 8) & 0xff) | (((x) & 0xff) << 8))


/* Swap bytes in 32 bit value.  */
#define __bswap_32(x) \
     ((((x) & 0xff000000) >> 24) | (((x) & 0x00ff0000) >>  8) |		      \
      (((x) & 0x0000ff00) <<  8) | (((x) & 0x000000ff) << 24))


/* Swap bytes in 64 bit value.  */
#define __bswap_64(x) \
     ((((x) & 0xff00000000000000ull) >> 56)				      \
      | (((x) & 0x00ff000000000000ull) >> 40)				      \
      | (((x) & 0x0000ff0000000000ull) >> 24)				      \
      | (((x) & 0x000000ff00000000ull) >> 8)				      \
      | (((x) & 0x00000000ff000000ull) << 8)				      \
      | (((x) & 0x0000000000ff0000ull) << 24)				      \
      | (((x) & 0x000000000000ff00ull) << 40)				      \
      | (((x) & 0x00000000000000ffull) << 56))


#endif
