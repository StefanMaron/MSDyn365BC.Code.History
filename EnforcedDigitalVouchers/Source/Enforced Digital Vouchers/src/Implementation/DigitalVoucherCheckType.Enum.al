enum 5580 "Digital Voucher Check Type" implements "Digital Voucher Check"
{
    Extensible = true;

    DefaultImplementation = "Digital Voucher Check" = "Voucher No Check";
    UnknownValueImplementation = "Digital Voucher Check" = "Voucher Unknown Check";

    value(0; "No Check")
    {
        Caption = 'No Check';
        Implementation = "Digital Voucher Check" = "Voucher No Check";
    }
    value(1; "Attachment")
    {
        Caption = 'Attachment';
        Implementation = "Digital Voucher Check" = "Voucher Attachment Check";
    }
    value(2; "Attachment or Note")
    {
        Caption = 'Attachment or Note';
        Implementation = "Digital Voucher Check" = "Voucher Attach Or Note Check";
    }
}
