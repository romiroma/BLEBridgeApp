//
//  BLESerial.cpp
//  BLESerial
//
//  Created by Roman on 27.06.2023.
//

#include <os/log.h>

#include <SerialDriverKit/SerialPortInterface.h>
#include <SerialDriverKit/IOUserSerial.h>
#include <DriverKit/IOLib.h>
#include <DriverKit/IOMemoryDescriptor.h>
#include <DriverKit/IOBufferMemoryDescriptor.h>
#include <time.h>
#include "BLESerial.h"

#define Log(fmt, ...) os_log(OS_LOG_DEFAULT, "BLESerial - " fmt "\n", ##__VA_ARGS__)

constexpr int bufferSize = 2048;

using SerialPortInterface = driverkit::serial::SerialPortInterface;

struct BLESerial_IVars
{
    IOBufferMemoryDescriptor *ifmd, *rxq, *txq;
    SerialPortInterface *interface;
    uint64_t rx_buf, tx_buf;
    bool dtr, rts;
};

bool BLESerial::init(void)
{
    bool result = false;
    result = super::init();
    if (result != true)
    {
        goto Exit;
    }
    ivars = IONewZero(BLESerial_IVars, 1);
    if (ivars == nullptr)
    {
        goto Exit;
    }
    kern_return_t ret;
    ret = ivars->rxq->Create(kIOMemoryDirectionInOut, bufferSize, 0, &ivars->rxq);
    if (ret != kIOReturnSuccess) {
        goto Exit;
    }
    ret = ivars->txq->Create(kIOMemoryDirectionInOut, bufferSize, 0, &ivars->txq);
    if (ret != kIOReturnSuccess) {
        goto Exit;
    }
    IOAddressSegment ioaddrseg;
    ivars->rxq->GetAddressRange(&ioaddrseg);
    ivars->rx_buf = ioaddrseg.address;
    ivars->txq->GetAddressRange(&ioaddrseg);
    ivars->tx_buf = ioaddrseg.address;
    return true;
Exit:
    return false;
}

void BLESerial::free(void)
{
    super::free();
}

bool BLESerial::initWith(IOBufferMemoryDescriptor *ifmd)
{
    bool result = false;
    ivars = IONewZero(BLESerial_IVars, 1);
    if (ivars == nullptr)
    {
        goto Exit;
    }
    result = super::initWith(ifmd);
    if (result != true)
    {
        goto Exit;
    }

    kern_return_t ret;
    ret = ivars->rxq->Create(kIOMemoryDirectionInOut, bufferSize, 0, &ivars->rxq);
    if (ret != kIOReturnSuccess) {
        goto Exit;
    }
    ret = ivars->txq->Create(kIOMemoryDirectionInOut, bufferSize, 0, &ivars->txq);
    if (ret != kIOReturnSuccess) {
        goto Exit;
    }
    IOAddressSegment ioaddrseg;
    ivars->rxq->GetAddressRange(&ioaddrseg);
    ivars->rx_buf = ioaddrseg.address;
    ivars->txq->GetAddressRange(&ioaddrseg);
    ivars->tx_buf = ioaddrseg.address;
    return true;
Exit:
    return false;
}

kern_return_t IMPL(BLESerial, HwActivate)
{
    kern_return_t ret;
    ret = HwActivate(SUPERDISPATCH);
    if (ret != kIOReturnSuccess) {
        goto Exit;
    }
    // Loopback, set CTS to RTS, set DSR and DCD to DTR
    ret = SetModemStatus(ivars->rts, ivars->dtr, false, ivars->dtr);
    if (ret != kIOReturnSuccess) {
        goto Exit;
    }
Exit:
    return ret;
}

kern_return_t IMPL(BLESerial, HwDeactivate)
{
    kern_return_t ret;
    ret = HwDeactivate(SUPERDISPATCH);
    if (ret != kIOReturnSuccess) {
        goto Exit;
    }
Exit:
    return ret;
}

kern_return_t IMPL(BLESerial, Start)
{
    kern_return_t ret;
    ret = Start(provider, SUPERDISPATCH);
    if (ret != kIOReturnSuccess) {
        return ret;
    }
    IOMemoryDescriptor *rxq_, *txq_;
    ret = ConnectQueues(&ivars->ifmd, &rxq_, &txq_, ivars->rxq, ivars->txq, 0, 0, 11, 11);
    if (ret != kIOReturnSuccess) {
        return ret;
    }
    IOAddressSegment ioaddrseg;
    ivars->ifmd->GetAddressRange(&ioaddrseg);
    ivars->interface = reinterpret_cast<SerialPortInterface*>(ioaddrseg.address);
    SerialPortInterface &intf = *ivars->interface;
    ret = RegisterService();

    if (ret != kIOReturnSuccess) {
        goto Exit;
    }
    TxFreeSpaceAvailable();
Exit:
    return ret;
}

kern_return_t IMPL(BLESerial, Stop)
{
    kern_return_t ret;
    ret = Stop(provider, SUPERDISPATCH);
    return ret;
}

void IMPL(BLESerial, TxDataAvailable)
{
    SerialPortInterface &intf = *ivars->interface;
    // Loopback
    // FIXME consider wrapped case
    size_t tx_buf_sz = intf.txPI - intf.txCI;
    void *src = reinterpret_cast<void *>(ivars->tx_buf + intf.txCI);
//    char src[] = "Hello, World!";
    void *dest = reinterpret_cast<void *>(ivars->rx_buf + intf.rxPI);
    memcpy(dest, src, tx_buf_sz);
    intf.rxPI += tx_buf_sz;

    RxDataAvailable();
    intf.txCI = intf.txPI;
    TxFreeSpaceAvailable();
    Log("[TX Buf]: %{public}s", reinterpret_cast<char *>(ivars->tx_buf));
    Log("[RX Buf]: %{public}s", reinterpret_cast<char *>(ivars->rx_buf));
    // dmesg confirms both buffers are all-zero
    Log("[TX] txPI: %d, txCI: %d, rxPI: %d, rxCI: %d, txqoffset: %d, rxqoffset: %d, txlogsz: %d, rxlogsz: %d",
        intf.txPI, intf.txCI, intf.rxPI, intf.rxCI, intf.txqoffset, intf.rxqoffset, intf.txqlogsz, intf.rxqlogsz);
}

void IMPL(BLESerial, RxFreeSpaceAvailable)
{
    Log("RxFreeSpaceAvailable() called!");
}

kern_return_t IMPL(BLESerial,HwResetFIFO){
    Log("HwResetFIFO() called with tx: %d, rx: %d!", tx, rx);
    kern_return_t ret = kIOReturnSuccess;
    return ret;
}

kern_return_t IMPL(BLESerial,HwSendBreak){
    Log("HwSendBreak called!");
    kern_return_t ret = kIOReturnSuccess;
    return ret;
}

kern_return_t IMPL(BLESerial,HwProgramUART){
    Log("HwProgramUART, BaudRate: %u, nD: %d, nS: %d, P: %d!", baudRate, nDataBits, nHalfStopBits, parity);
    kern_return_t ret = kIOReturnSuccess;
    return ret;
}


kern_return_t IMPL(BLESerial,HwProgramBaudRate){
    Log("HwProgramBaudRate, BaudRate = %d!", baudRate);
    kern_return_t ret = kIOReturnSuccess;
    return ret;
}

kern_return_t IMPL(BLESerial,HwProgramMCR){
    Log("HwProgramMCR, DTR: %d, RTS: %d!", dtr, rts);
    ivars->dtr = dtr;
    ivars->rts = rts;
    kern_return_t ret = kIOReturnSuccess;
Exit:
    return ret;
}

kern_return_t IMPL(BLESerial, HwGetModemStatus){
    *cts = ivars->rts;
    *dsr = ivars->dtr;
    *ri = false;
    *dcd = ivars->dtr;
    Log("HwGetModemStatus CTS=%d, DSR=%d, RI=%d, DCD=%d!", *cts, *dsr, *ri, *dcd);
    kern_return_t ret = kIOReturnSuccess;
    return ret;
}

kern_return_t IMPL(BLESerial,HwProgramLatencyTimer){
    Log("HwProgramLatencyTimer");
    kern_return_t ret = kIOReturnSuccess;
    return ret;
}

kern_return_t IMPL(BLESerial,HwProgramFlowControl){
    Log("HwProgramFlowControl arg: %u, xon: %d, xoff: %d", arg, xon, xoff);
    kern_return_t ret = kIOReturnSuccess;
Exit:
    return ret;
}
