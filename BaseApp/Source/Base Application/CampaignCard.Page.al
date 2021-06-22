page 5086 "Campaign Card"
{
    Caption = 'Campaign Card';
    PageType = Card;
    PopulateAllFields = true;
    PromotedActionCategories = 'New,Process,Report,Campaign,Navigate';
    SourceTable = Campaign;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the campaign.';
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
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the salesperson responsible for the campaign.';
                }
                field("Last Date Modified"; "Last Date Modified")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date when the campaign card was last modified. This field is not editable.';
                }
                field(Activated; Activated)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies if a sales lines price discount has been activated. After you set up a campaign and create segments for it, you can create discounts for targeted audiences.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
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
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = CONST(5071),
                                  "No." = FIELD("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
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
                    PromotedCategory = Category5;
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
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Opportunity List";
                    RunPageLink = "Campaign No." = FIELD("No.");
                    RunPageView = SORTING("Campaign No.");
                    ToolTip = 'View opportunities for the campaign.';
                }
                action("Sales &Prices")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales &Prices';
                    Image = SalesPrices;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Sales Prices";
                    RunPageLink = "Sales Type" = CONST(Campaign),
                                  "Sales Code" = FIELD("No.");
                    RunPageView = SORTING("Sales Type", "Sales Code");
                    ToolTip = 'Define how to set up sales price agreements. These sales prices can be for individual customers, for a group of customers, for all customers, or for a campaign.';
                }
                action("Sales &Line Discounts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales &Line Discounts';
                    Image = SalesLineDisc;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Sales Line Discounts";
                    RunPageLink = "Sales Type" = CONST(Campaign),
                                  "Sales Code" = FIELD("No.");
                    RunPageView = SORTING("Sales Type", "Sales Code");
                    ToolTip = 'View the sales line discounts that are available. These discount agreements can be for individual customers, for a group of customers, for all customers or for a campaign.';
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(ActivateSalesPricesLineDisc)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = '&Activate Sales Prices/Line Discounts';
                    Image = ActivateDiscounts;
                    Promoted = true;
                    PromotedCategory = Process;
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
                    PromotedCategory = Process;
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
                RunObject = Report "Campaign - Details";
                ToolTip = 'Show detailed information about the campaign.';
            }
        }
    }

    var
        CampaignMgmt: Codeunit "Campaign Target Group Mgt";
}

