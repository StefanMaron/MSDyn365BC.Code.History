namespace Microsoft.Inventory.Ledger;

page 506 "Item Application Entries"
{
    Caption = 'Item Application Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Item Application Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the posting date that corresponds to the posting date of the item ledger entry, for which this item application entry was created.';
                }
                field("Item Ledger Entry No."; Rec."Item Ledger Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies one or more item application entries for each inventory transaction that is posted.';
                }
                field("Inbound Item Entry No."; Rec."Inbound Item Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the item ledger entry corresponding to the inventory increase or positive quantity in inventory.';
                }
                field("Outbound Item Entry No."; Rec."Outbound Item Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the item ledger entry corresponding to the inventory decrease for this entry.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the quantity of the item that is being applied from the inventory decrease in the Outbound Item Entry No. field, to the inventory increase in the Inbound Item Entry No. field.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

