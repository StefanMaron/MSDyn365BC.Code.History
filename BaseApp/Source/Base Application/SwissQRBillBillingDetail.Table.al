table 11503 "Swiss QRBill Billing Detail"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'moved to Swiss QR-Bill extension 11518 Swiss QR-Bill Billing Detail';
    ObsoleteTag = '18.0';

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Format Code"; Code[10]) { }
        field(3; "Tag Code"; Code[10]) { }
        field(4; "Tag Value"; Text[100]) { }
        field(5; "Tag Type"; Option)
        {
            OptionMembers = Unknown,"Document No.","Document Date","Creditor Reference","VAT Registration No.","VAT Date","VAT Details","VAT Purely On Import","Payment Terms";
        }
        field(6; "Tag Description"; Text[100]) { }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
