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
                // NAVCZ
                CheckUniqueDeclarationNo;
                if xRec."Statistics Period" <> '' then
                    CheckJnlLinesExist(FieldNo("Statistics Period"));
                // NAVCZ
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
        field(31060; "Perform. Country/Region Code"; Code[10])
        {
            Caption = 'Perform. Country/Region Code';
            TableRelation = "Registration Country/Region"."Country/Region Code" WHERE("Account Type" = CONST("Company Information"),
                                                                                       "Account No." = FILTER(''));
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of VAT Registration in Other Countries will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
        field(31061; "Declaration No."; Code[20])
        {
            Caption = 'Declaration No.';

            trigger OnValidate()
            begin
                TestField("Statistics Period");
                CheckUniqueDeclarationNo;
                if xRec."Declaration No." <> '' then
                    CheckJnlLinesExist(FieldNo("Declaration No."));
            end;
        }
        field(31062; "Statement Type"; Option)
        {
            Caption = 'Statement Type';
            OptionCaption = 'Primary,Null,Replacing,Deleting';
            OptionMembers = Primary,Null,Replacing,Deleting;

            trigger OnValidate()
            begin
                CheckJnlLinesExist(FieldNo("Statement Type"));
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
        Text1220000: Label 'Declaration No. %1 already exists for Statistics Period %2.';
        Text1220001: Label 'You cannot change %1 value after Intrastat Journal Batch %2 was exported.';

    [Scope('OnPrem')]
    procedure CheckUniqueDeclarationNo()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        // NAVCZ
        if "Declaration No." <> '' then begin
            IntrastatJnlBatch.Reset();
            IntrastatJnlBatch.SetRange("Journal Template Name", "Journal Template Name");
            IntrastatJnlBatch.SetRange("Statistics Period", "Statistics Period");
            IntrastatJnlBatch.SetRange("Declaration No.", "Declaration No.");
            IntrastatJnlBatch.SetFilter(Name, '<>%1', Name);
            if IntrastatJnlBatch.FindFirst then
                Error(Text1220000, "Declaration No.", "Statistics Period");
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckJnlLinesExist(CurrentFieldNo: Integer)
    begin
        // NAVCZ
        IntrastatJnlLine.Reset();
        IntrastatJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        IntrastatJnlLine.SetRange("Journal Batch Name", Name);
        case CurrentFieldNo of
            FieldNo("Statistics Period"):
                begin
                    IntrastatJnlLine.SetRange("Statistics Period", xRec."Statistics Period");
                    if IntrastatJnlLine.FindFirst then
                        Error(Text1220001, FieldCaption("Statistics Period"), Name);
                end;
            FieldNo("Declaration No."):
                begin
                    IntrastatJnlLine.SetRange("Declaration No.", xRec."Declaration No.");
                    if IntrastatJnlLine.FindFirst then
                        Error(Text1220001, FieldCaption("Declaration No."), Name);
                end;
            FieldNo("Statement Type"):
                begin
                    IntrastatJnlLine.SetRange("Statement Type", xRec."Statement Type");
                    if IntrastatJnlLine.FindFirst then
                        Error(Text1220001, FieldCaption("Statement Type"), Name);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(OldIntrastatJnlBatch: Record "Intrastat Jnl. Batch"): Boolean
    var
        VATReportingSetup: Record "Stat. Reporting Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        // NAVCZ
        if "Declaration No." = '' then begin
            VATReportingSetup.Get();
            VATReportingSetup.TestField("Intrastat Declaration Nos.");
            "Declaration No." := NoSeriesMgt.GetNextNo(VATReportingSetup."Intrastat Declaration Nos.", 0D, true);
            exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure xSetupNewBatch()
    begin
        // NAVCZ
        IntraJnlTemplate.Get("Journal Template Name");
        "Perform. Country/Region Code" := IntraJnlTemplate."Perform. Country/Region Code";
    end;

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

