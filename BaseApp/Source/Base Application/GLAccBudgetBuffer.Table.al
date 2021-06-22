table 374 "G/L Acc. Budget Buffer"
{
    Caption = 'G/L Acc. Budget Buffer';
    DataCaptionFields = "Code";
    DrillDownPageID = "Chart of Accounts";
    LookupPageID = "G/L Account List";
    ReplicateData = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(3; "Budget Filter"; Code[10])
        {
            Caption = 'Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Budget Name";
        }
        field(4; "G/L Account Filter"; Code[20])
        {
            Caption = 'G/L Account Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Account";
            ValidateTableRelation = false;
        }
        field(5; "Business Unit Filter"; Code[20])
        {
            Caption = 'Business Unit Filter';
            FieldClass = FlowFilter;
            TableRelation = "Business Unit";
        }
        field(6; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
        }
        field(7; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
        }
        field(8; "Budget Dimension 1 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(1);
            Caption = 'Budget Dimension 1 Filter';
            FieldClass = FlowFilter;
        }
        field(9; "Budget Dimension 2 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(2);
            Caption = 'Budget Dimension 2 Filter';
            FieldClass = FlowFilter;
        }
        field(10; "Budget Dimension 3 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(3);
            Caption = 'Budget Dimension 3 Filter';
            FieldClass = FlowFilter;
        }
        field(11; "Budget Dimension 4 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(4);
            Caption = 'Budget Dimension 4 Filter';
            FieldClass = FlowFilter;
        }
        field(12; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            ClosingDates = true;
            FieldClass = FlowFilter;
        }
        field(13; "Budgeted Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("G/L Budget Entry".Amount WHERE("Budget Name" = FIELD("Budget Filter"),
                                                               "G/L Account No." = FIELD("G/L Account Filter"),
                                                               "Business Unit Code" = FIELD("Business Unit Filter"),
                                                               "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                               "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                               "Budget Dimension 1 Code" = FIELD("Budget Dimension 1 Filter"),
                                                               "Budget Dimension 2 Code" = FIELD("Budget Dimension 2 Filter"),
                                                               "Budget Dimension 3 Code" = FIELD("Budget Dimension 3 Filter"),
                                                               "Budget Dimension 4 Code" = FIELD("Budget Dimension 4 Filter"),
                                                               Date = FIELD("Date Filter")));
            Caption = 'Budgeted Amount';
            FieldClass = FlowField;
        }
        field(14; "Income/Balance"; Option)
        {
            Caption = 'Income/Balance';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Income Statement,Balance Sheet';
            OptionMembers = " ","Income Statement","Balance Sheet";
        }
        field(15; "Account Category"; Option)
        {
            Caption = 'Account Category';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Assets,Liabilities,Equity,Income,Cost of Goods Sold,Expense';
            OptionMembers = " ",Assets,Liabilities,Equity,Income,"Cost of Goods Sold",Expense;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label '1,6,,Budget Dimension 1 Filter';
        Text001: Label '1,6,,Budget Dimension 2 Filter';
        Text002: Label '1,6,,Budget Dimension 3 Filter';
        Text003: Label '1,6,,Budget Dimension 4 Filter';
        GLBudgetName: Record "G/L Budget Name";

    procedure GetCaptionClass(BudgetDimType: Integer): Text[250]
    begin
        if GLBudgetName.Name <> GetFilter("Budget Filter") then
            GLBudgetName.Get(GetFilter("Budget Filter"));
        case BudgetDimType of
            1:
                begin
                    if GLBudgetName."Budget Dimension 1 Code" <> '' then
                        exit('1,6,' + GLBudgetName."Budget Dimension 1 Code");

                    exit(Text000);
                end;
            2:
                begin
                    if GLBudgetName."Budget Dimension 2 Code" <> '' then
                        exit('1,6,' + GLBudgetName."Budget Dimension 2 Code");

                    exit(Text001);
                end;
            3:
                begin
                    if GLBudgetName."Budget Dimension 3 Code" <> '' then
                        exit('1,6,' + GLBudgetName."Budget Dimension 3 Code");

                    exit(Text002);
                end;
            4:
                begin
                    if GLBudgetName."Budget Dimension 4 Code" <> '' then
                        exit('1,6,' + GLBudgetName."Budget Dimension 4 Code");

                    exit(Text003);
                end;
        end;
    end;
}

