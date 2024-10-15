namespace Microsoft.Bank.PositivePay;

using System.IO;

table 1242 "Positive Pay Footer"
{
    Caption = 'Positive Pay Footer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Data Exch. Detail Entry No."; Integer)
        {
            Caption = 'Data Exch. Detail Entry No.';
            TableRelation = "Positive Pay Detail"."Data Exch. Entry No.";
        }
        field(3; "Account Number"; Text[30])
        {
            Caption = 'Account Number';
        }
        field(4; "Check Count"; Integer)
        {
            BlankZero = true;
            CalcFormula = count("Positive Pay Detail" where("Void Check Indicator" = const(''),
                                                             "Data Exch. Entry No." = field("Data Exch. Detail Entry No.")));
            Caption = 'Check Count';
            FieldClass = FlowField;
        }
        field(5; "Check Total"; Decimal)
        {
            BlankZero = true;
            CalcFormula = sum("Positive Pay Detail".Amount where("Void Check Indicator" = const(''),
                                                                  "Data Exch. Entry No." = field("Data Exch. Detail Entry No.")));
            Caption = 'Check Total';
            FieldClass = FlowField;
        }
        field(6; "Void Count"; Integer)
        {
            BlankZero = true;
            CalcFormula = count("Positive Pay Detail" where("Void Check Indicator" = const('V'),
                                                             "Data Exch. Entry No." = field("Data Exch. Detail Entry No.")));
            Caption = 'Void Count';
            FieldClass = FlowField;
        }
        field(7; "Void Total"; Decimal)
        {
            BlankZero = true;
            CalcFormula = sum("Positive Pay Detail".Amount where("Void Check Indicator" = const('V'),
                                                                  "Data Exch. Entry No." = field("Data Exch. Detail Entry No.")));
            Caption = 'Void Total';
            FieldClass = FlowField;
        }
        field(8; "Total Count"; Integer)
        {
            BlankZero = true;
            CalcFormula = count("Positive Pay Detail" where("Data Exch. Entry No." = field("Data Exch. Detail Entry No.")));
            Caption = 'Total Count';
            FieldClass = FlowField;
        }
        field(9; "Grand Total"; Decimal)
        {
            BlankZero = true;
            CalcFormula = sum("Positive Pay Detail".Amount where("Data Exch. Entry No." = field("Data Exch. Detail Entry No.")));
            Caption = 'Grand Total';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Data Exch. Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

