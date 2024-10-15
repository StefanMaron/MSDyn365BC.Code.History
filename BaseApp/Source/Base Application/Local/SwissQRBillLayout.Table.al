table 11505 "Swiss QRBill Layout"
{
    ObsoleteState = Removed;
    ObsoleteReason = 'moved to Swiss QR-Bill extension table 11513 Swiss QR-Bill Layout';
    ObsoleteTag = '18.0';
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "IBAN Type"; Option)
        {
            OptionMembers = IBAN,"QR-IBAN";
        }
        field(4; "Unstr. Message"; Text[140]) { }
        field(5; "Billing Information"; Code[20]) { }
        field(6; "Payment Reference Type"; Option)
        {
            OptionMembers = "Without Reference","Creditor Reference (ISO 11649)","QR Reference";
        }
        field(7; "Alt. Procedure Name 1"; Text[10]) { }
        field(8; "Alt. Procedure Value 1"; Text[100]) { }
        field(9; "Alt. Procedure Name 2"; Text[10]) { }
        field(10; "Alt. Procedure Value 2"; Text[100]) { }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
