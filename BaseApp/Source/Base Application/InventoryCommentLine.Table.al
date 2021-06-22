table 5748 "Inventory Comment Line"
{
    Caption = 'Inventory Comment Line';
    LookupPageID = "Inventory Comment List";

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Transfer Order,Posted Transfer Shipment,Posted Transfer Receipt';
            OptionMembers = " ","Transfer Order","Posted Transfer Shipment","Posted Transfer Receipt";
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
    }

    keys
    {
        key(Key1; "Document Type", "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        InvtCommentLine: Record "Inventory Comment Line";
    begin
        InvtCommentLine.SetRange("Document Type", "Document Type");
        InvtCommentLine.SetRange("No.", "No.");
        InvtCommentLine.SetRange(Date, WorkDate);
        if not InvtCommentLine.FindFirst then
            Date := WorkDate;

        OnAfterSetUpNewLine(Rec, InvtCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var InventoryCommentLineRec: Record "Inventory Comment Line"; var InventoryCommentLineFilter: Record "Inventory Comment Line")
    begin
    end;
}

