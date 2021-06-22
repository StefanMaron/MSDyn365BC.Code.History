page 9125 "Item Application FactBox"
{
    Caption = 'Item Application';
    Editable = false;
    PageType = CardPart;
    SourceTable = "Item Ledger Entry";

    layout
    {
        area(content)
        {
            field("Entry No."; "Entry No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
            }
            field("Item No."; "Item No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the item in the entry.';
            }
            field("Item.""Costing Method"""; Item."Costing Method")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Costing Method';
                ToolTip = 'Specifies which costing method applies to the item number.';
            }
            field("Posting Date"; "Posting Date")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the entry''s posting date.';
            }
            field("Entry Type"; "Entry Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies which type of transaction that the entry is created from.';
            }
            field(Quantity; Quantity)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of units of the item in the item entry.';
            }
            field("Reserved Quantity"; "Reserved Quantity")
            {
                ApplicationArea = Reservation;
                ToolTip = 'Specifies how many units of the item on the line have been reserved.';
            }
            field("Remaining Quantity"; "Remaining Quantity")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the quantity in the Quantity field that remains to be processed.';
            }
            field(Available; Available)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Available';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the number available for the relevant entry.';
            }
            field(Applied; Applied)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Applied';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the number applied to the relevant entry.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcFields("Reserved Quantity");
        Available := Quantity - "Reserved Quantity";
        Applied := ItemApplnEntry.OutboundApplied("Entry No.", false) - ItemApplnEntry.InboundApplied("Entry No.", false);

        if not Item.Get("Item No.") then
            Item.Reset();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Available := 0;
        Applied := 0;
        Clear(Item);

        exit(Find(Which));
    end;

    var
        Item: Record Item;
        ItemApplnEntry: Record "Item Application Entry";
        Available: Decimal;
        Applied: Decimal;
}

