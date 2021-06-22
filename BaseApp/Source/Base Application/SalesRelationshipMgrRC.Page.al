page 9026 "Sales & Relationship Mgr. RC"
{
    Caption = 'Sales and Relationship Manager', Comment = 'Use same translation as ''Profile Description'' (if applicable)';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control60; "Headline RC Relationship Mgt.")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control6; "Sales Pipeline Chart")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control4; "Opportunity Chart")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control1; "Sales & Relationship Mgr. Act.")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control11; "Relationship Performance")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control16; "Team Member Activities")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control56; "User Tasks Activities")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control2; "Power BI Report Spinner Part")
            {
                ApplicationArea = RelationshipMgmt;
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Customer - &Order Summary")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Customer - &Order Summary';
                Image = "Report";
                RunObject = Report "Customer - Order Summary";
                ToolTip = 'View the quantity not yet shipped for each customer in three periods of 30 days each, starting from a selected date. There are also columns with orders to be shipped before and after the three periods and a column with the total order detail for each customer. The report can be used to analyze a company''s expected sales volume.';
            }
            action("Customer - &Top 10 List")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Customer - &Top 10 List';
                Image = "Report";
                RunObject = Report "Customer - Top 10 List";
                ToolTip = 'View which customers purchase the most or owe the most in a selected period. Only customers that have either purchases during the period or a balance at the end of the period will be included.';
            }
            separator(Action17)
            {
            }
            action("S&ales Statistics")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'S&ales Statistics';
                Image = "Report";
                RunObject = Report "Sales Statistics";
                ToolTip = 'View detailed information about sales to your customers.';
            }
            action("Salesperson - Sales &Statistics")
            {
                ApplicationArea = Suite, RelationshipMgmt;
                Caption = 'Salesperson - Sales &Statistics';
                Image = "Report";
                RunObject = Report "Salesperson - Sales Statistics";
                ToolTip = 'View amounts for sales, profit, invoice discount, and payment discount, as well as profit percentage, for each salesperson for a selected period. The report also shows the adjusted profit and adjusted profit percentage, which reflect any changes to the original costs of the items in the sales.';
            }
            action("Salesperson - &Commission")
            {
                ApplicationArea = Suite, RelationshipMgmt;
                Caption = 'Salesperson - &Commission';
                Image = "Report";
                RunObject = Report "Salesperson - Commission";
                ToolTip = 'View a list of invoices for each salesperson for a selected period. The following information is shown for each invoice: Customer number, sales amount, profit amount, and the commission on sales amount and profit amount. The report also shows the adjusted profit and the adjusted profit commission, which are the profit figures that reflect any changes to the original costs of the goods sold.';
            }
            separator(Action22)
            {
            }
            action("Campaign - &Details")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Campaign - &Details';
                Image = "Report";
                RunObject = Report "Campaign - Details";
                ToolTip = 'Show detailed information about the campaign.';
            }
        }
        area(embedding)
        {
            action(Contacts)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Contacts';
                Image = CustomerContact;
                RunObject = Page "Contact List";
                ToolTip = 'View a list of all your contacts.';
            }
            action(Opportunities)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Opportunities';
                RunObject = Page "Opportunity List";
                ToolTip = 'View the sales opportunities that are handled by salespeople for the contact. Opportunities must involve a contact and can be linked to campaigns.';
            }
            action("Sales Quotes")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Sales Quotes';
                Image = Quote;
                RunObject = Page "Sales Quotes";
                ToolTip = 'Make offers to customers to sell certain products on certain delivery and payment terms. While you negotiate with a customer, you can change and resend the sales quote as much as needed. When the customer accepts the offer, you convert the sales quote to a sales invoice or a sales order in which you process the sale.';
            }
            action("Sales Orders")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Sales Orders';
                Image = "Order";
                RunObject = Page "Sales Order List";
                ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
            }
            action(Customers)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Customers';
                Image = Customer;
                RunObject = Page "Customer List";
                ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
            }
            action(Items)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Items';
                Image = Item;
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
            action("Active Segments")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Active Segments';
                RunObject = Page "Segment List";
                ToolTip = 'View the list of active segments. Segments represent a grouping of contacts, so that you can interact with several contacts at once, for example by direct mail.';
            }
            action("Logged Segments")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Logged Segments';
                RunObject = Page "Logged Segments";
                ToolTip = 'View the list of segments containing contacts for which you have logged interactions. Segments represent a grouping of contacts, so that you can interact with several contacts at once, for example by direct mail.';
            }
            action(Campaigns)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Campaigns';
                Image = Campaign;
                RunObject = Page "Campaign List";
                ToolTip = 'View a list of all your campaigns.';
            }
            action("Cases - Dynamics 365 Customer Service")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Cases - Dynamics 365 Customer Service';
                RunObject = Page "CRM Case List";
                ToolTip = 'View the list of cases that you manage with Microsoft Dynamics 365 Customer Service.';
            }
            action(Salespersons)
            {
                ApplicationArea = Suite, RelationshipMgmt;
                Caption = 'Salespersons';
                RunObject = Page "Salespersons/Purchasers";
                ToolTip = 'View or edit information about the sales people that work for you and which customers they are assigned to.';
            }
        }
        area(sections)
        {
            group(Action257)
            {
                Caption = 'Sales';
                action(Action67)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contacts';
                    Image = CustomerContact;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Contact List";
                    ToolTip = 'View or edit detailed information about the contact persons at your business partners that you use to communicate business activities with or that you target marketing activities towards.';
                }
                action(Action66)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunities';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Opportunity List";
                    ToolTip = 'View the sales opportunities that are handled by salespeople for the contact. Opportunities must involve a contact and can be linked to campaigns.';
                }
                action(Action65)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales Quotes';
                    Image = Quote;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Sales Quotes";
                    ToolTip = 'Make offers to customers to sell certain products on certain delivery and payment terms. While you negotiate with a customer, you can change and resend the sales quote as much as needed. When the customer accepts the offer, you convert the sales quote to a sales invoice or a sales order in which you process the sale.';
                }
                action(Action64)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales Orders';
                    Image = "Order";
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Sales Order List";
                    ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
                }
                action("Blanket Sales Orders")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Blanket Sales Orders';
                    Image = Reminder;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Blanket Sales Orders";
                    ToolTip = 'Use blanket sales orders as a framework for a long-term agreement between you and your customers to sell large quantities that are to be delivered in several smaller shipments over a certain period of time. Blanket orders often cover only one item with predetermined delivery dates. The main reason for using a blanket order rather than a sales order is that quantities entered on a blanket order do not affect item availability and thus can be used as a worksheet for monitoring, forecasting, and planning purposes..';
                }
                action(Action63)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Customers';
                    Image = Customer;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Customer List";
                    ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
                }
                action(Action62)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Items';
                    Image = Item;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Item List";
                    ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
                }
                action(Segments)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Segments';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Segment List";
                    ToolTip = 'View the list of segments that are currently used in active campaigns. Segments represent a grouping of contacts, so that you can interact with several contacts at once, for example by direct mail.';
                }
                action(Action59)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaigns';
                    Image = Campaign;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Campaign List";
                    ToolTip = 'View the list of your marketing campaigns. A campaign organizes all the sales and marketing activities involving your contacts, such as a sales promotion campaign.';
                }
                action(Action58)
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Salespersons';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Salespersons/Purchasers";
                    ToolTip = 'View or edit information about the sales people that work for you and which customers they are assigned to.';
                }
            }
            group("Administration Sales/Purchase")
            {
                Caption = 'Administration Sales/Purchase';
                Image = AdministrationSalesPurchases;
                action("Salespeople/Purchasers")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Salespeople/Purchasers';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Salespersons/Purchasers";
                    ToolTip = 'View or edit information about the sales people and purchasers that work for you and which customers and vendors they are assigned to.';
                }
                action("Customer Price Groups")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Customer Price Groups';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Customer Price Groups";
                    ToolTip = 'View a list of your customer price groups.';
                }
                action("Cust. Invoice Discounts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Cust. Invoice Discounts';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Cust. Invoice Discounts";
                    ToolTip = 'View or edit invoice discounts that you grant to certain customers.';
                }
                action("Vend. Invoice Discounts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Vend. Invoice Discounts';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Vend. Invoice Discounts";
                    ToolTip = 'View the invoice discounts that your vendors grant you.';
                }
                action("Item Disc. Groups")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Item Disc. Groups';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Item Disc. Groups";
                    ToolTip = 'View or edit discount group codes that you can use as criteria when you grant special discounts to customers.';
                }
                action("Sales Cycles")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales Cycles';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Sales Cycles";
                    ToolTip = 'View the different sales cycles that you use to manage sales opportunities.';
                }
            }
            group(Analysis)
            {
                Caption = 'Analysis';
                action("Sales Analysis Reports")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Analysis Reports';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Analysis Report Sale";
                    ToolTip = 'Analyze the dynamics of your sales according to key sales performance indicators that you select, for example, sales turnover in both amounts and quantities, contribution margin, or progress of actual sales against the budget. You can also use the report to analyze your average sales prices and evaluate the sales performance of your sales force.';
                }
                action("Sales Analysis by Dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Sales Analysis by Dimensions';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Analysis View List Sales";
                    ToolTip = 'View sales amounts in G/L accounts by their dimension values and other filters that you define in an analysis view and then show in a matrix window.';
                }
                action("Sales Budgets")
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Sales Budgets';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Budget Names Sales";
                    ToolTip = 'Enter item sales values of type amount, quantity, or cost for expected item sales in different time periods. You can create sales budgets by items, customers, customer groups, or other dimensions in your business. The resulting sales budgets can be reviewed here or they can be used in comparisons with actual sales data in sales analysis reports.';
                }
                action(Action38)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contacts';
                    Image = CustomerContact;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Contact List";
                    ToolTip = 'View a list of all your contacts.';
                }
                action(Action21)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Customers';
                    Image = Customer;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Customer List";
                    ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
                }
            }
            group(SetupAndExtensions)
            {
                Caption = 'Setup & Extensions';
                Image = Setup;
                ToolTip = 'Overview and change system and application settings, and manage extensions and services';
                action("Assisted Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assisted Setup';
                    Image = QuestionaireSetup;
                    RunObject = Page "Assisted Setup";
                    ToolTip = 'Set up core functionality such as sales tax, sending documents as email, and approval workflow by running through a few pages that guide you through the information.';
                }
                action("Manual Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Manual Setup';
                    RunObject = Page "Manual Setup";
                    ToolTip = 'Define your company policies for business departments and for general activities by filling setup windows manually.';
                }
                action("Service Connections")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Service Connections';
                    Image = ServiceTasks;
                    RunObject = Page "Service Connections";
                    ToolTip = 'Enable and configure external services, such as exchange rate updates, Microsoft Social Engagement, and electronic bank integration.';
                }
                action(Extensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extensions';
                    Image = NonStockItemSetup;
                    RunObject = Page "Extension Management";
                    ToolTip = 'Install Extensions for greater functionality of the system.';
                }
                action(Workflows)
                {
                    ApplicationArea = Suite;
                    Caption = 'Workflows';
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page Workflows;
                    ToolTip = 'Set up or enable workflows that connect business-process tasks performed by different users. System tasks, such as automatic posting, can be included as steps in workflows, preceded or followed by user tasks. Requesting and granting approval to create new records are typical workflow steps.';
                }
            }
        }
        area(processing)
        {
            group(New)
            {
                Caption = 'New';
                action(NewContact)
                {
                    AccessByPermission = TableData Contact = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact';
                    Image = AddContacts;
                    RunObject = Page "Contact Card";
                    RunPageMode = Create;
                    ToolTip = 'Create a new contact. Contacts are persons at your business partners that you use to communicate business activities with or that you target marketing activities towards.';
                }
                action(NewOpportunity)
                {
                    AccessByPermission = TableData Opportunity = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunity';
                    Image = NewOpportunity;
                    RunObject = Page "Opportunity Card";
                    RunPageMode = Create;
                    ToolTip = 'View the sales opportunities that are handled by salespeople for the contact. Opportunities must involve a contact and can be linked to campaigns.';
                }
                action(NewSegment)
                {
                    AccessByPermission = TableData "Segment Header" = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Segment';
                    Image = Segment;
                    RunObject = Page Segment;
                    RunPageMode = Create;
                    ToolTip = 'Create a new segment where you manage interactions with a contact.';
                }
                action(NewCampaign)
                {
                    AccessByPermission = TableData Campaign = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign';
                    Image = Campaign;
                    RunObject = Page "Campaign Card";
                    RunPageMode = Create;
                    ToolTip = 'Create a new campaign';
                }
            }
            group("Sales Prices")
            {
                Caption = 'Sales Prices';
                action("Sales Price &Worksheet")
                {
                    AccessByPermission = TableData "Sales Price Worksheet" = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales Price &Worksheet';
                    Image = PriceWorksheet;
                    RunObject = Page "Sales Price Worksheet";
                    ToolTip = 'Manage sales prices for individual customers, for a group of customers, for all customers, or for a campaign.';
                }
                action("Sales &Prices")
                {
                    AccessByPermission = TableData "Sales Price and Line Disc Buff" = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales &Prices';
                    Image = SalesPrices;
                    RunObject = Page "Sales Prices";
                    ToolTip = 'Define how to set up sales price agreements. These sales prices can be for individual customers, for a group of customers, for all customers, or for a campaign.';
                }
                action("Sales Line &Discounts")
                {
                    AccessByPermission = TableData "Sales Price and Line Disc Buff" = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales Line &Discounts';
                    Image = SalesLineDisc;
                    RunObject = Page "Sales Line Discounts";
                    ToolTip = 'View or edit sales line discounts that you grant when certain conditions are met, such as customer, quantity, or ending date. The discount agreements can be for individual customers, for a group of customers, for all customers or for a campaign.';
                }
            }
            group(Flow)
            {
                Caption = 'Flow';
                action("Manage Flows")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Manage Flows';
                    Image = Flow;
                    RunObject = Page "Flow Selector";
                    ToolTip = 'View or edit automated workflows created with Microsoft Flow.';
                }
            }
        }
    }
}

