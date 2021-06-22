table 5091 "Sales Cycle Stage"
{
    Caption = 'Sales Cycle Stage';
    DataCaptionFields = "Sales Cycle Code", Stage, Description;
    LookupPageID = "Sales Cycle Stages";

    fields
    {
        field(1; "Sales Cycle Code"; Code[10])
        {
            Caption = 'Sales Cycle Code';
            NotBlank = true;
            TableRelation = "Sales Cycle";
        }
        field(2; Stage; Integer)
        {
            BlankZero = true;
            Caption = 'Stage';
            MinValue = 1;
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Completed %"; Decimal)
        {
            Caption = 'Completed %';
            DecimalPlaces = 0 : 0;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5; "Activity Code"; Code[10])
        {
            Caption = 'Activity Code';
            TableRelation = Activity;
        }
        field(6; "Quote Required"; Boolean)
        {
            Caption = 'Quote Required';
        }
        field(7; "Allow Skip"; Boolean)
        {
            Caption = 'Allow Skip';
        }
        field(8; Comment; Boolean)
        {
            CalcFormula = Exist ("Rlshp. Mgt. Comment Line" WHERE("Table Name" = CONST("Sales Cycle Stage"),
                                                                  "No." = FIELD("Sales Cycle Code"),
                                                                  "Sub No." = FIELD(Stage)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "No. of Opportunities"; Integer)
        {
            CalcFormula = Count ("Opportunity Entry" WHERE(Active = CONST(true),
                                                           "Sales Cycle Code" = FIELD("Sales Cycle Code"),
                                                           "Sales Cycle Stage" = FIELD(Stage),
                                                           "Estimated Close Date" = FIELD("Date Filter")));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Opportunity Entry"."Estimated Value (LCY)" WHERE(Active = CONST(true),
                                                                                 "Sales Cycle Code" = FIELD("Sales Cycle Code"),
                                                                                 "Sales Cycle Stage" = FIELD(Stage),
                                                                                 "Estimated Close Date" = FIELD("Date Filter")));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Opportunity Entry"."Calcd. Current Value (LCY)" WHERE(Active = CONST(true),
                                                                                      "Sales Cycle Code" = FIELD("Sales Cycle Code"),
                                                                                      "Sales Cycle Stage" = FIELD(Stage),
                                                                                      "Estimated Close Date" = FIELD("Date Filter")));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Average No. of Days"; Decimal)
        {
            CalcFormula = Average ("Opportunity Entry"."Days Open" WHERE(Active = CONST(false),
                                                                         "Sales Cycle Code" = FIELD("Sales Cycle Code"),
                                                                         "Sales Cycle Stage" = FIELD(Stage),
                                                                         "Estimated Close Date" = FIELD("Date Filter")));
            Caption = 'Average No. of Days';
            DecimalPlaces = 0 : 2;
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(14; "Date Formula"; DateFormula)
        {
            Caption = 'Date Formula';
        }
        field(15; "Chances of Success %"; Decimal)
        {
            Caption = 'Chances of Success %';
            MaxValue = 100;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Sales Cycle Code", Stage)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        OppEntry: Record "Opportunity Entry";
    begin
        RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::"Sales Cycle Stage");
        RMCommentLine.SetRange("No.", "Sales Cycle Code");
        RMCommentLine.SetRange("Sub No.", Stage);
        RMCommentLine.DeleteAll();

        OppEntry.SetRange(Active, true);
        OppEntry.SetRange("Sales Cycle Code", "Sales Cycle Code");
        OppEntry.SetRange("Sales Cycle Stage", Stage);
        if not OppEntry.IsEmpty then
            Error(Text000);
    end;

    var
        Text000: Label 'You cannot delete a stage which has active entries.';
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
}

