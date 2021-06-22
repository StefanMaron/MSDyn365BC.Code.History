table 5126 "Sales Comment Line Archive"
{
    Caption = 'Sales Comment Line Archive';
    DrillDownPageID = "Purch. Comment List";
    LookupPageID = "Purch. Comment List";

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order,Receipt,Posted Invoice,Posted Credit Memo,Posted Return Receipt';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Receipt,"Posted Invoice","Posted Credit Memo","Posted Return Receipt";
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
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
        field(7; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(8; "Doc. No. Occurrence"; Integer)
        {
            Caption = 'Doc. No. Occurrence';
        }
        field(9; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
    }

    keys
    {
        key(Key1; "Document Type", "No.", "Doc. No. Occurrence", "Version No.", "Document Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        SalesCommentLine: Record "Sales Comment Line Archive";
    begin
        SalesCommentLine.SetRange("Document Type", "Document Type");
        SalesCommentLine.SetRange("No.", "No.");
        SalesCommentLine.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        SalesCommentLine.SetRange("Version No.", "Version No.");
        SalesCommentLine.SetRange("Document Line No.", "Line No.");
        SalesCommentLine.SetRange(Date, WorkDate);
        if not SalesCommentLine.FindFirst then
            Date := WorkDate;
    end;
}

