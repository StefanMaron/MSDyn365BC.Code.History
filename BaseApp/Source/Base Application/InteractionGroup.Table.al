table 5063 "Interaction Group"
{
    Caption = 'Interaction Group';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Interaction Groups";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(4; "No. of Interactions"; Integer)
        {
            CalcFormula = Count ("Interaction Log Entry" WHERE("Interaction Group Code" = FIELD(Code),
                                                               Canceled = CONST(false),
                                                               Date = FIELD("Date Filter"),
                                                               Postponed = CONST(false)));
            Caption = 'No. of Interactions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Interaction Log Entry"."Cost (LCY)" WHERE("Interaction Group Code" = FIELD(Code),
                                                                          Canceled = CONST(false),
                                                                          Date = FIELD("Date Filter"),
                                                                          Postponed = CONST(false)));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Duration (Min.)"; Decimal)
        {
            CalcFormula = Sum ("Interaction Log Entry"."Duration (Min.)" WHERE("Interaction Group Code" = FIELD(Code),
                                                                               Canceled = CONST(false),
                                                                               Date = FIELD("Date Filter"),
                                                                               Postponed = CONST(false)));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
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
}

