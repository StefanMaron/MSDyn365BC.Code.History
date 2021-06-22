page 5726 "Catalog Item List"
{
    AdditionalSearchTerms = 'non-inventoriable item';
    ApplicationArea = Basic, Suite, Service;
    Caption = 'Catalog Items';
    CardPageID = "Catalog Item Card";
    Editable = false;
    MultipleNewLines = false;
    PageType = List;
    SourceTable = "Nonstock Item";
    SourceTableView = SORTING("Vendor Item No.", "Manufacturer Code")
                      ORDER(Ascending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Vendor Item No."; "Vendor Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                }
                field("Manufacturer Code"; "Manufacturer Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the manufacturer of the catalog item.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item number that the program has generated for this catalog item.';
                    Visible = false;
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor from whom you can purchase the catalog item.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the catalog item.';
                }
                field("Unit of Measure"; "Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                }
                field("Published Cost"; "Published Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the published cost or vendor list price for the catalog item.';
                }
                field("Negotiated Cost"; "Negotiated Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the price you negotiated to pay for the catalog item.';
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Basic, Suite;
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
                field("Item Template Code"; "Item Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the item template used for this catalog item.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the catalog item card was last modified.';
                }
                field("Bar Code"; "Bar Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bar code of the catalog item.';
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
        area(reporting)
        {
            action("Catalog Item Sales")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Catalog Item Sales';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Catalog Item Sales";
                ToolTip = 'View a list of item sales for each catalog item during a selected time period. It can be used to review a company''s sale of catalog items.';
            }
            action("Item Substitutions")
            {
                ApplicationArea = Suite;
                Caption = 'Item Substitutions';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Item Substitutions";
                ToolTip = 'View or edit any substitute items that are set up to be traded instead of the item in case it is not available.';
            }
        }
    }
}

