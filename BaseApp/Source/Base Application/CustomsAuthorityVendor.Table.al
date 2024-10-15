table 12122 "Customs Authority Vendor"
{
    Caption = 'Customs Authority Vendor';
    LookupPageID = "Customs Authority Vendors";

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(2; Name; Text[30])
        {
            CalcFormula = Lookup (Vendor.Name WHERE("No." = FIELD("Vendor No.")));
            Caption = 'Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Vendor No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure LookupEntryNo(CAEntryNo: Integer): Integer
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if CAEntryNo <> 0 then
            if VendLedgEntry.Get(CAEntryNo) then
                Get(VendLedgEntry."Vendor No.");
        if PAGE.RunModal(0, Rec) = ACTION::LookupOK then begin
            VendLedgEntry.SetRange("Vendor No.", "Vendor No.");
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
            if PAGE.RunModal(0, VendLedgEntry, VendLedgEntry."Document No.") = ACTION::LookupOK then
                exit(VendLedgEntry."Entry No.");
        end;
        exit(CAEntryNo);
    end;
}

