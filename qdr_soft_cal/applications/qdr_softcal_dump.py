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

def qdr_bitdump(fpga, qdr_cal):
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
      print '%d: '%(j),
      #select bit
      fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x0,j), 0x4)
      #reset dll
      fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x0,0x4), 0x8)
      fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x0,0x0), 0x8)
      for i in range(0,63):
        fpga.blindwrite(qdr_cal, '%c%c%c%c'%(0x0,0x0,0x0,0x3), 0x8)
        status = numpy.fromstring(fpga.read(qdr_cal,16,0), count=16, dtype='int8')
        print '%d'%(status[14]),
      print ''

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

    fpga.progdev(bitstream)
    print 'prog ok'
    fpga.write_int('sys_scratchpad', 0xdeadbeef)
    print 'qdr0:'
    qdr_bitdump(fpga,'qdr0_cal');
    print 'qdr1:'
    qdr_bitdump(fpga,'qdr1_cal');
      
    time.sleep(0)

except KeyboardInterrupt:
    exit_clean()
except:
    exit_fail()

exit_clean()

