page 7380 "Phys. Invt. Item Selection"
{
    Caption = 'Phys. Invt. Item Selection';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Phys. Invt. Item Selection";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item for which the cycle counting can be performed.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the item.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location where the cycle counting is performed.';
                }
                field("Shelf No."; "Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item for informational use.';
                    Visible = false;
                }
                field("Phys Invt Counting Period Code"; "Phys Invt Counting Period Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the counting period that indicates how often you want to count the item or stockkeeping unit in a physical inventory.';
                }
                field("Last Counting Date"; "Last Counting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date when the counting period for the item or stockkeeping unit was updated.';
                }
                field("Next Counting Start Date"; "Next Counting Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting date of the next counting period.';
                }
                field("Next Counting End Date"; "Next Counting End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending date of the next counting period.';
                }
                field("Count Frequency per Year"; "Count Frequency per Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of times you want the item or stockkeeping unit to be counted each year.';
                    Visible = false;
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Item Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Item Card';
                    Image = Item;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = FIELD("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the item.';
                }
                action("SKU Card")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'SKU Card';
                    Image = SKU;
                    RunObject = Page "Stockkeeping Unit List";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Location Code" = FIELD("Location Code");
                    ToolTip = 'View or edit detailed information for the stockkeeping unit.';
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush;
    end;

    local procedure LookupOKOnPush()
    begin
        CurrPage.SetSelectionFilter(Rec);
        ModifyAll(Selected, true);
    end;
}

