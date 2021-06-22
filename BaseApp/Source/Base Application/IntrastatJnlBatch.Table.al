table 262 "Intrastat Jnl. Batch"
{
    Caption = 'Intrastat Jnl. Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "Intrastat Jnl. Batches";

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Intrastat Jnl. Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; Reported; Boolean)
        {
            Caption = 'Reported';
        }
        field(14; "Statistics Period"; Code[10])
        {
            Caption = 'Statistics Period';

            trigger OnValidate()
            begin
                TestField(Reported, false);
                if StrLen("Statistics Period") <> 4 then
                    Error(
                      Text000,
                      FieldCaption("Statistics Period"));
                Evaluate(Month, CopyStr("Statistics Period", 3, 2));
                if (Month < 1) or (Month > 12) then
                    Error(Text001);
            end;
        }
        field(15; "Amounts in Add. Currency"; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Amounts in Add. Currency';

            trigger OnValidate()
            begin
                TestField(Reported, false);
            end;
        }
        field(16; "Currency Identifier"; Code[10])
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Currency Identifier';

            trigger OnValidate()
            begin
                TestField(Reported, false);
            end;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", Name);
        IntrastatJnlLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        LockTable();
        IntraJnlTemplate.Get("Journal Template Name");
    end;

    trigger OnRename()
    begin
        IntrastatJnlLine.SetRange("Journal Template Name", xRec."Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", xRec.Name);
        while IntrastatJnlLine.FindFirst do
            IntrastatJnlLine.Rename("Journal Template Name", Name, IntrastatJnlLine."Line No.");
    end;

    var
        Text000: Label '%1 must be 4 characters, for example, 9410 for October, 1994.';
        Text001: Label 'Please check the month number.';
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Month: Integer;

    procedure GetStatisticsStartDate(): Date
    var
        Century: Integer;
        Year: Integer;
        Month: Integer;
    begin
        TestField("Statistics Period");
        Century := Date2DMY(WorkDate, 3) div 100;
        Evaluate(Year, CopyStr("Statistics Period", 1, 2));
        Year := Year + Century * 100;
        Evaluate(Month, CopyStr("Statistics Period", 3, 2));
        exit(DMY2Date(1, Month, Year));
    end;
}

