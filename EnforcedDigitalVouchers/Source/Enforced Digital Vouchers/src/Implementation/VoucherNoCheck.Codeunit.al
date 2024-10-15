codeunit 5582 "Voucher No Check" implements "Digital Voucher Check"
{
    // Default implementation of the interface when no check or generation of digital voucher is required        
    Access = Internal;

    procedure CheckVoucherIsAttachedToDocument(var ErrorMessageMgt: Codeunit "Error Message Management"; DigitalVoucherEntryType: Enum "Digital Voucher Entry Type"; RecRef: RecordRef)
    begin

    end;

    procedure GenerateDigitalVoucherForPostedDocument(DigitalVoucherEntryType: Enum "Digital Voucher Entry Type"; RecRef: RecordRef)
    begin

    end;
}
