table 31080 "Export Acc. Schedule"
{
    Caption = 'Export Acc. Schedule';
    DataCaptionFields = Name;
    LookupPageID = "Export Acc. Schedule List";

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(5; "Account Schedule Name"; Code[10])
        {
            Caption = 'Account Schedule Name';
            TableRelation = "Acc. Schedule Name";
        }
        field(10; "Column Layout Name"; Code[10])
        {
            Caption = 'Column Layout Name';
            TableRelation = "Column Layout Name";
        }
        field(20; "Show Amts. in Add. Curr."; Boolean)
        {
            Caption = 'Show Amts. in Add. Curr.';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AccSchedFilterLine: Record "Acc. Schedule Filter Line";
    begin
        AccSchedFilterLine.SetRange("Export Acc. Schedule Name", Name);
        AccSchedFilterLine.DeleteAll(true);
    end;

    [Scope('OnPrem')]
    procedure ShowFilterTable()
    var
        AccSchedFilterLine: Record "Acc. Schedule Filter Line";
        AccSchedFilterLines: Page "Acc. Schedule Filter Lines";
    begin
        TestField(Name);
        TestField("Account Schedule Name");
        AccSchedFilterLine.FilterGroup(2);
        AccSchedFilterLine.SetRange("Export Acc. Schedule Name", Name);
        AccSchedFilterLine.FilterGroup(0);

        AccSchedFilterLines.SetParameter(Rec);
        AccSchedFilterLines.SetTableView(AccSchedFilterLine);
        AccSchedFilterLines.RunModal;
    end;
}

