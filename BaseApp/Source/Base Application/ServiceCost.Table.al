table 5905 "Service Cost"
{
    Caption = 'Service Cost';
    LookupPageID = "Service Costs";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = "G/L Account";
        }
        field(4; "Default Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Default Unit Price';
        }
        field(5; "Default Quantity"; Decimal)
        {
            Caption = 'Default Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(6; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure";
        }
        field(7; "Cost Type"; Option)
        {
            Caption = 'Cost Type';
            OptionCaption = 'Travel,Support,Other';
            OptionMembers = Travel,Support,Other;

            trigger OnValidate()
            begin
                Validate("Service Zone Code");
            end;
        }
        field(8; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            TableRelation = "Service Zone";

            trigger OnValidate()
            begin
                if "Service Zone Code" <> '' then
                    TestField("Cost Type", "Cost Type"::Travel);
            end;
        }
        field(9; "Default Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Default Unit Cost';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Service Zone Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Cost Type", "Default Unit Price")
        {
        }
    }

    trigger OnDelete()
    begin
        MoveEntries.MoveServiceCostLedgerEntries(Rec);
    end;

    var
        MoveEntries: Codeunit MoveEntries;
}

