table 5125 "Purch. Comment Line Archive"
{
    Caption = 'Purch. Comment Line Archive';
    DrillDownPageID = "Purch. Archive Comment Sheet";
    LookupPageID = "Purch. Archive Comment Sheet";

    fields
    {
        field(1; "Document Type"; Enum "Purchase Comment Document Type")
        {
            Caption = 'Document Type';
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
        PurchCommentLine: Record "Purch. Comment Line Archive";
    begin
        PurchCommentLine.SetRange("Document Type", "Document Type");
        PurchCommentLine.SetRange("No.", "No.");
        PurchCommentLine.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
        PurchCommentLine.SetRange("Version No.", "Version No.");
        PurchCommentLine.SetRange("Document Line No.", "Line No.");
        PurchCommentLine.SetRange(Date, WorkDate());
        if not PurchCommentLine.FindFirst() then
            Date := WorkDate();
    end;
}

