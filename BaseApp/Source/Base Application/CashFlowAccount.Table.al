table 841 "Cash Flow Account"
{
    Caption = 'Cash Flow Account';
    DataCaptionFields = "No.", Name;
    DrillDownPageID = "Cash Flow Account List";
    LookupPageID = "Cash Flow Account List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';

            trigger OnValidate()
            begin
                if ("Search Name" = UpperCase(xRec.Name)) or ("Search Name" = '') then
                    "Search Name" := Name;
            end;
        }
        field(3; "Search Name"; Code[50])
        {
            Caption = 'Search Name';
        }
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Entry,Heading,Total,Begin-Total,End-Total';
            OptionMembers = Entry,Heading,Total,"Begin-Total","End-Total";
        }
        field(5; Comment; Boolean)
        {
            CalcFormula = Exist ("Cash Flow Account Comment" WHERE("Table Name" = CONST("Cash Flow Account"),
                                                                   "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(7; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(8; "No. of Blank Lines"; Integer)
        {
            Caption = 'No. of Blank Lines';
            MinValue = 0;
        }
        field(9; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;

            trigger OnValidate()
            begin
                if Indentation < 0 then
                    Indentation := 0;
            end;
        }
        field(10; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(11; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(12; "Cash Flow Forecast Filter"; Code[20])
        {
            Caption = 'Cash Flow Forecast Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cash Flow Forecast";
        }
        field(13; Amount; Decimal)
        {
            CalcFormula = Sum ("Cash Flow Forecast Entry"."Amount (LCY)" WHERE("Cash Flow Account No." = FIELD("No."),
                                                                               "Cash Flow Account No." = FIELD(FILTER(Totaling)),
                                                                               "Cash Flow Forecast No." = FIELD("Cash Flow Forecast Filter"),
                                                                               "Cash Flow Date" = FIELD("Date Filter"),
                                                                               "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                               "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter")));
            Caption = 'Amount';
            FieldClass = FlowField;
        }
        field(29; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(30; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(34; Totaling; Text[250])
        {
            Caption = 'Totaling';
            TableRelation = "Cash Flow Account";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if not ("Account Type" in ["Account Type"::Total, "Account Type"::"End-Total"]) then
                    FieldError("Account Type");
                CalcFields(Amount);
            end;
        }
        field(35; "Source Type"; Option)
        {
            Caption = 'Source Type';
            OptionCaption = ' ,Receivables,Payables,Liquid Funds,Cash Flow Manual Expense,Cash Flow Manual Revenue,Sales Orders,Purchase Orders,Fixed Assets Budget,Fixed Assets Disposal,Service Orders,G/L Budget,,,Job,Tax';
            OptionMembers = " ",Receivables,Payables,"Liquid Funds","Cash Flow Manual Expense","Cash Flow Manual Revenue","Sales Orders","Purchase Orders","Fixed Assets Budget","Fixed Assets Disposal","Service Orders","G/L Budget",,,Job,Tax;
        }
        field(36; "G/L Integration"; Option)
        {
            Caption = 'G/L Integration';
            OptionCaption = ' ,Balance,Budget,Both';
            OptionMembers = " ",Balance,Budget,Both;
        }
        field(37; "G/L Account Filter"; Code[250])
        {
            Caption = 'G/L Account Filter';
            TableRelation = "G/L Account";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                GLAccList: Page "G/L Account List";
            begin
                GLAccList.LookupMode(true);
                if GLAccList.RunModal = ACTION::LookupOK then
                    "G/L Account Filter" := CopyStr(GLAccList.GetSelectionFilter, 1, MaxStrLen("G/L Account Filter"));
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
        key(Key3; "Source Type")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, "Account Type", Amount)
        {
        }
    }

    trigger OnDelete()
    var
        CommentLine: Record "Comment Line";
    begin
        MoveEntries.MoveCashFlowEntries(Rec);

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::"G/L Account");
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll;
    end;

    trigger OnInsert()
    begin
        if Indentation < 0 then
            Indentation := 0;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;

        if Indentation < 0 then
            Indentation := 0;
    end;

    trigger OnRename()
    begin
        "Last Date Modified" := Today;
    end;

    var
        MoveEntries: Codeunit MoveEntries;
}

