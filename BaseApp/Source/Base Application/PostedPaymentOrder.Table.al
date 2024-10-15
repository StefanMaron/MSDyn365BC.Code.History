table 7000021 "Posted Payment Order"
{
    Caption = 'Posted Payment Order';
    DrillDownPageID = "Posted Payment Orders List";
    LookupPageID = "Posted Payment Orders List";

    fields
    {
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(4; "Bank Account Name"; Text[100])
        {
            CalcFormula = Lookup ("Bank Account".Name WHERE("No." = FIELD("Bank Account No.")));
            Caption = 'Bank Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
        }
        field(7; Amount; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Remaining Amount" WHERE("Bill Gr./Pmt. Order No." = FIELD("No."),
                                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                              Status = FIELD("Status Filter"),
                                                                              "Category Code" = FIELD("Category Filter"),
                                                                              "Due Date" = FIELD("Due Date Filter"),
                                                                              Type = CONST(Payable)));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(9; "No. Printed"; Integer)
        {
            Caption = 'No. Printed';
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = Exist ("BG/PO Comment Line" WHERE("BG/PO No." = FIELD("No."),
                                                            Type = FILTER(Payable)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Category Filter"; Code[10])
        {
            Caption = 'Category Filter';
            FieldClass = FlowFilter;
            TableRelation = "Category Code";
            ValidateTableRelation = false;
        }
        field(13; "Due Date Filter"; Date)
        {
            Caption = 'Due Date Filter';
            FieldClass = FlowFilter;
        }
        field(14; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(15; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(16; "Amount Grouped"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Amount for Collection" WHERE("Bill Gr./Pmt. Order No." = FIELD("No."),
                                                                                   "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                   "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                   Status = FIELD("Status Filter"),
                                                                                   "Category Code" = FIELD("Category Filter"),
                                                                                   "Due Date" = FIELD("Due Date Filter"),
                                                                                   Type = CONST(Payable)));
            Caption = 'Amount Grouped';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Remaining Amount" WHERE("Bill Gr./Pmt. Order No." = FIELD("No."),
                                                                              "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                              "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                              Status = FIELD("Status Filter"),
                                                                              "Category Code" = FIELD("Category Filter"),
                                                                              "Due Date" = FIELD("Due Date Filter"),
                                                                              Type = CONST(Payable)));
            Caption = 'Remaining Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Status Filter"; Option)
        {
            Caption = 'Status Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Open,Honored,Rejected';
            OptionMembers = Open,Honored,Rejected;
        }
        field(29; "Payment Order Expenses Amt."; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Payment Order Expenses Amt.';
        }
        field(33; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(34; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Remaining Amt. (LCY)" WHERE("Bill Gr./Pmt. Order No." = FIELD("No."),
                                                                                  "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                  "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                  Status = FIELD("Status Filter"),
                                                                                  "Category Code" = FIELD("Category Filter"),
                                                                                  "Due Date" = FIELD("Due Date Filter"),
                                                                                  Type = CONST(Payable)));
            Caption = 'Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(35; "Amount Grouped (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Amt. for Collection (LCY)" WHERE("Bill Gr./Pmt. Order No." = FIELD("No."),
                                                                                       "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                       "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                       Status = FIELD("Status Filter"),
                                                                                       "Category Code" = FIELD("Category Filter"),
                                                                                       "Due Date" = FIELD("Due Date Filter"),
                                                                                       Type = CONST(Payable)));
            Caption = 'Amount Grouped (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(36; "Remaining Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Posted Cartera Doc."."Remaining Amt. (LCY)" WHERE("Bill Gr./Pmt. Order No." = FIELD("No."),
                                                                                  "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                                  "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                                  Status = FIELD("Status Filter"),
                                                                                  "Category Code" = FIELD("Category Filter"),
                                                                                  "Due Date" = FIELD("Due Date Filter"),
                                                                                  Type = CONST(Payable)));
            Caption = 'Remaining Amount (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Posting Date")
        {
            SumIndexFields = "Payment Order Expenses Amt.";
        }
        key(Key3; "Bank Account No.", "Posting Date", "Currency Code")
        {
            SumIndexFields = "Payment Order Expenses Amt.";
        }
    }

    fieldgroups
    {
    }

    var
        Text1100000: Label 'untitled';
        PostedPmtOrd: Record "Posted Payment Order";

    [Scope('OnPrem')]
    procedure PrintRecords(ShowRequestForm: Boolean)
    var
        CarteraReportSelection: Record "Cartera Report Selections";
    begin
        with PostedPmtOrd do begin
            Copy(Rec);
            CarteraReportSelection.SetRange(Usage, CarteraReportSelection.Usage::"Posted Payment Order");
            CarteraReportSelection.SetFilter("Report ID", '<>0');
            CarteraReportSelection.Find('-');
            repeat
                REPORT.RunModal(CarteraReportSelection."Report ID", ShowRequestForm, false, PostedPmtOrd);
            until CarteraReportSelection.Next() = 0;
        end;
    end;

    procedure Caption(): Text
    begin
        if "No." = '' then
            exit(Text1100000);
        CalcFields("Bank Account Name");
        exit(StrSubstNo('%1 %2', "No.", "Bank Account Name"));
    end;
}

