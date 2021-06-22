table 99000756 "Work Center Group"
{
    Caption = 'Work Center Group';
    DataCaptionFields = "Code", Name;
    DrillDownPageID = "Work Center Groups";
    LookupPageID = "Work Center Groups";
    Permissions = TableData "Prod. Order Capacity Need" = r;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(21; "Work Shift Filter"; Code[10])
        {
            Caption = 'Work Shift Filter';
            FieldClass = FlowFilter;
            TableRelation = "Work Shift";
        }
        field(22; "Capacity (Total)"; Decimal)
        {
            CalcFormula = Sum ("Calendar Entry"."Capacity (Total)" WHERE("Capacity Type" = CONST("Work Center"),
                                                                         "Work Center Group Code" = FIELD(Code),
                                                                         "Work Shift Code" = FIELD("Work Shift Filter"),
                                                                         Date = FIELD("Date Filter")));
            Caption = 'Capacity (Total)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(23; "Capacity (Effective)"; Decimal)
        {
            CalcFormula = Sum ("Calendar Entry"."Capacity (Effective)" WHERE("Capacity Type" = CONST("Work Center"),
                                                                             "Work Center Group Code" = FIELD(Code),
                                                                             "Work Shift Code" = FIELD("Work Shift Filter"),
                                                                             Date = FIELD("Date Filter")));
            Caption = 'Capacity (Effective)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(24; "Prod. Order Need (Qty.)"; Decimal)
        {
            CalcFormula = Sum ("Prod. Order Capacity Need"."Allocated Time" WHERE(Status = FIELD("Prod. Order Status Filter"),
                                                                                  "Work Center Group Code" = FIELD(Code),
                                                                                  Date = FIELD("Date Filter"),
                                                                                  "Requested Only" = CONST(false)));
            Caption = 'Prod. Order Need (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "Prod. Order Status Filter"; Option)
        {
            Caption = 'Prod. Order Status Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Simulated,Planned,Firm Planned,Released,Finished';
            OptionMembers = Simulated,Planned,"Firm Planned",Released,Finished;
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

