table 361 "Analysis by Dim. Parameters"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            TableRelation = "Analysis View";
            DataClassification = SystemMetadata;
        }
        field(3; "Line Dim Option"; Option)
        {
            OptionCaption = 'G/L Account,Period,Business Unit,Dimension 1,Dimension 2,Dimension 3,Dimension 4,Cash Flow Account,Cash Flow Forecast';
            OptionMembers = "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast";
            DataClassification = SystemMetadata;
        }
        field(4; "Column Dim Option"; Option)
        {
            OptionCaption = 'G/L Account,Period,Business Unit,Dimension 1,Dimension 2,Dimension 3,Dimension 4,Cash Flow Account,Cash Flow Forecast';
            OptionMembers = "G/L Account",Period,"Business Unit","Dimension 1","Dimension 2","Dimension 3","Dimension 4","Cash Flow Account","Cash Flow Forecast";
            DataClassification = SystemMetadata;
        }
        field(5; "Date Filter"; Text[250])
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        field(6; "Account Filter"; Text[250])
        {
            Caption = 'Account Filter';
            DataClassification = SystemMetadata;
        }
        field(7; "Bus. Unit Filter"; Text[250])
        {
            Caption = 'Business Unit Filter';
            DataClassification = SystemMetadata;
        }
        field(8; "Cash Flow Forecast Filter"; Text[250])
        {
            Caption = 'Cash Flow Forecast Filter';
            DataClassification = SystemMetadata;
        }
        field(9; "Budget Filter"; Text[250])
        {
            Caption = 'Budget Filter';
            DataClassification = SystemMetadata;
        }
        field(10; "Dimension 1 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(11; "Dimension 2 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(12; "Dimension 3 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(13; "Dimension 4 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(20; "Show Actual/Budgets"; Option)
        {
            Caption = 'Show';
            OptionCaption = 'Actual Amounts,Budgeted Amounts,Variance,Variance%,Index%';
            OptionMembers = "Actual Amounts","Budgeted Amounts",Variance,"Variance%","Index%";
            DataClassification = SystemMetadata;
        }
        field(21; "Show Amount Field"; Option)
        {
            OptionCaption = 'Amount,Debit Amount,Credit Amount';
            OptionMembers = Amount,"Debit Amount","Credit Amount";
            DataClassification = SystemMetadata;
        }
        field(22; "Closing Entries"; Option)
        {
            Caption = 'Closing Entries';
            OptionCaption = 'Include,Exclude';
            OptionMembers = Include,Exclude;
            DataClassification = SystemMetadata;
        }
        field(23; "Rounding Factor"; Option)
        {
            Caption = 'Rounding Factor';
            OptionCaption = 'None,1,1000,1000000';
            OptionMembers = None,"1","1000","1000000";
            DataClassification = SystemMetadata;
        }
        field(24; "Show In Add. Currency"; Boolean)
        {
            Caption = 'Show Amounts in Add. Reporting Currency';
            DataClassification = SystemMetadata;
        }
        field(25; "Show Column Name"; Boolean)
        {
            Caption = 'Show Column Name';
            DataClassification = SystemMetadata;
        }
        field(26; "Show Opposite Sign"; Boolean)
        {
            Caption = 'Show Opposite Sign';
            DataClassification = SystemMetadata;
        }
        field(30; "Period Type"; Option)
        {
            Caption = 'View by';
            OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
            OptionMembers = Day,Week,Month,Quarter,Year,"Accounting Period";
            DataClassification = SystemMetadata;
        }
        field(31; "Column Set"; Text[250])
        {
            Caption = 'Column Set';
            DataClassification = SystemMetadata;
        }
        field(33; "Amount Type"; Option)
        {
            Caption = 'View as';
            OptionCaption = 'Net Change,Balance at Date';
            OptionMembers = "Net Change","Balance at Date";
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key("Key 1"; "Analysis View Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;
}