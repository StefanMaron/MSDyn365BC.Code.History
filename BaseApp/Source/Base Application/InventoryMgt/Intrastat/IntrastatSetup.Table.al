table 247 "Intrastat Setup"
{
    Caption = 'Intrastat Setup';
#if not CLEAN22
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
#endif
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

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
        field(8; "Use Advanced Checklist"; Boolean)
        {
            Caption = 'Use Advanced Checklist';
            ObsoleteState = Removed;
            ObsoleteTag = '22.0';
            ObsoleteReason = 'Unconditionally replaced by Advanced Intrastat Checklist';
        }
        field(9; "Cust. VAT No. on File"; Enum "Intrastat VAT No. On File")
        {
            Caption = 'Customer VAT No. on File';
        }
        field(10; "Vend. VAT No. on File"; Enum "Intrastat VAT No. On File")
        {
            Caption = 'Vendor VAT No. on File';
        }
        field(11; "Company VAT No. on File"; Enum "Intrastat VAT No. On File")
        {
            Caption = 'Company VAT No. on File';
        }
        field(12; "Default Trans. Spec. Code"; Code[10])
        {
            Caption = 'Default Trans. Spec. Code';
            TableRelation = "Transaction Specification";
        }
        field(13; "Default Trans. Spec. Ret. Code"; Code[10])
        {
            Caption = 'Default Trans. Spec. Returns Code';
            TableRelation = "Transaction Specification";
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

        if Get() then
            if (ContactNo = "Intrastat Contact No.") and (ContactType = "Intrastat Contact Type") then begin
                if ContactType = "Intrastat Contact Type"::Contact then
                    Error(OnDelIntrastatContactErr, ContactNo);
                Error(OnDelVendorIntrastatContactErr, ContactNo);
            end;
    end;
}

