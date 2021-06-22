page 512 "Customer Disc. Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Disc. Groups';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Navigate';
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
                    PromotedCategory = Category4;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View the sales line discounts that are available. These discount agreements can be for individual customers, for a group of customers, for all customers or for a campaign.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';

                    trigger OnAction()
                    var
                        SalesLineDiscount: Record "Sales Line Discount";
                    begin
                        SalesLineDiscount.SetCurrentKey("Sales Type", "Sales Code");
                        SalesLineDiscount.SetRange("Sales Type", SalesLineDiscount."Sales Type"::"Customer Disc. Group");
                        SalesLineDiscount.SetRange("Sales Code", Code);
                        Page.Run(Page::"Sales Line Discounts", SalesLineDiscount);
                    end;
                }
                action(PriceLists)
                {
                    AccessByPermission = TableData "Sales Discount Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Price Lists';
                    Image = SalesLineDisc;
                    Promoted = true;
                    PromotedCategory = Category4;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales price lists with discounts for products that you sell to customers that belong to the customer discount group.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec);
                    end;
                }

            }
        }
    }
    trigger OnOpenPage()
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        ExtendedPriceEnabled: Boolean;

    procedure GetSelectionFilter(): Text
    var
        CustDiscGr: Record "Customer Discount Group";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(CustDiscGr);
        exit(SelectionFilterManagement.GetSelectionFilterForCustomerDiscountGroup(CustDiscGr));
    end;
}

