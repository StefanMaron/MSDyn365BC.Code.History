codeunit 5583 "Voucher Unknown Check" implements "Digital Voucher Check"
{
    Access = Internal;

    var
        NotPossibleToPerformErr: Label 'Not possible to perform a check of this type';

    procedure CheckVoucherIsAttachedToDocument(var ErrorMessageMgt: Codeunit "Error Message Management"; DigitalVoucherEntryType: Enum "Digital Voucher Entry Type"; RecRef: RecordRef)
    begin
        Error(NotPossibleToPerformErr);
    end;

    procedure GenerateDigitalVoucherForPostedDocument(DigitalVoucherEntryType: Enum "Digital Voucher Entry Type"; RecRef: RecordRef)
    begin
        Error(NotPossibleToPerformErr);
    end;
}
