table 247 "Intrastat Setup"
{
    Caption = 'Intrastat Setup';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Report Receipts"; Boolean)
        {
            Caption = 'Report Receipts';
        }
        field(3; "Report Shipments"; Boolean)
        {
            Caption = 'Report Shipments';
        }
        field(4; "Default Trans. - Purchase"; Code[10])
        {
            Caption = 'Default Trans. Type';
            TableRelation = "Transaction Type";
        }
        field(5; "Default Trans. - Return"; Code[10])
        {
            Caption = 'Default Trans. Type - Returns';
            TableRelation = "Transaction Type";
        }
        field(6; "Intrastat Contact Type"; Option)
        {
            Caption = 'Intrastat Contact Type';
            OptionCaption = ' ,Contact,Vendor';
            OptionMembers = " ",Contact,Vendor;

            trigger OnValidate()
            begin
                if "Intrastat Contact Type" <> xRec."Intrastat Contact Type" then
                    Validate("Intrastat Contact No.", '');
            end;
        }
        field(7; "Intrastat Contact No."; Code[20])
        {
            Caption = 'Intrastat Contact No.';
            TableRelation = IF ("Intrastat Contact Type" = CONST(Contact)) Contact."No."
            ELSE
            IF ("Intrastat Contact Type" = CONST(Vendor)) Vendor."No.";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        OnDelIntrastatContactErr: Label 'You cannot delete contact number %1 because it is set up as an Intrastat contact in the Intrastat Setup window.', Comment = '1 - Contact No';
        OnDelVendorIntrastatContactErr: Label 'You cannot delete vendor number %1 because it is set up as an Intrastat contact in the Intrastat Setup window.', Comment = '1 - Vendor No';

    procedure CheckDeleteIntrastatContact(ContactType: Option; ContactNo: Code[20])
    begin
        if (ContactNo = '') or (ContactType = "Intrastat Contact Type"::" ") then
            exit;

        if Get then
            if (ContactNo = "Intrastat Contact No.") and (ContactType = "Intrastat Contact Type") then begin
                if ContactType = "Intrastat Contact Type"::Contact then
                    Error(OnDelIntrastatContactErr, ContactNo);
                Error(OnDelVendorIntrastatContactErr, ContactNo);
            end;
    end;
}

