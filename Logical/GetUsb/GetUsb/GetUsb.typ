(********************************************************************
 * COPYRIGHT -- BuR
 ********************************************************************
 * Program: checkusb
 * File: checkusb.typ
 * Author: geertsc
 * Created: April 15, 2009
 ********************************************************************
 * Local data types of program checkusb
 ********************************************************************)

TYPE
	UsbStep_type : 
		(
		USBWAIT,
		USBCHECK,
		USBGETNODE,
		USBCHECKDEVICE,
		USBUNLINK,
		USBLINK,
		USBERROR
		);
END_TYPE
