table 5208 "Human Resource Comment Line"
{
    Caption = 'Human Resource Comment Line';
    DataCaptionFields = "No.";
    DrillDownPageID = "Human Resource Comment List";
    LookupPageID = "Human Resource Comment List";

    fields
    {
        field(1; "Table Name"; Enum "Human Resources Comment Table Name")
        {
            Caption = 'Table Name';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF ("Table Name" = CONST(Employee)) Employee."No."
            ELSE
            IF ("Table Name" = CONST("Alternative Address")) "Alternative Address"."Employee No."
            ELSE
            IF ("Table Name" = CONST("Employee Qualification")) "Employee Qualification"."Employee No."
            ELSE
            IF ("Table Name" = CONST("Misc. Article Information")) "Misc. Article Information"."Employee No."
            ELSE
            IF ("Table Name" = CONST("Confidential Information")) "Confidential Information"."Employee No."
            ELSE
            IF ("Table Name" = CONST("Employee Absence")) "Employee Absence"."Employee No."
            ELSE
            IF ("Table Name" = CONST("Employee Relative")) "Employee Relative"."Employee No.";
        }
        field(3; "Table Line No."; Integer)
        {
            Caption = 'Table Line No.';
        }
        field(4; "Alternative Address Code"; Code[10])
        {
            Caption = 'Alternative Address Code';
            TableRelation = IF ("Table Name" = CONST("Alternative Address")) "Alternative Address".Code WHERE("Employee No." = FIELD("No."));
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(7; Date; Date)
        {
            Caption = 'Date';
        }
        field(8; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(9; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Table Line No.", "Alternative Address Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        HumanResCommentLine: Record "Human Resource Comment Line";
    begin
        HumanResCommentLine := Rec;
        HumanResCommentLine.SetRecFilter();
        HumanResCommentLine.SetRange("Line No.");
        HumanResCommentLine.SetRange(Date, WorkDate());
        if not HumanResCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, HumanResCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var HumanResourceCommentLineRec: Record "Human Resource Comment Line"; var HumanResourceCommentLineFilter: Record "Human Resource Comment Line")
    begin
    end;
}

