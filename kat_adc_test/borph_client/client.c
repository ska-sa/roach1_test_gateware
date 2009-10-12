/* example client to read and write registers, using borph_read and 
 * borph_write - edit main to do what you want
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <ctype.h>

#include <sys/select.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>

#include "netc.h"
#include "katcp.h"
#include "katcl.h"

/* supporting logic starts here */

static int dispatch_client(struct katcl_line *l, char *msgname, int verbose, unsigned int timeout)
{
  fd_set fsr, fsw;
  struct timeval tv;
  int result;
  char *ptr, *match;
  int prefix;
  int fd;

  fd = fileno_katcl(l);

  if(msgname){
    switch(msgname[0]){
      case '!' :
      case '?' :
        prefix = strlen(msgname + 1);
        match = msgname + 1;
        break;
      default :
        prefix = strlen(msgname);
        match = msgname;
        break;
    }
  } else {
    prefix = 0;
    match = NULL;
  }

  for(;;){

    FD_ZERO(&fsr);
    FD_ZERO(&fsw);

    if(match){ /* only look for data if we need it */
      FD_SET(fd, &fsr);
    }

    if(flushing_katcl(l)){ /* only write data if we have some */
      FD_SET(fd, &fsw);
    }

    tv.tv_sec  = timeout / 1000;
    tv.tv_usec = (timeout % 1000) * 1000;

    result = select(fd + 1, &fsr, &fsw, NULL, &tv);
    switch(result){
      case -1 :
        switch(errno){
          case EAGAIN :
          case EINTR  :
            continue; /* WARNING */
          default  :
            return -1;
        }
        break;
      case  0 :
        if(verbose){
          fprintf(stderr, "dispatch: no io activity within %u ms\n", timeout);
        }
        return -1;
    }

    if(FD_ISSET(fd, &fsw)){
      result = write_katcl(l);
      if(result < 0){
        fprintf(stderr, "dispatch: write failed: %s\n", strerror(error_katcl(l)));
        return -1;
      }
      if((result > 0) && (match == NULL)){ /* if we finished writing and don't expect a match then quit */
        return 0;
      }
    }

    if(FD_ISSET(fd, &fsr)){
      if(read_katcl(l) < 0){
        fprintf(stderr, "dispatch: read failed: %s\n", strerror(error_katcl(l)));
        return -1;
      }
    }

    while(have_katcl(l) > 0){
      ptr = arg_string_katcl(l, 0);
      if(ptr){
        switch(ptr[0]){
          case KATCP_INFORM : 
            break;
          case KATCP_REPLY : 
            if(match){
              if(strncmp(match, ptr + 1, prefix) || ((ptr[prefix + 1] != '\0') && (ptr[prefix + 1] != ' '))){
                fprintf(stderr, "dispatch: warning, encountered reply <%s> not match <%s>\n", ptr, match);
              } else {
                ptr = arg_string_katcl(l, 1);
                if(ptr && !strcmp(ptr, KATCP_OK)){
                  return 0;
                } else {
                  return -1;
                }
              }
            }
            break;
          case KATCP_REQUEST : 
            fprintf(stderr, "dispatch: warning, encountered an unanswerable request <%s>\n", ptr);
            break;
          default :
            fprintf(stderr, "dispatch: read malformed message <%s>\n", ptr);
            break;
        }
      }
    }
  }
}

int borph_write(struct katcl_line *l, char *regname, void *buffer, int offset, int len, unsigned int timeout)
{
  if(append_string_katcl(l, KATCP_FLAG_FIRST, "?write")   < 0) return -1;
  if(append_string_katcl(l, 0, regname)                   < 0) return -1;
  if(append_unsigned_long_katcl(l, 0, offset)             < 0) return -1;
  if(append_buffer_katcl(l, KATCP_FLAG_LAST, buffer, len) < 0) return -1;
  if(dispatch_client(l, "!write", 0, timeout)             < 0) return -1;

  have_katcl(l);

  return 0;
}

int borph_read(struct katcl_line *l, char *regname, void *buffer, int offset, int len, unsigned int timeout)
{
  int count, got;

  if(append_string_katcl(l, KATCP_FLAG_FIRST, "?read")    < 0) return -1;
  if(append_string_katcl(l, 0, regname)                   < 0) return -1;
  if(append_unsigned_long_katcl(l, 0, offset)             < 0) return -1;
  if(append_unsigned_long_katcl(l, KATCP_FLAG_LAST, len)  < 0) return -1;

  if(dispatch_client(l, "!read", 0, timeout)              < 0) return -1;

  count = arg_count_katcl(l);
  if(count < 2){
    fprintf(stderr, "read: insufficient arguments in reply\n");
    return -1;
  }

  got = arg_buffer_katcl(l, 2, buffer, len);

  if(got < len){
    fprintf(stderr, "read: partial data, wanted %d, got %d\n", len, got);
    return -1;
  }

  have_katcl(l);

  return len;
}

/* supporing logic ends here, add your code to main() */

#define IIC_START  0x2
#define IIC_STOP   0x4
#define IIC_READ   0x1
#define IIC_WRITE  0x0

#define IIC_CMD(a,rnw) ((((a) & 0x7f) << 1) | ((rnw) & 0x1))
#define IIC_CMD_RD 0x1
#define IIC_CMD_WR 0x0

int kat_adc_iic_status(struct katcl_line *l)
{
  unsigned char data[4];
  if(borph_read(l, "iic_adc0", data, 8, 4, 50000) < 0){
    fprintf(stderr, "unable to read register\n");
    return -2;
  }
  return (data[2] << 8) | data[3];
}

int kat_adc_iic_reset(struct katcl_line *l)
{
  unsigned char data[4];
  data[0] = 0xff;
  data[1] = 0xff;
  data[2] = 0xff;
  data[3] = 0xff;
  if(borph_write(l, "iic_adc0", data, 8, 4, 50000) < 0){
    fprintf(stderr, "unable to write register\n");
    return -2;
  }
  return (data[1] << 8) | data[0];
}

#define BOOL(x) ((x) ? "TRUE " : "FALSE")

void kat_adc_decode_status(int s)
{
  printf("RXFIFO: empty = %s, full = %s, overflow = %s\n", BOOL(s & 0x1), BOOL(s & 0x2), BOOL(s & 0x4));
  printf("TXFIFO: empty = %s, full = %s, overflow = %s\n", BOOL(s & 0x10), BOOL(s & 0x20), BOOL(s & 0x40));
  printf("RX NACK error = %s\n", BOOL(s & 0x100));
}

int kat_adc_get_iic_reg(struct katcl_line *l, unsigned char dev_addr, unsigned char reg_addr, unsigned char* val)
{
  unsigned char data[4];
  /* careful - intel integers little endian */

  /* block operation fifo */
  data[3] = 0x1;
  if(borph_write(l, "iic_adc0", data, 12, 4, 50000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return 2;
  }

  data[0] = 0x00;
  data[1] = 0x00;
  data[2] = IIC_START | IIC_WRITE;
  data[3] = IIC_CMD(dev_addr, IIC_CMD_WR);

  if(borph_write(l, "iic_adc0", data, 0, 4, 50000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return 2;
  }

  data[0] = 0x00;
  data[1] = 0x00;
  data[2] = IIC_WRITE;
  data[3] = reg_addr;

  if(borph_write(l, "iic_adc0", data, 0, 4, 50000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return 2;
  }

  data[0] = 0x00;
  data[1] = 0x00;
  data[2] = IIC_START | IIC_WRITE;
  data[3] = IIC_CMD(dev_addr, IIC_CMD_RD);

  if(borph_write(l, "iic_adc0", data, 0, 4, 50000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return -2;
  }

  data[0] = 0x00;
  data[1] = 0x00;
  data[2] = IIC_STOP | IIC_READ;
  data[3] = 0x0;

  if(borph_write(l, "iic_adc0", data, 0, 4, 50000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return -2;
  }

  /* unblock operation fifo */
  data[3] = 0x0;
  if(borph_write(l, "iic_adc0", data, 12, 4, 50000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return 2;
  }

  usleep(20000); /* wait for the iic transaction to complete */

  if(borph_read(l, "iic_adc0", data, 4, 4, 50000) < 0){
    fprintf(stderr, "unable to read register\n");
    return -2;
  }
  (*val) = data[3];

  if (kat_adc_iic_status(l) & 0x100){
    kat_adc_iic_reset(l);
    return 1;
  }

  return 0;
}

int kat_adc_set_iic_reg(struct katcl_line *l, unsigned char dev_addr, unsigned char reg_addr, unsigned char val)
{
  unsigned char data[4];
  /* block operation fifo */
  data[3] = 0x1;
  if(borph_write(l, "iic_adc0", data, 12, 4, 50000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return 2;
  }

  /* careful - intel integers little endian */
  data[0] = 0x00;
  data[1] = 0x00;
  data[2] = IIC_START | IIC_WRITE;
  data[3] = IIC_CMD(dev_addr, IIC_CMD_WR);

  if(borph_write(l, "iic_adc0", data, 0, 4, 5000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return 2;
  }

  data[0] = 0x00;
  data[1] = 0x00;
  data[2] = IIC_WRITE;
  data[3] = reg_addr;

  if(borph_write(l, "iic_adc0", data, 0, 4, 5000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return 2;
  }
  data[0] = 0x00;
  data[1] = 0x00;
  data[2] = IIC_STOP | IIC_WRITE;
  data[3] = val;

  if(borph_write(l, "iic_adc0", data, 0, 4, 5000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return 2;
  }

  /* unblock operation fifo */
  data[3] = 0x0;
  if(borph_write(l, "iic_adc0", data, 12, 4, 50000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return 2;
  }


  usleep(20000); /* wait for the iic transaction to complete */


  if (kat_adc_iic_status(l) & 0x100){
    kat_adc_iic_reset(l);
    return 1;
  }

  return 0;
}

#define TMP421_A       0x4c
#define TMP421_REG_AMB 0x0
#define TMP421_REG_ADC 0x1

#define GPIOI_A 0x20
#define GPIOQ_A 0x21
#define GPIO_REG_OEN 0x6
#define GPIO_REG_OUT 0x2

#define GPIO_SW_DISABLE 0x80
#define GPIO_SW_ENABLE  0x00
#define GPIO_LATCH      0x40
#define GPIO_GAIN_0DB   0x3f

int kat_adc_set_reg(struct katcl_line *l, unsigned char which, unsigned short data, unsigned char addr)
{
  unsigned char buf[3];
  buf[0] = (data & 0xff00) >> 8;
  buf[1] = (data & 0x00ff) >> 0;
  buf[2] = addr;
  buf[3] = 0x1;
  if(borph_write(l, "adc_ctrl", buf, 4 + (which ? 4 : 0), 4, 50000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return 2;
  }
  return 0;
}

struct adc_reg{
  unsigned char addr;
  unsigned short data;
};

#define NUM_REG 9
struct adc_reg adc_reg_init [NUM_REG] = {
  {.addr =  0x0, .data = 0x7FFF},
  {.addr =  0x1, .data = 0xBAFF},
  //{.addr =  0x1, .data = 0xB2FF},
  {.addr =  0x2, .data = 0x007F},
  {.addr =  0x3, .data = 0x807F},
  {.addr =  0x9, .data = 0x03FF},
  {.addr =  0xa, .data = 0x007F},
  {.addr =  0xb, .data = 0x807F},
  {.addr =  0xe, .data = 0x00FF},
  {.addr =  0xf, .data = 0x007F}
};

int kat_config_adc(struct katcl_line *l, unsigned char which, int interleaved)
{
  unsigned char buf[3];
  int i;
  for (i = 0; i < NUM_REG; i++){
    kat_adc_set_reg(l, which, adc_reg_init[i].data, adc_reg_init[i].addr);
    usleep(1000);
  }

  /* TODO: interleaved */

  /* Set and Release Reset */
  buf[0] = 0x0;
  buf[1] = 0x0;
  buf[2] = 0x0;
  buf[3] = 0x3;
  if(borph_write(l, "adc_ctrl", buf, 0, 4, 50000) < 0){
    fprintf(stderr, "unable to write to register\n");
    return 2;
  }
  return 0;
};

#define SRC_ADC0_I 0x0
#define SRC_ADC0_Q 0x1
#define SRC_ADC1_I 0x2
#define SRC_ADC1_Q 0x3

#define BUF0_SRC(x) (((x)&0x3) << 0)
#define BUF1_SRC(x) (((x)&0x3) << 4)

int kat_adc_run_capture(struct katcl_line *l, unsigned char src0, unsigned char src1)
{
  unsigned char data[4];
  data[0] = 0x0;
  data[1] = 0x0;
  data[2] = BUF0_SRC(src0) | BUF1_SRC(src1);
  data[3] = 0x0;
  if(borph_write(l, "ctrl", data, 0, 4, 50000) < 0){
    fprintf(stderr, "unable to write register\n");
    return -2;
  }
  data[3] = 0x1;
  if(borph_write(l, "ctrl", data, 0, 4, 50000) < 0){
    fprintf(stderr, "unable to write register\n");
    return -2;
  }
  data[3] = 0x0;
  if(borph_write(l, "ctrl", data, 0, 4, 50000) < 0){
    fprintf(stderr, "unable to write register\n");
    return -2;
  }
  /* Wait for capture to finish (could check status[0] (DONE)) */
  usleep(50000);
  return 0;
}

int kat_adc_dump_buffer(struct katcl_line *l, int which, char* filename)
{
  int fd;
  int i;
  int ret;
  unsigned char* buffer[4096];

  if ((fd = open(filename, O_CREAT|O_WRONLY|O_TRUNC)) < 0){
    fprintf(stderr, "error: open failed - %s\n", strerror(errno));
  }

  /* Dump 64K data to file */
  for (i = 0; i < 4; i++) {
    if(borph_read(l, which ? "qdr1_memory" : "qdr0_memory", buffer, i*4096, 4096, 50000) < 0){
      fprintf(stderr, "unable to write register\n");
      close(fd);
      return -2;
    }
    if ((ret=write(fd, buffer, 4096)) < 0){
      fprintf(stderr, "error: write failed - %s\n", strerror(errno));
    } else if (ret < 4096) {
      fprintf(stderr, "error: wrote less than 4k\n");
    }
  }
  close(fd);
  return 0;
}


int main(int argc, char **argv)
{
  char *server = NULL;
  int fd;
  struct katcl_line *l;
  unsigned char iic_val;

  if(argc <= 0){
    server = getenv("KATCP_SERVER");
  } else {
    server = argv[1];
  }

  if(server == NULL){
    fprintf(stderr, "need a server as first argument or in the KATCP_SERVER variable\n");
    return 2;
  }

  fd = net_connect(server, 0, 1);
  if(fd < 0){
    fprintf(stderr, "unable to connect to %s\n", server);
    return 2;
  }

  l = create_katcl(fd);
  if(l == NULL){
    fprintf(stderr, "unable to allocate state\n");
    return 2;
  }

  /***************** IIC Config ********************/

  printf("ADC0: Performing IIC Operations\n");
  printf("\n");

  if (kat_adc_get_iic_reg(l, TMP421_A, TMP421_REG_AMB, &iic_val)){
    fprintf(stderr, "error: ambient temperature read failed\n");
  } else {
    printf("kat_adc:  ambient temp = %d C\n", iic_val);
  }

  if (kat_adc_get_iic_reg(l, TMP421_A, TMP421_REG_ADC, &iic_val)){
    fprintf(stderr, "error: core temperature read failed\n");
  } else {
    printf("kat_adc: adc core temp = %d C\n", iic_val);
  }

  printf("ADC0: Setting GPIO\n");
  if (kat_adc_set_iic_reg(l, GPIOI_A, GPIO_REG_OEN, 0x0)){
    fprintf(stderr, "error: GPIOI output-enable configuration failed\n");
  }

  if (kat_adc_set_iic_reg(l, GPIOQ_A, GPIO_REG_OEN, 0x0)){
    fprintf(stderr, "error: GPIOQ output-enable configuration failed\n");
  }

  if (kat_adc_set_iic_reg(l, GPIOI_A, GPIO_REG_OUT, GPIO_SW_DISABLE | GPIO_LATCH | GPIO_GAIN_0DB)){
    fprintf(stderr, "error: GPIOI output configuration failed\n");
  }

  if (kat_adc_set_iic_reg(l, GPIOQ_A, GPIO_REG_OUT, GPIO_SW_DISABLE | GPIO_LATCH | GPIO_GAIN_0DB)){
    fprintf(stderr, "error: GPIOQ output configuration failed\n");
  }

  printf("\n");

  if (kat_adc_iic_status(l) != 0x0011){
    printf("ADC0 IIC Controller Status Warning (Something went wrong):\n");
    kat_adc_decode_status(kat_adc_iic_status(l));
    kat_adc_iic_reset(l);
  }

  /***************** ADC Config ********************/
  printf("\n");
  printf("ADC0 Configuration\n");
  kat_config_adc(l, 0, 0);

  /************** Capture Start ********************/
  kat_adc_run_capture(l, SRC_ADC0_I, SRC_ADC0_Q);

  kat_adc_dump_buffer(l, 0, "adc_data0");
  kat_adc_dump_buffer(l, 1, "adc_data1");

  printf("Done\n");
  destroy_katcl(l, 1);

  return 0;
}
