table 5918 "Fault Code"
{
    Caption = 'Fault Code';
    LookupPageID = "Fault Codes";

    fields
    {
        field(1; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            TableRelation = "Fault Area".Code;
        }
        field(2; "Symptom Code"; Code[10])
        {
            Caption = 'Symptom Code';
            TableRelation = "Symptom Code".Code;
        }
        field(3; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(4; Description; Text[80])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Fault Area Code", "Symptom Code", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        ServMgtSetup.Get();
        if ServMgtSetup."Fault Reporting Level" = ServMgtSetup."Fault Reporting Level"::None then
            Error(
              Text000,
              TableCaption, ServMgtSetup.FieldCaption("Fault Reporting Level"), ServMgtSetup.TableCaption(),
              Format(ServMgtSetup."Fault Reporting Level"));
    end;

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";

        Text000: Label 'You cannot use %1, because the %2 in the %3 table is %4.';
        Text001: Label 'You cannot rename a %1.';
}

