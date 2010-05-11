#!/usr/bin/env python
'''
'''

import corr,time,numpy,struct,sys,logging,pylab

bitstream = 'qdr_soft_cal.bof'
katcp_port=7147

def exit_fail():
    print 'FAILURE DETECTED. Log entries:\n',lh.printMessages()
    try:
        fpga.stop()
    except: pass
    raise
    exit()

def exit_clean():
    try:
        fpga.stop()
    except: pass
    exit()

def data_vld(d):
  if (d == 0x1 or d == 0x2) :
    return 1;
  return 0;

def qdr_test(fpga):
  status = numpy.fromstring(fpga.read('stat',4,0), count=4, dtype='int8')
  fpga.write_int('ctrl',  0x0)
  fpga.write_int('ctrl',  0x1)
  fpga.write_int('ctrl',  0x0)
  fpga.write_int('ctrl',  0x2)
  fpga.write_int('ctrl',  0x0)
  time.sleep(0.1)


  checklength=16
  if (status[3] & 0x2):
    print 'qdr0_fail'
  data = numpy.fromstring(fpga.read('qdr0_memory',checklength*4,0), count=checklength, dtype='>I')
  print data

  if (status[3] & 0x4):
    print 'qdr1_fail'
  data = numpy.fromstring(fpga.read('qdr1_memory',checklength*4,0), count=checklength, dtype='>I')
  print data
  

def software_calibrate(fpga, qdr_cal):
    #turn dll on
    fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x1,0x0), 0x0)
    time.sleep(0.01);
    #turn dll off
    fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x0,0x0), 0x0)
    time.sleep(0.01);
    #turn dll on
    fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x1,0x0), 0x0)
    time.sleep(0.01);

    #enable calibration
    fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x1,0x1), 0x0)
    time.sleep(0.01);

    #check cal rdy
    status = numpy.fromstring(fpga.read(qdr_cal,16,0), count=16, dtype='int8')
    if (status[12] != 0x1):
      print 'Error: no cal rdy'


    for j in range(0,18):
      #print '%d: '%(j)
      #select bit
      fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x0,j), 0x4)
      #reset dll
      fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x0,0x4), 0x8)
      fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x0,0x0), 0x8)
      time.sleep(0.01);

      prev=0
      hist0=0;
      hist1=0;
      hist2=0;
      baddies=0;
      progress = 0;

      for i in range(0,63):
        fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x0,0x3), 0x8)
        status = numpy.fromstring(fpga.read(qdr_cal,16,0), count=16, dtype='int8')
        if (not status[14]):
          curr = 0
        else:
          curr = status[15]
        #print 'i = %d: curr = %d, prev = %d, hist[0,1,2] = %d,%d,%d'%(i,curr,prev,hist0,hist1,hist2)

        data_stable = data_vld(curr) and data_vld(hist0)and hist0 == hist1 and hist2 == hist1

        if (data_stable):
          if (not data_vld(prev)):
            prev = curr;
            #print 'leading stable value found at %d'%(i)
          else:
            if prev != curr:
              #print 'leading stable edge found at %d'%(i)
              progress = i;
              break;
        else:
          if (data_vld(prev)):
            baddies=baddies+1

        hist2 = hist1
        hist1 = hist0
        hist0 = curr

        if (i==63):
          print 'calfail: bit %d - no edge found'%(j)

      headroom = 8
      history_length = 3
      #print 'pivot edge found at %d and %d baddies'%(progress, baddies-history_length)
      if (progress + headroom - history_length < 63):
        #go forwards
        #print 'going forward %d'%(headroom-history_length)
        for i in range(0,headroom-history_length):
          fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x0,0x3), 0x8)
      else:
        #go backwards
        #print 'going back %d'%(headroom+baddies-history_length)
        if (progress - headroom - hsitory_length < 0):
          print 'calfail: bit %d - no space to find edge'%(j)
        for i in range(0,headroom+baddies-history_length):
          fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x0,0x1), 0x8)

      status = numpy.fromstring(fpga.read(qdr_cal,16,0), count=16, dtype='int8')
      if (not status[14] or not data_vld(status[15])):
        print 'calfail: bit %d - invalid data'%(j)

      #check if the data is aligned
      if (status[15] != 0x2):
        fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x1,0x0), 0x8)
      else:
        fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x0,0x0), 0x8)

    #disable calibration
    fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x1,0x0), 0x0)
    time.sleep(0.01);


#START OF MAIN:

if __name__ == '__main__':
    from optparse import OptionParser

    p = OptionParser()
    p.set_usage('test_dram.py <ROACH_HOSTNAME_or_IP> [options]')
    p.set_description(__doc__)
    p.add_option('-s', '--skip', dest='skip', action='store_true',
        help='Skip reprogramming the FPGA and configuring EQ.')
    opts, args = p.parse_args(sys.argv[1:])

    if args==[]:
        print 'Please specify a ROACH board. Run with the -h flag to see all options.\nExiting.'
        exit()
    else:
        roach = args[0]

try:
    loggers = []
    lh=corr.log_handlers.DebugLogHandler()
    logger = logging.getLogger(roach)
    logger.addHandler(lh)
    logger.setLevel(10)

    #print('Connecting to server %s on port %i... '%(roach,katcp_port)),
    fpga = corr.katcp_wrapper.FpgaClient(roach, katcp_port, timeout=10,logger=logger)
    time.sleep(0.5)

    if fpga.is_connected():
        i=0;
    else:
        print 'ERROR connecting to server %s on port %i.\n'%(roach,katcp_port)
        exit_fail()

    #fpga.progdev('')
    #time.sleep(1)
    fpga.progdev(bitstream)
    print 'prog ok'
    fpga.write_int('sys_scratchpad', 0xdeadbeef)
    print 'calibrating qdr0'
    software_calibrate(fpga, 'qdr0_cal');
    print 'calibrating qdr1'
    software_calibrate(fpga, 'qdr1_cal');
    print 'testing qdrs'
    print '0'
    qdr_test(fpga);
    print '1'
    qdr_test(fpga);
    print '2'
    qdr_test(fpga);
    print '3'
    qdr_test(fpga);
    print '4'
    qdr_test(fpga);
    print '5'
    qdr_test(fpga);
      
    time.sleep(0)

except KeyboardInterrupt:
    exit_clean()
except:
    exit_fail()

exit_clean()

