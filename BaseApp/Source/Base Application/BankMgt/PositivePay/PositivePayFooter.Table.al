table 1242 "Positive Pay Footer"
{
    Caption = 'Positive Pay Footer';

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
            CalcFormula = Count ("Positive Pay Detail" WHERE("Void Check Indicator" = CONST(''),
                                                             "Data Exch. Entry No." = FIELD("Data Exch. Detail Entry No.")));
            Caption = 'Check Count';
            FieldClass = FlowField;
        }
        field(5; "Check Total"; Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum ("Positive Pay Detail".Amount WHERE("Void Check Indicator" = CONST(''),
                                                                  "Data Exch. Entry No." = FIELD("Data Exch. Detail Entry No.")));
            Caption = 'Check Total';
            FieldClass = FlowField;
        }
        field(6; "Void Count"; Integer)
        {
            BlankZero = true;
            CalcFormula = Count ("Positive Pay Detail" WHERE("Void Check Indicator" = CONST('V'),
                                                             "Data Exch. Entry No." = FIELD("Data Exch. Detail Entry No.")));
            Caption = 'Void Count';
            FieldClass = FlowField;
        }
        field(7; "Void Total"; Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum ("Positive Pay Detail".Amount WHERE("Void Check Indicator" = CONST('V'),
                                                                  "Data Exch. Entry No." = FIELD("Data Exch. Detail Entry No.")));
            Caption = 'Void Total';
            FieldClass = FlowField;
        }
        field(8; "Total Count"; Integer)
        {
            BlankZero = true;
            CalcFormula = Count ("Positive Pay Detail" WHERE("Data Exch. Entry No." = FIELD("Data Exch. Detail Entry No.")));
            Caption = 'Total Count';
            FieldClass = FlowField;
        }
        field(9; "Grand Total"; Decimal)
        {
            BlankZero = true;
            CalcFormula = Sum ("Positive Pay Detail".Amount WHERE("Data Exch. Entry No." = FIELD("Data Exch. Detail Entry No.")));
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

