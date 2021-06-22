page 512 "Customer Disc. Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Disc. Groups';
    PageType = List;
    SourceTable = "Customer Discount Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the customer discount group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the customer discount group.';
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
            group("Cust. &Disc. Groups")
            {
                Caption = 'Cust. &Disc. Groups';
                Image = Group;
                action(SalesLineDiscounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales &Line Discounts';
                    Image = SalesLineDisc;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Sales Line Discounts";
                    RunPageLink = "Sales Type" = CONST("Customer Disc. Group"),
                                  "Sales Code" = FIELD(Code);
                    RunPageView = SORTING("Sales Type", "Sales Code");
                    ToolTip = 'View the sales line discounts that are available. These discount agreements can be for individual customers, for a group of customers, for all customers or for a campaign.';
                }
            }
        }
    }

    procedure GetSelectionFilter(): Text
    var
        CustDiscGr: Record "Customer Discount Group";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(CustDiscGr);
        exit(SelectionFilterManagement.GetSelectionFilterForCustomerDiscountGroup(CustDiscGr));
    end;
}

