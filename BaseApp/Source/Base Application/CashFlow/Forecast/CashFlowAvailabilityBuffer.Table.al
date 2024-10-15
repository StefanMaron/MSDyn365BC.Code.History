namespace Microsoft.CashFlow.Forecast;

table 930 "Cash Flow Availability Buffer"
{
    DataClassification = CustomerContent;

    fields
    {
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
        }
        field(6; "Period Name"; Text[50])
        {
            Caption = 'Period Name';
        }
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
        }
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
        }
        field(10; Receivables; Decimal)
        {
            Caption = 'Receivables';
        }
        field(11; "Sales Orders"; Decimal)
        {
            Caption = 'Sales Orders';
        }
        field(12; "Service Orders"; Decimal)
        {
            Caption = 'Service Orders';
        }
        field(13; "Fixed Assets Disposal"; Decimal)
        {
            Caption = 'Fixed Assets Disposal';
        }
        field(14; "Cash Flow Manual Revenues"; Decimal)
        {
            Caption = 'Cash Flow Manual Revenues';
        }
        field(15; Payables; Decimal)
        {
            Caption = 'Payables';
        }
        field(16; "Purchase Orders"; Decimal)
        {
            Caption = 'Purchase Orders';
        }
        field(17; "Fixed Assets Budget"; Decimal)
        {
            Caption = 'Fixed Assets Budget';
        }
        field(18; "Cash Flow Manual Expenses"; Decimal)
        {
            Caption = 'Cash Flow Manual Expenses';
        }
        field(19; "G/L Budget"; Decimal)
        {
            Caption = 'G/L Budget';
        }
        field(20; Job; Decimal)
        {
            Caption = 'Project';
        }
        field(21; Tax; Decimal)
        {
            Caption = 'Tax';
        }
        field(22; Total; Decimal)
        {
            Caption = 'Total';
        }
    }

    keys
    {
        key(Key1; "Period Type", "Period Start")
        {
            Clustered = true;
        }
    }
}