table 842 "Cash Flow Account Comment"
{
    Caption = 'Cash Flow Account Comment';
    DrillDownPageID = "Cash Flow Comment List";
    LookupPageID = "Cash Flow Comment List";

    fields
    {
        field(1; "Table Name"; Option)
        {
            Caption = 'Table Name';
            OptionCaption = 'Cash Flow Forecast,Cash Flow Account';
            OptionMembers = "Cash Flow Forecast","Cash Flow Account";
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF ("Table Name" = CONST("Cash Flow Forecast")) "Cash Flow Forecast"
            ELSE
            IF ("Table Name" = CONST("Cash Flow Account")) "Cash Flow Account";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(6; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Table Name", "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        CFAccountComment: Record "Cash Flow Account Comment";
    begin
        CFAccountComment.SetRange("Table Name", "Table Name");
        CFAccountComment.SetRange("No.", "No.");
        if not CFAccountComment.FindFirst then
            Date := WorkDate;
    end;
}

