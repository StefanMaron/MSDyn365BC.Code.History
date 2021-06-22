page 2104 "O365 Sales Item List"
{
    Caption = 'Price List';
    CardPageID = "O365 Item Card";
    DeleteAllowed = false;
    Editable = true;
    ModifyAllowed = true;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = Item;
    SourceTableView = SORTING(Description);

    layout
    {
        area(content)
        {
            repeater(Price)
            {
                Caption = 'Price';
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    ToolTip = 'Specifies what you are selling. You can enter a maximum of 30 characters, both numbers and letters.';
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    AutoFormatExpression = '2';
                    AutoFormatType = 10;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(DeleteLine)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Delete Price';
                Gesture = RightSwipe;
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                Scope = Repeater;
                ToolTip = 'Delete the selected price.';

                trigger OnAction()
                begin
                    if not Confirm(DeleteQst) then
                        exit;
                    Delete(true);
                    CurrPage.Update;
                end;
            }
        }
    }

    var
        DeleteQst: Label 'Are you sure?';
}

