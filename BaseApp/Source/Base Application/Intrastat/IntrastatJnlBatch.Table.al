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
            Numeric = true;

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
        field(12100; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Purchases,Sales';
            OptionMembers = Purchases,Sales;
        }
        field(12101; Periodicity; Option)
        {
            Caption = 'Periodicity';
            OptionCaption = 'Month,Quarter,Year';
            OptionMembers = Month,Quarter,Year;

            trigger OnValidate()
            begin
                "Statistics Period" := '';   //IT
            end;
        }
        field(12103; "File Disk No."; Code[20])
        {
            Caption = 'File Disk No.';
            Numeric = true;

            trigger OnValidate()
            var
                IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
            begin
                if xRec."File Disk No." <> "File Disk No." then begin
                    TestField("File Disk No.");
                    if "File Disk No." <> '' then begin
                        IntrastatJnlBatch.SetRange("File Disk No.", "File Disk No.");
                        if not IntrastatJnlBatch.IsEmpty() then
                            FieldError("File Disk No.");
                    end;
                end;
            end;
        }
        field(12110; "Corrective Entry"; Boolean)
        {
            Caption = 'Corrective Entry';

            trigger OnValidate()
            begin
                TestField(Reported, false);
                if ("Corrective Entry" <> xRec."Corrective Entry") then
                    ErrorIfIntrastatJnlLineExist(FieldCaption("Corrective Entry"));
            end;
        }
        field(12111; "EU Service"; Boolean)
        {
            Caption = 'EU Service';

            trigger OnValidate()
            begin
                TestField(Reported, false);
                if "EU Service" and (Periodicity = Periodicity::Year) then
                    FieldError(Periodicity);
                if ("EU Service" <> xRec."EU Service") then
                    ErrorIfIntrastatJnlLineExist(FieldCaption("EU Service"));
            end;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name)
        {
            Clustered = true;
        }
        key(Key2; "File Disk No.")
        {
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
        while IntrastatJnlLine.FindFirst() do
            IntrastatJnlLine.Rename("Journal Template Name", Name, IntrastatJnlLine."Line No.");
    end;

    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        Month: Integer;

        Text000: Label '%1 must be 4 characters, for example, 9410 for October, 1994.';
        Text001: Label 'Please check the month number.';
        Text12100: Label 'You cannot change %1 when Intrastat Jnl. Lines for batch %2 exists.';

    [Scope('OnPrem')]
    procedure ErrorIfIntrastatJnlLineExist(ChangedFieldName: Text[100])
    begin
        if IntrastatJnlLinesExist() then
            Error(
              Text12100,
              ChangedFieldName, Name);
    end;

    [Scope('OnPrem')]
    procedure IntrastatJnlLinesExist(): Boolean
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        IntrastatJnlLine.Reset();
        IntrastatJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", Name);
        exit(IntrastatJnlLine.FindFirst())
    end;

    [Scope('OnPrem')]
    procedure CheckEUServAndCorrection(JnlTemplateName: Code[10]; JnlBatchName: Code[10]; CheckEUService: Boolean; CheckCorrective: Boolean)
    begin
        if Get(JnlTemplateName, JnlBatchName) then begin
            if CheckEUService then
                TestField("EU Service");
            if CheckCorrective then
                TestField("Corrective Entry");
        end;
    end;

    procedure GetStatisticsStartDate(): Date
    var
        Century: Integer;
        Year: Integer;
        Month: Integer;
    begin
        TestField("Statistics Period");
        Century := Date2DMY(WorkDate(), 3) div 100;
        Evaluate(Year, CopyStr("Statistics Period", 1, 2));
        Year := Year + Century * 100;
        Evaluate(Month, CopyStr("Statistics Period", 3, 2));
        exit(DMY2Date(1, Month, Year));
    end;
}

