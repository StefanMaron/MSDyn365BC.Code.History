table 5090 "Sales Cycle"
{
    Caption = 'Sales Cycle';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Sales Cycles";

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
        field(3; "Probability Calculation"; Option)
        {
            Caption = 'Probability Calculation';
            OptionCaption = 'Multiply,Add,Chances of Success %,Completed %';
            OptionMembers = Multiply,Add,"Chances of Success %","Completed %";
        }
        field(4; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(5; "No. of Opportunities"; Integer)
        {
            CalcFormula = Count ("Opportunity Entry" WHERE(Active = CONST(true),
                                                           "Sales Cycle Code" = FIELD(Code),
                                                           "Action Taken" = FILTER(<> Won & <> Lost),
                                                           "Estimated Close Date" = FIELD("Date Filter")));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Opportunity Entry"."Estimated Value (LCY)" WHERE(Active = CONST(true),
                                                                                 "Sales Cycle Code" = FIELD(Code),
                                                                                 "Action Taken" = FILTER(<> Won & <> Lost),
                                                                                 "Estimated Close Date" = FIELD("Date Filter")));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = Sum ("Opportunity Entry"."Calcd. Current Value (LCY)" WHERE(Active = CONST(true),
                                                                                      "Sales Cycle Code" = FIELD(Code),
                                                                                      "Action Taken" = FILTER(<> Won & <> Lost),
                                                                                      "Estimated Close Date" = FIELD("Date Filter")));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; Comment; Boolean)
        {
            CalcFormula = Exist ("Rlshp. Mgt. Comment Line" WHERE("Table Name" = CONST("Sales Cycle"),
                                                                  "No." = FIELD(Code),
                                                                  "Sub No." = CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
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

    trigger OnDelete()
    begin
        CalcFields("No. of Opportunities");
        TestField("No. of Opportunities", 0);

        SalesCycleStage.SetRange("Sales Cycle Code", Code);
        SalesCycleStage.DeleteAll(true);

        RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::"Sales Cycle");
        RMCommentLine.SetRange("No.", Code);
        RMCommentLine.DeleteAll();
    end;

    var
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
        SalesCycleStage: Record "Sales Cycle Stage";
}

