(********************************************************************
 * COPYRIGHT -- BuR
 ********************************************************************
 * Program: checkusb
 * File: checkusb.st
 * Author: geertsc
 * Created: April 15, 2009
 ********************************************************************
 * Implementation of program checkusb
 ********************************************************************)
PROGRAM _CYCLIC

CASE UsbStep OF
	
	USBWAIT:
		TON_0.IN := TRUE;
		TON_0.PT := T#5s;
		IF (TON_0.Q) THEN
			TON_0.IN := FALSE;
			UsbStep := USBCHECK;
		END_IF
		TON_0();

	USBCHECK:	
		(* Check for usb-stick *)
		UsbNodeListGetFub.enable := TRUE;
		UsbNodeListGetFub.pBuffer := ADR(usbNodeList);
		UsbNodeListGetFub.bufferSize := SIZEOF(usbNodeList);
					
		(* optional use OF filters (z.B. MASS_STORAGE == 0x08)*)
		UsbNodeListGetFub.filterInterfaceClass := asusb_CLASS_MASS_STORAGE;
		UsbNodeListGetFub.filterInterfaceSubClass := asusb_SUBCLASS_SCSI_COMMAND_SET;
					
		UsbNodeListGetFub();
		IF (UsbNodeListGetFub.status = 0) THEN
			usbAttachDetachCount := UsbNodeListGetFub.attachDetachCount;
			UsbStep := USBGETNODE;
		ELSIF (UsbNodeListGetFub.status <> 65535) THEN
			UsbStep := USBERROR; (* Try to Unlink at usb problem *)
		END_IF
					
	USBGETNODE:
	    UsbNodeGetFub.enable := TRUE;
	    (* First DeviceID from UsbNodeListGet() *)
	    UsbNodeGetFub.nodeId := usbNodeList[0] ;			
	    UsbNodeGetFub.pBuffer := ADR(usbDevice);
	    UsbNodeGetFub.bufferSize := SIZEOF(usbDevice);
	    UsbNodeGetFub();
	   	IF (UsbNodeGetFub.status = 0 ) THEN
	   		UsbStep := USBCHECKDEVICE;
	   	ELSIF (UsbNodeGetFub.status <> 65535) THEN
			UsbStep := USBERROR; (* Unlink at usb problem *)
		END_IF
					
	USBCHECKDEVICE:
		szDevParamName := '/DEVICE=';
		szDevParamName := CONCAT(szDevParamName,usbDevice.ifName);
		IF 	(UsbHandle = 0) THEN
			UsbStep := USBLINK;
			usbDeviceOld := usbDevice;
		ELSIF
			(usbDevice.ifName <> usbDeviceOld.ifName) OR
			(usbDevice.bcdDevice <> usbDeviceOld.bcdDevice) OR
			(usbDevice.interfaceClass <> usbDeviceOld.interfaceClass) OR
			(usbDevice.interfaceProtocol <> usbDeviceOld.interfaceProtocol) OR
			(usbDevice.interfaceSubClass <> usbDeviceOld.interfaceSubClass) OR
			(usbDevice.productId <> usbDeviceOld.productId) OR
			(usbDevice.vendorId <> usbDeviceOld.vendorId) 
		THEN
			usbDeviceOld := usbDevice;
			UsbStep := USBUNLINK;
		ELSE
			UsbStep := USBWAIT; (* Dezelfde Usbstick *)
		END_IF
		
	USBUNLINK:
		IF (UsbHandle <> 0)  THEN
			(* unlink file device *)
			DevUnlink_0.enable := TRUE;
			DevUnlink_0.handle := UsbHandle;
			DevUnlink_0();
			IF (DevUnlink_0.status = 0) THEN
				UsbHandle := 0;
				UsbStep := USBLINK;
			ELSIF (DevUnlink_0.status <> 65535) THEN
				UsbStep := USBWAIT;
			END_IF
		ELSE
			UsbStep := USBLINK;
		END_IF
	
	USBLINK:
		(* link file device *)
		DevLink_0.enable := TRUE;
		DevLink_0.pDevice := ADR(ifName);
		DevLink_0.pParam := ADR(szDevParamName);
		DevLink_0();
	   	IF (DevLink_0.status = 0) OR (DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST) THEN
			UsbStep := USBWAIT;
			UsbHandle := DevLink_0.handle;
		ELSIF (DevLink_0.status <> 65535) THEN
			UsbStep := USBWAIT;
		END_IF

	USBERROR:
		IF (UsbHandle <> 0)  THEN
			(* unlink file device *)
			DevUnlink_0.enable := TRUE;
			DevUnlink_0.handle := UsbHandle;
			DevUnlink_0();
			IF (DevUnlink_0.status <> 65535) THEN
				UsbHandle := 0;
				UsbStep := USBWAIT;
			END_IF
		ELSE
			UsbStep := USBWAIT;
		END_IF
		
END_CASE
END_PROGRAM
