table 260 "Tariff Number"
{
    Caption = 'Tariff Number';
    LookupPageID = "Tariff Numbers";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            Numeric = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Supplementary Units"; Boolean)
        {
            CalcFormula = Exist ("Unit of Measure" WHERE(Code = FIELD("Supplem. Unit of Measure Code")));
            Caption = 'Supplementary Units';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11760; "Statement Code"; Code[10])
        {
            Caption = 'Statement Code';
            TableRelation = Commodity.Code;
        }
        field(11761; "VAT Stat. Unit of Measure Code"; Code[10])
        {
            Caption = 'VAT Stat. Unit of Measure Code';
            TableRelation = "Unit of Measure";
        }
        field(11762; "Allow Empty Unit of Meas.Code"; Boolean)
        {
            Caption = 'Allow Empty Unit of Meas.Code';
        }
        field(11763; "Statement Limit Code"; Code[10])
        {
            Caption = 'Statement Limit Code';
            TableRelation = Commodity.Code;
        }
        field(11792; "Full Name"; Text[250])
        {
            Caption = 'Full Name';
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Fields for Full Description will be removed and this field should not be used. Standard fields for Name are now 100. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
        field(11793; "Full Name ENG"; Text[250])
        {
            Caption = 'Full Name ENG';
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Fields for Full Description will be removed and this field should not be used. Standard fields for Name are now 100. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
        field(31060; "Supplem. Unit of Measure Code"; Code[10])
        {
            Caption = 'Supplem. Unit of Measure Code';
            TableRelation = "Unit of Measure";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        // NAVCZ
        StatisticIndication.SetRange("Tariff No.", "No.");
        StatisticIndication.DeleteAll;
        // NAVCZ
    end;

    var
        StatisticIndication: Record "Statistic Indication";
}

