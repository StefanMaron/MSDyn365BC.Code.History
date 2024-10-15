table 365 "Analysis View Entry"
{
    Caption = 'Analysis View Entry';
    DrillDownPageID = "Analysis View Entries";
    LookupPageID = "Analysis View Entries";

    fields
    {
        field(1; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            NotBlank = true;
            TableRelation = "Analysis View" WHERE("Account Source" = FIELD("Account Source"));
        }
        field(2; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Source" = CONST("G/L Account")) "G/L Account"
            ELSE
            IF ("Account Source" = CONST("Cash Flow Account")) "Cash Flow Account";
        }
        field(4; "Dimension 1 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Value Code';
        }
        field(5; "Dimension 2 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Value Code';
        }
        field(6; "Dimension 3 Value Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Value Code';
        }
        field(7; "Dimension 4 Value Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(4);
            Caption = 'Dimension 4 Value Code';
        }
        field(8; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(9; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; Amount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnLookup()
            begin
                DrillDown;
            end;
        }
        field(11; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Debit Amount';
        }
        field(12; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Credit Amount';
        }
        field(13; "Add.-Curr. Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Amount';
        }
        field(14; "Add.-Curr. Debit Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Debit Amount';
        }
        field(15; "Add.-Curr. Credit Amount"; Decimal)
        {
            AccessByPermission = TableData Currency = R;
            AutoFormatType = 1;
            Caption = 'Add.-Curr. Credit Amount';
        }
        field(16; "Account Source"; Option)
        {
            Caption = 'Account Source';
            OptionCaption = 'G/L Account,Cash Flow Account';
            OptionMembers = "G/L Account","Cash Flow Account";
        }
        field(17; "Cash Flow Forecast No."; Code[20])
        {
            Caption = 'Cash Flow Forecast No.';
            TableRelation = "Cash Flow Forecast";
        }
        field(10720; "Old G/L Account No."; Code[20])
        {
            Caption = 'Old G/L Account No.';
            TableRelation = "Historic G/L Account"."No.";
        }
        field(10721; Updated; Boolean)
        {
            Caption = 'Updated';
        }
    }

    keys
    {
        key(Key1; "Analysis View Code", "Account No.", "Account Source", "Dimension 1 Value Code", "Dimension 2 Value Code", "Dimension 3 Value Code", "Dimension 4 Value Code", "Business Unit Code", "Posting Date", "Entry No.", "Old G/L Account No.")
        {
            Clustered = true;
        }
        key(Key2; "Analysis View Code", "Account No.", "Account Source", "Dimension 1 Value Code", "Dimension 2 Value Code", "Dimension 3 Value Code", "Dimension 4 Value Code", "Business Unit Code", "Posting Date", "Cash Flow Forecast No.")
        {
            SumIndexFields = Amount, "Debit Amount", "Credit Amount", "Add.-Curr. Amount", "Add.-Curr. Debit Amount", "Add.-Curr. Credit Amount";
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label '1,5,,Dimension 1 Value Code';
        Text001: Label '1,5,,Dimension 2 Value Code';
        Text002: Label '1,5,,Dimension 3 Value Code';
        Text003: Label '1,5,,Dimension 4 Value Code';
        AnalysisView: Record "Analysis View";

    procedure GetCaptionClass(AnalysisViewDimType: Integer): Text[250]
    begin
        if AnalysisView.Code <> "Analysis View Code" then
            AnalysisView.Get("Analysis View Code");
        case AnalysisViewDimType of
            1:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 1 Code");

                    exit(Text000);
                end;
            2:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 2 Code");

                    exit(Text001);
                end;
            3:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 3 Code");

                    exit(Text002);
                end;
            4:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 4 Code");

                    exit(Text003);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure DrillDown()
    var
        TempGLEntry: Record "G/L Entry" temporary;
        TempCFForecastEntry: Record "Cash Flow Forecast Entry" temporary;
        AnalysisViewEntryToGLEntries: Codeunit AnalysisViewEntryToGLEntries;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDrilldown(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Account Source" = "Account Source"::"G/L Account" then begin
            TempGLEntry.Reset;
            TempGLEntry.DeleteAll;
            AnalysisViewEntryToGLEntries.GetGLEntries(Rec, TempGLEntry);
            PAGE.RunModal(PAGE::"General Ledger Entries", TempGLEntry);
        end else begin
            TempCFForecastEntry.Reset;
            TempCFForecastEntry.DeleteAll;
            AnalysisViewEntryToGLEntries.GetCFLedgEntries(Rec, TempCFForecastEntry);
            PAGE.RunModal(PAGE::"Cash Flow Forecast Entries", TempCFForecastEntry);
        end;

        OnAfterDrillDown(Rec);
    end;

    procedure CopyDimFilters(var AccSchedLine: Record "Acc. Schedule Line")
    begin
        AccSchedLine.CopyFilter("Dimension 1 Filter", "Dimension 1 Value Code");
        AccSchedLine.CopyFilter("Dimension 2 Filter", "Dimension 2 Value Code");
        AccSchedLine.CopyFilter("Dimension 3 Filter", "Dimension 3 Value Code");
        AccSchedLine.CopyFilter("Dimension 4 Filter", "Dimension 4 Value Code");
    end;

    procedure SetDimFilters(DimFilter1: Text; DimFilter2: Text; DimFilter3: Text; DimFilter4: Text)
    begin
        SetFilter("Dimension 1 Value Code", DimFilter1);
        SetFilter("Dimension 2 Value Code", DimFilter2);
        SetFilter("Dimension 3 Value Code", DimFilter3);
        SetFilter("Dimension 4 Value Code", DimFilter4);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDrillDown(var AnalysisViewEntry: Record "Analysis View Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrilldown(var AnalysisViewEntry: Record "Analysis View Entry"; var IsHandled: Boolean)
    begin
    end;
}

