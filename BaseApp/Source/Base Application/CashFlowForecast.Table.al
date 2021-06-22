table 840 "Cash Flow Forecast"
{
    Caption = 'Cash Flow Forecast';
    DrillDownPageID = "Cash Flow Forecast List";
    LookupPageID = "Cash Flow Forecast List";
    Permissions = TableData "Cash Flow Account Comment" = rimd,
                  TableData "Cash Flow Forecast Entry" = rimd;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                if ("Search Name" = UpperCase(xRec.Description)) or ("Search Name" = '') then
                    "Search Name" := Description;
            end;
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(5; "Consider Discount"; Boolean)
        {
            Caption = 'Consider Discount';

            trigger OnValidate()
            begin
                if not "Consider Discount" then
                    "Consider Pmt. Disc. Tol. Date" := false;
            end;
        }
        field(6; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(7; "Created By"; Code[50])
        {
            Caption = 'Created By';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Manual Payments To"; Date)
        {
            Caption = 'Manual Payments To';
        }
        field(9; Comment; Boolean)
        {
            CalcFormula = Exist ("Cash Flow Account Comment" WHERE("Table Name" = CONST("Cash Flow Forecast"),
                                                                   "No." = FIELD("No.")));
            Caption = 'Comment';
            FieldClass = FlowField;
        }
        field(10; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(11; "Manual Payments From"; Date)
        {
            Caption = 'Manual Payments From';
        }
        field(12; "G/L Budget From"; Date)
        {
            AccessByPermission = TableData "G/L Budget Name" = R;
            Caption = 'G/L Budget From';
        }
        field(13; "G/L Budget To"; Date)
        {
            AccessByPermission = TableData "G/L Budget Name" = R;
            Caption = 'G/L Budget To';
        }
        field(14; "Consider CF Payment Terms"; Boolean)
        {
            Caption = 'Consider CF Payment Terms';
        }
        field(15; "Consider Pmt. Disc. Tol. Date"; Boolean)
        {
            Caption = 'Consider Pmt. Disc. Tol. Date';
        }
        field(16; "Consider Pmt. Tol. Amount"; Boolean)
        {
            Caption = 'Consider Pmt. Tol. Amount';
        }
        field(17; "Account No. Filter"; Code[20])
        {
            Caption = 'Account No. Filter';
            FieldClass = FlowFilter;
        }
        field(18; "Source Type Filter"; Enum "Cash Flow Source Type")
        {
            Caption = 'Source Type Filter';
            FieldClass = FlowFilter;
        }
        field(19; "Cash Flow Date Filter"; Date)
        {
            Caption = 'Cash Flow Date Filter';
            FieldClass = FlowFilter;
        }
        field(20; "Amount (LCY)"; Decimal)
        {
            CalcFormula = Sum ("Cash Flow Forecast Entry"."Amount (LCY)" WHERE("Cash Flow Forecast No." = FIELD("No."),
                                                                               "Cash Flow Date" = FIELD("Cash Flow Date Filter"),
                                                                               "Source Type" = FIELD("Source Type Filter"),
                                                                               "Cash Flow Account No." = FIELD("Account No. Filter"),
                                                                               Positive = FIELD("Positive Filter")));
            Caption = 'Amount (LCY)';
            FieldClass = FlowField;
        }
        field(21; "Positive Filter"; Boolean)
        {
            Caption = 'Positive Filter';
            FieldClass = FlowFilter;
        }
        field(22; "Overdue CF Dates to Work Date"; Boolean)
        {
            Caption = 'Overdue CF Dates to Work Date';
        }
        field(23; "Default G/L Budget Name"; Code[10])
        {
            Caption = 'Default G/L Budget Name';
            TableRelation = "G/L Budget Name";
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
        fieldgroup(DropDown; "No.", Description, "Description 2", "Creation Date")
        {
        }
    }

    trigger OnDelete()
    begin
        if GetShowInChart then
            CFSetup.SetChartRoleCenterCFNo('');

        CFAccountComment.Reset();
        CFAccountComment.SetRange("Table Name", CFAccountComment."Table Name"::"Cash Flow Forecast");
        CFAccountComment.SetRange("No.", "No.");
        CFAccountComment.DeleteAll();

        CFForecastEntry.Reset();
        CFForecastEntry.SetCurrentKey("Cash Flow Forecast No.");
        CFForecastEntry.SetRange("Cash Flow Forecast No.", "No.");
        CFForecastEntry.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            CFSetup.Get();
            CFSetup.TestField("Cash Flow Forecast No. Series");
            NoSeriesMgt.InitSeries(CFSetup."Cash Flow Forecast No. Series", xRec."No. Series", 0D, "No.", "No. Series");
        end;

        "Creation Date" := WorkDate;
        "Created By" := UserId;
        "Manual Payments From" := WorkDate;
        "G/L Budget From" := WorkDate;
    end;

    var
        CFSetup: Record "Cash Flow Setup";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFAccountComment: Record "Cash Flow Account Comment";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        NoSeriesMgt: Codeunit NoSeriesManagement;

    procedure AssistEdit(OldCashFlowForecast: Record "Cash Flow Forecast"): Boolean
    begin
        with CashFlowForecast do begin
            CashFlowForecast := Rec;
            CFSetup.Get();
            CFSetup.TestField("Cash Flow Forecast No. Series");
            if NoSeriesMgt.SelectSeries(CFSetup."Cash Flow Forecast No. Series", OldCashFlowForecast."No. Series", "No. Series") then begin
                CFSetup.Get();
                CFSetup.TestField("Cash Flow Forecast No. Series");
                NoSeriesMgt.SetSeries("No.");
                Rec := CashFlowForecast;
                exit(true);
            end;
        end;
    end;

    procedure DrillDown()
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        CFForecastEntry.DrillDownOnEntries(Rec);
    end;

    procedure CalcAmountForPosNeg(PositiveAmount: Boolean): Decimal
    begin
        SetRange("Positive Filter", PositiveAmount);
        exit(CalcAmount);
    end;

    procedure DrillDownPosNegEntries(PositiveAmount: Boolean)
    begin
        SetRange("Positive Filter", PositiveAmount);
        DrillDown;
    end;

    procedure CalcAmountForAccountNo(AccountNo: Code[20]): Decimal
    begin
        SetAccountNoFilter(AccountNo);
        exit(CalcAmount);
    end;

    procedure SetAccountNoFilter(AccountNo: Code[20])
    begin
        if AccountNo = '' then
            SetRange("Account No. Filter")
        else
            SetRange("Account No. Filter", AccountNo);
    end;

    procedure DrillDownEntriesForAccNo(AccountNo: Code[20])
    begin
        SetAccountNoFilter(AccountNo);
        DrillDown;
    end;

    procedure CalcAmountFromSource(SourceType: Option): Decimal
    begin
        SetSourceTypeFilter(SourceType);
        exit(CalcAmount);
    end;

    procedure SetSourceTypeFilter(SourceType: Option)
    begin
        if SourceType = 0 then
            SetRange("Source Type Filter")
        else
            SetRange("Source Type Filter", SourceType);
    end;

    procedure DrillDownEntriesFromSource(SourceType: Option)
    begin
        SetSourceTypeFilter(SourceType);
        DrillDown;
    end;

    procedure CalcAmount(): Decimal
    begin
        CalcFields("Amount (LCY)");
        exit("Amount (LCY)");
    end;

    procedure SetCashFlowDateFilter(FromDate: Date; ToDate: Date)
    begin
        if (FromDate = 0D) and (ToDate = 0D) then
            SetRange("Cash Flow Date Filter")
        else
            if ToDate = 0D then
                SetFilter("Cash Flow Date Filter", '%1..', FromDate)
            else
                SetRange("Cash Flow Date Filter", FromDate, ToDate);
    end;

    procedure PrintRecords()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFReportSelection: Record "Cash Flow Report Selection";
    begin
        with CashFlowForecast do begin
            Copy(Rec);
            CFReportSelection.SetFilter("Report ID", '<>0');
            if CFReportSelection.FindSet then
                repeat
                    REPORT.RunModal(CFReportSelection."Report ID", true, false, CashFlowForecast);
                until CFReportSelection.Next = 0;
        end;
    end;

    procedure LookupCashFlowFilter(var Text: Text): Boolean
    var
        CashFlowForecastList: Page "Cash Flow Forecast List";
    begin
        CashFlowForecastList.LookupMode(true);
        if CashFlowForecastList.RunModal = ACTION::LookupOK then begin
            Text := CashFlowForecastList.GetSelectionFilter;
            exit(true);
        end;
        exit(false)
    end;

    procedure CalculateAllAmounts(FromDate: Date; ToDate: Date; var Amounts: array[14] of Decimal; var TotalAmount: Decimal)
    var
        SourceType: Option;
    begin
        Clear(Amounts);
        SetCashFlowDateFilter(FromDate, ToDate);
        for SourceType := 1 to ArrayLen(Amounts) do
            Amounts[SourceType] := CalcAmountFromSource(SourceType);
        TotalAmount := CalcAmountFromSource(0);
    end;

    procedure ValidateShowInChart(ShowInChart: Boolean): Boolean
    var
        NewCashFlowNo: Code[20];
    begin
        if ShowInChart then
            NewCashFlowNo := "No."
        else
            NewCashFlowNo := '';

        CFSetup.Get();
        CFSetup.Validate("CF No. on Chart in Role Center", NewCashFlowNo);
        CFSetup.Modify();
        exit(GetShowInChart);
    end;

    procedure GetShowInChart(): Boolean
    var
        ChartRoleCenterCFNo: Code[20];
    begin
        ChartRoleCenterCFNo := CFSetup.GetChartRoleCenterCFNo;
        if ChartRoleCenterCFNo = '' then
            exit(false);

        exit("No." = ChartRoleCenterCFNo);
    end;

    procedure GetEntryDate(Which: Option First,Last): Date
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        CFForecastEntry.SetCurrentKey("Cash Flow Forecast No.", "Cash Flow Date");
        CFForecastEntry.SetRange("Cash Flow Forecast No.", "No.");
        case Which of
            Which::First:
                if not CFForecastEntry.FindFirst then
                    exit(0D);
            Which::Last:
                if not CFForecastEntry.FindLast then
                    exit(0D);
        end;
        exit(CFForecastEntry."Cash Flow Date");
    end;
}

