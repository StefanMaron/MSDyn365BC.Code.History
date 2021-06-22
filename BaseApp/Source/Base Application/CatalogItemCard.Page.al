page 5725 "Catalog Item Card"
{
    Caption = 'Catalog Item Card';
    PageType = Card;
    SourceTable = "Nonstock Item";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit then
                            CurrPage.Update;
                    end;
                }
                field("Manufacturer Code"; "Manufacturer Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the manufacturer of the catalog item.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the vendor from whom you can purchase the catalog item.';
                }
                field("Vendor Item No."; "Vendor Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the item number that the program has generated for this catalog item.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the catalog item.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the catalog item card was last modified.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Published Cost"; "Published Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the published cost or vendor list price for the catalog item.';
                }
                field("Negotiated Cost"; "Negotiated Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the price you negotiated to pay for the catalog item.';
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Gross Weight"; "Gross Weight")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the gross weight, including the weight of any packaging, of the catalog item.';
                }
                field("Net Weight"; "Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net weight of the item. The weight of packaging materials is not included.';
                }
                field("Bar Code"; "Bar Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bar code of the catalog item.';
                }
                field("Item Template Code"; "Item Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the item template used for this catalog item.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ca&talog Item")
            {
                Caption = 'Ca&talog Item';
                Image = NonStockItem;
                action("Substituti&ons")
                {
                    ApplicationArea = Suite;
                    Caption = 'Substituti&ons';
                    Image = ItemSubstitution;
                    RunObject = Page "Item Substitution Entry";
                    RunPageLink = Type = CONST("Nonstock Item"),
                                  "No." = FIELD("Entry No.");
                    ToolTip = 'View substitute items that are set up to be sold instead of the item.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Nonstock Item"),
                                  "No." = FIELD("Entry No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Create Item")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Create Item';
                    Image = NewItemNonStock;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Convert the catalog item card to a normal item card, according to an item template that you choose.';

                    trigger OnAction()
                    begin
                        CatalogItemMgt.NonstockAutoItem(Rec);
                    end;
                }
            }
        }
    }

    var
        CatalogItemMgt: Codeunit "Catalog Item Management";
}

