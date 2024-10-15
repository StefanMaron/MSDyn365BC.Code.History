namespace Microsoft.Inventory.Item;

page 9152 "My Items"
{
    Caption = 'My Items';
    PageType = ListPart;
    SourceTable = "My Item";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item numbers that are displayed in the My Item Cue on the Role Center.';

                    trigger OnValidate()
                    begin
                        SyncFieldsWithItem();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies a description of the item.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit Price';
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the item''s unit price.';
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory';
                    ToolTip = 'Specifies the inventory quantities of my items.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Open)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open';
                Image = ViewDetails;
                RunObject = Page "Item Card";
                RunPageLink = "No." = field("Item No.");
                RunPageMode = View;
                ShortCutKey = 'Return';
                ToolTip = 'Open the card for the selected record.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SyncFieldsWithItem();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(Item)
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId);
    end;

    var
        Item: Record Item;

    local procedure SyncFieldsWithItem()
    var
        MyItem: Record "My Item";
    begin
        Clear(Item);

        if Item.Get(Rec."Item No.") then
            if (Rec.Description <> Item.Description) or (Rec."Unit Price" <> Item."Unit Price") then begin
                Rec.Description := Item.Description;
                Rec."Unit Price" := Item."Unit Price";
                if MyItem.Get(Rec."User ID", Rec."Item No.") then
                    Rec.Modify();
            end;
    end;
}

