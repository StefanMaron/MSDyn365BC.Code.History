page 5087 "Campaign List"
{
    ApplicationArea = RelationshipMgmt;
    Caption = 'Campaigns';
    CardPageID = "Campaign Card";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Campaign,Prices & Discounts';
    SourceTable = Campaign;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the campaign.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the salesperson responsible for the campaign.';
                }
                field("Status Code"; "Status Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the status code for the campaign.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date on which the campaign is valid. There are certain rules for how dates should be entered.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the last day on which this campaign is valid.';
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
            group("C&ampaign")
            {
                Caption = 'C&ampaign';
                Image = Campaign;
                action("E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'E&ntries';
                    Image = Entries;
                    RunObject = Page "Campaign Entries";
                    RunPageLink = "Campaign No." = FIELD("No.");
                    RunPageView = SORTING("Campaign No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the entries linked to the campaign. In this window, you cannot manually create new campaign entries.';
                }
                action("Co&mments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = CONST(Campaign),
                                  "No." = FIELD("No."),
                                  "Sub No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Campaign Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View key figures concerning your campaign.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        Promoted = true;
                        PromotedCategory = Category4;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(5071),
                                      "No." = FIELD("No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        Promoted = true;
                        PromotedCategory = Category4;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            Campaign: Record Campaign;
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Campaign);
                            DefaultDimMultiple.SetMultiRecord(Campaign, FieldNo("No."));
                            DefaultDimMultiple.RunModal;
                        end;
                    }
                }
                action("T&asks")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'T&asks';
                    Image = TaskList;
                    RunObject = Page "Task List";
                    RunPageLink = "Campaign No." = FIELD("No."),
                                  "System To-do Type" = FILTER(Organizer);
                    RunPageView = SORTING("Campaign No.");
                    ToolTip = 'View tasks for the campaign.';
                }
                action("S&egments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'S&egments';
                    Image = Segment;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    RunObject = Page "Segment List";
                    RunPageLink = "Campaign No." = FIELD("No.");
                    RunPageView = SORTING("Campaign No.");
                    ToolTip = 'View a list of all the open segments. Open segments are those for which the interaction has not been logged yet.';
                }
                action("Oppo&rtunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Oppo&rtunities';
                    Image = OpportunitiesList;
                    RunObject = Page "Opportunity List";
                    RunPageLink = "Campaign No." = FIELD("No.");
                    RunPageView = SORTING("Campaign No.");
                    ToolTip = 'View sales opportunities handled by salespeople.';
                }
                action("Sales &Prices")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales &Prices';
                    Promoted = true;
                    PromotedCategory = Category5;
                    Image = SalesPrices;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'Define how to set up sales price agreements. These sales prices can be for individual customers, for a group of customers, for all customers, or for a campaign.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
                    ObsoleteTag = '17.0';

                    trigger OnAction()
                    var
                        SalesPrice: Record "Sales Price";
                    begin
                        SalesPrice.SetCurrentKey("Sales Type", "Sales Code");
                        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Campaign);
                        SalesPrice.SetRange("Sales Code", "No.");
                        Page.Run(Page::"Sales Prices", SalesPrice);
                    end;
                }
                action("Sales &Line Discounts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales &Line Discounts';
                    Promoted = true;
                    PromotedCategory = Category5;
                    Image = SalesLineDisc;
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
                        SalesLineDiscount.SetRange("Sales Type", SalesLineDiscount."Sales Type"::Campaign);
                        SalesLineDiscount.SetRange("Sales Code", "No.");
                        Page.Run(Page::"Sales Line Discounts", SalesLineDiscount);
                    end;
                }
                action(PriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Promoted = true;
                    PromotedCategory = Category5;
                    Caption = 'Sales Price Lists';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales price lists for products that you sell to the customer. A product price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, "Price Type"::Sale, "Price Amount Type"::Any);
                    end;
                }
                action(PriceListsDiscounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Price Lists (Discounts)';
                    Image = LineDiscount;
                    Visible = false;
                    ToolTip = 'View or set up different discounts for products that you sell to the customer. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Action PriceLists shows all sales price lists with prices and discounts';
                    ObsoleteTag = '18.0';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, PriceType::Sale, AmountType::Discount);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Activate Sales Prices/Line Discounts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = '&Activate Sales Prices/Line Discounts';
                    Image = ActivateDiscounts;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Activate discounts that are associated with the campaign.';

                    trigger OnAction()
                    begin
                        CampaignMgmt.ActivateCampaign(Rec);
                    end;
                }
                action("&Deactivate Sales Prices/Line Discounts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = '&Deactivate Sales Prices/Line Discounts';
                    Image = DeactivateDiscounts;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Deactivate discounts that are associated with the campaign.';

                    trigger OnAction()
                    begin
                        CampaignMgmt.DeactivateCampaign(Rec, true);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Campaign Details")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Campaign Details';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Campaign - Details";
                ToolTip = 'Show detailed information about the campaign.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        CampaignMgmt: Codeunit "Campaign Target Group Mgt";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        ExtendedPriceEnabled: Boolean;

    procedure GetSelectionFilter(): Text
    var
        Campaign: Record Campaign;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Campaign);
        exit(SelectionFilterManagement.GetSelectionFilterForCampaign(Campaign));
    end;
}

