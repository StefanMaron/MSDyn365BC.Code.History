table 5883 "Phys. Invt. Comment Line"
{
    Caption = 'Phys. Invt. Comment Line';
    DrillDownPageID = "Phys. Inventory Comment List";
    LookupPageID = "Phys. Inventory Comment List";

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Order,Recording,Posted Order,Posted Recording';
            OptionMembers = "Order",Recording,"Posted Order","Posted Recording";
        }
        field(2; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            TableRelation = IF ("Document Type" = CONST(Order)) "Phys. Invt. Order Header"
            ELSE
            IF ("Document Type" = CONST(Recording)) "Phys. Invt. Record Header"."Order No."
            ELSE
            IF ("Document Type" = CONST("Posted Order")) "Pstd. Phys. Invt. Order Hdr"
            ELSE
            IF ("Document Type" = CONST("Posted Recording")) "Pstd. Phys. Invt. Record Hdr"."Order No.";
        }
        field(3; "Recording No."; Integer)
        {
            Caption = 'Recording No.';
            TableRelation = IF ("Document Type" = CONST(Recording)) "Phys. Invt. Record Header"."Recording No." WHERE("Order No." = FIELD("Order No."))
            ELSE
            IF ("Document Type" = CONST("Posted Recording")) "Pstd. Phys. Invt. Record Hdr"."Recording No." WHERE("Order No." = FIELD("Order No."));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; Date; Date)
        {
            Caption = 'Date';
        }
        field(11; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(12; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Document Type", "Order No.", "Recording No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if "Document Type" in ["Document Type"::Order, "Document Type"::"Posted Order"] then
            TestField("Recording No.", 0);
    end;

    procedure SetUpNewLine()
    var
        PhysInvtCommentLine: Record "Phys. Invt. Comment Line";
    begin
        PhysInvtCommentLine.SetRange("Document Type", "Document Type");
        PhysInvtCommentLine.SetRange("Order No.", "Order No.");
        PhysInvtCommentLine.SetRange("Recording No.", "Recording No.");
        if not PhysInvtCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, PhysInvtCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var PhysInvtCommentLineRec: Record "Phys. Invt. Comment Line"; var PhysInvtCommentLineFilter: Record "Phys. Invt. Comment Line")
    begin
    end;
}

