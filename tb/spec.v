/*
Packets
	Token
		<SYNC><PID><ADDR><CRC5><EOP>
		PID - setup, in , out
	SOF
		<SYNC><PID><FRAME NUMBER><CRC5><EOP>
		PID - sof
	Data
		<SYNC><PID><DATA><CRC16><EOP>
		PID - data0, data1
		DATA 0-1023 bytes
	Handshake
		<SYNC><PID><EOP>
		PID - ack, nak, stall
		

Transaction ends:
  ack:          transaction ok 
  nak:          ep is busy, need to retry transaction
  no response:  error in packet, need to retry transaction,
                from SE0-J to J-K pass in 16-18 bit times.
  stall:        ep is halt, need ?
                functional stall when halt feature is setted (ch.9).
                  A special case of the functional stall is the “commanded stall.” Commanded
                  stall occurs when the host explicitly sets the endpoint’s Halt feature, as detailed in Chapter 9. Once a
                  function’s endpoint is halted, the function must continue returning STALL until the condition causing the
                  halt has been cleared through host intervention.
                The second case, known as “protocol stall,” is detailed in Section 8.5.2. Protocol stall is unique to control
                pipes. Protocol stall differs from functional stall in meaning and duration. A protocol STALL is returned
                during the Data or Status stage of a control transfer, and the STALL condition terminates at the beginning
                of the next control transfer (Setup). The remainder of this section refers to the general case of a functional
                stall. STALL indicates that the function has an error that prevents it from completing the command.
                The protocol stall condition lasts until the receipt of the next SETUP transaction and the
                function will return STALL in response to any IN or OUT transaction on the pipe until the SETUP
                transaction is received. In general, protocol stall indicates that the request or its parameters is not
                understood by the device and thus provides a mechanism for extending USB requests.
                A control pipe may also support functional stall as well, but this is not recommended. This is a
                degenerative case, because a functional stall on a control pipe indicates that it has lost the ability to
                communicate with the host. If the control pipe does support functional stall, then it must possess a Halt
                feature, which can be set or cleared by the host. Chapter 9 details how to treat the special case of a Halt
                feature on a control pipe. A well-designed device will associate all of its functions and Halt features with
                non-control endpoints. The control pipes should be reserved for servicing USB requests.
                
                  

False EOP - host must wait 16 bit time.
    
Transactions
	Bulk transfer
		OUT - from host to func
			Host <Token packet(out)>
			Host <Data packet(data0 | data1)>
			Func <Handshake packet(ack | nak | stall) | No response>
		IN - from func to host
			Host <Token packet(in)>
			Func <Data packet(data0 | data1) | Handshake packet(stall | nak) | No response if no recognize in-token>
			Host <Handshake packet(ack) | No response>
		Toggle sync. Conf event reset to data0, then data1 data0 ...
	
  Control transfer
  Setup phase  
    SETUP
      Host <Token packet(setup)>
      Host <Data packet(data0)>
      Func <Handshake packet(ack) | No response>
	
  Data phase
    Same as bulk transfer
  
	Status phase
		IN
			Host <Token packet(in)>
			Func <Zero-length Data packet(data1) | Handshake packet(stall | nak) | No response if no recognize in-token>
			Host <Handshake packet(ack) | No response>
		OUT
			Host <Token packet(out)>
			Host <Zero-length Data packet(data1)>
			Func <Handshake packet(ack | nak | stall)>
	
	Interrupt transfer
		OUT - from host to func
			Host <Token packet(out)>
			Host <Data packet(data0 | data1)>
			Func <Handshake packet(ack | nak | stall) | No response>
		IN - from func to host
			Host <Token packet(in)>
			Func <Data packet(data0 | data1) | Handshake packet(stall | nak) | No response if no recognize in-token>
			Host <Handshake packet(ack) | No response>
		Mode: to communicate rate feedback information. Toggle bit always toggle.

	Isochronous transfer
		OUT - from host to func
			Host <Token packet(out)>
			Host <Data packet(data0)>
		IN - from func to host
			Host <Token packet(in)>
			Func <Data packet(data0)>
		Host and func must receive pid = data0 | data1.
		
Transfers
	Bulk
		<Bulk transaction>...<Bulk transaction>
		
		Full-speed only
		EP wMaxPacketSize = 8,16,32,64
	Control
		<Setup transaction>
		<Bulk transaction same direction>...<Bulk transaction same direction>
		<Status transaction inverse direction>
		
		bidirectional EP
		EP wMaxPacketSize(full-speed) = 8,16,32,64
		EP wMaxPacketSize(low-speed) = 8
		can be retried in current frame
		
	Interrupt
		<Interrupt transaction>...<Interrupt transaction>
		
		EP wMaxPacketSize(full-speed) = up to 64
		EP wMaxPacketSize(low-speed) = up to 8
		Interrupt transfers are moved over the USB by accessing an interrupt endpoint every period (set in congiguration).
	Isochronous
		<Isochronous transaction>...<Isochronous transaction>

		Full-speed only
		? EP wMaxPacketSize up to 1023
		
Device states
	Attached
        Connect cable. 
        If external-powered device - wait usb-reset.
        If USB-powered device - no power.
	Powered
        If external-powered device - wait usb-reset.
        If USB-powered device - wait usb-reset.
	Default
        Answer on default addr transfer
        Wait unique addr
	Addressed
        Answer on unique addr transfer
        Wait config
	Configured
        Configuration Interface EP is default state
        Normal transfers
	Suspended
        No bus activity for 3 ms.
		Limit power from Vbus. Chapter 7.
        Optional remote wakeup signaling (on reset is disabled): signaling
        to host for bus activity.
	
Bus enumeration
	1. Host informed about attach device by hub. Device in Powered state.
	2. Host query hub. Wait 100 ms for power stability.
	3. Host issues a port enable and reset command to that hub port. 7.1.7.1 fig. 7-19
	4. Hub maintains the reset signal to that port for 10-20 ms (See Section 11.5.1.5). When the reset signal is released, the port has been enabled. The USB device is now in the Default state and can draw no more than 100mA from VBUS.
    -wait 10 reset recover
	6. The host reads the device descriptor to determine what actual maximum data payload size this USB device’s default pipe can use.
	5. The host assigns a unique address to the USB device, moving the device to the Address state.
	7. The host reads the configuration information from the device by reading each configuration zero to n-1, where n is the number of configurations.
	8. Based on the configuration information and how the USB device will be used, the host assigns a configuration value to the device. The device is now in the Configured state and all of the endpoints in this configuration have taken on their described characteristics. The USB device may now draw the
    amount of VBUS power described in its descriptor for the selected configuration.
	
configurations
	interfaces
		alternate settings
		
Operations
	Reseting
	Addressing
	Configuration
	Data transfer
	
Request Processing
	With the exception of SetAddress() requests (see Section 9.4.6), a device may begin processing of a request as soon as the device returns the ACK following the Setup. The device is expected to “complete” processing of the request before it allows the Status stage to complete successfully.
	
	All devices are expected to handle requests in a timely manner. USB sets an upper limit of 5 seconds as the upper limit for any command to be processed.
	
	Standard Requests
		All standard requests are maked through control transfer.
		Type and parameter of request (8 bytes) are in Data packet of Setup transaction. 
		
		Set Address
			If a device receives a SetAddress() request, the device must be able to complete processing of the request and be able to successfully complete the Status stage of the request within 50 ms. In the case of the SetAddress() request, the Status stage successfully completes when	the devices sends the zero-length Status packet or when the device sees the ACK in response to the Status stage data packet.
			After successful completion of the Status stage, the device is allowed a SetAddress() recovery interval of 2 ms. At the end of this interval, the device must be able to accept Setup packets addressed to the new address. Also, at the end of the recovery interval the device must not respond to tokens sent to the old address (unless, of course, the old and new address is the same.)
	
  
  CLIENT -- USB DRIVER -- HOST CONTROLLER -- USB DEVICE -- FUNCTION
  Device configuration
  USB configuration
  Function configuration
  Client set fot pipe:
    -max data size
    -max service interval
  Client view data as contiguous stream.
  Pipe 
    active
    halted
  Aborting a Pipe: All of the IRPs scheduled for a pipe are retired immediately and returned to the client
with a status indicating they have been aborted. Neither the host state nor the reflected endpoint state
of the pipe is affected.
 Resetting a Pipe: The pipe’s IRPs are aborted. The host state is moved to Active. If the reflected
endpoint state needs to be changed, that must be commanded explicitly by the USBD client.
 Clearing a Halted pipe: The pipe's state is cleared from Halted to Active.
 Halting a pipe: The pipe's state is set to Halted.  

Clients provide full buffers to outgoing pipes and retrieve transfer status information following the
completion of a request. The transfer status returned for an outgoing pipe allows the client to determine the
success or failure of the transfer.
Clients provide empty buffers to incoming pipes and retrieve the filled buffers and transfer status
information from incoming pipes following the completion of a request. The transfer status returned for an
incoming pipe allows a client to determine the amount and the quality of the data received.

The USBD provides clients with pipe error recovery mechanisms by allowing pipes to be reset or aborted.
*/
