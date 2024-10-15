page 8907 "Sales & Marketing Manager RC"
{
    Caption = 'Sales & Marketing Manager RC';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Sales';
                action("Customers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customers';
                    RunObject = Page "Customer List";
                }
                action("Contacts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contacts';
                    RunObject = Page "Contact List";
                }
                action("Salespeople")
                {
                    ApplicationArea = Suite;
                    Caption = 'Salespeople/Purchasers';
                    RunObject = Page "Salespersons/Purchasers";
                }
                action("Teams")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Teams';
                    RunObject = Page "Teams";
                }
                action("Tasks")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tasks';
                    RunObject = Page "Tasks";
                }
                action("Opportunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunities';
                    RunObject = Page "Opportunity List";
                }
                group("Group1")
                {
                    Caption = 'Budgets & Analysis';
                    action("Sales Budgets")
                    {
                        ApplicationArea = SalesBudget;
                        Caption = 'Sales Budgets';
                        RunObject = Page "Budget Names Sales";
                    }
                    action("Sales Analysis Reports")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Sales Analysis Reports';
                        RunObject = Page "Analysis Report Sale";
                    }
                    action("Sales Analysis by Dimensions")
                    {
                        ApplicationArea = Dimensions, SalesAnalysis;
                        Caption = 'Sales Analysis by Dimensions';
                        RunObject = Page "Analysis View List Sales";
                    }
                    action("Forecast")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Production Forecast';
                        RunObject = Page "Demand Forecast";
                    }
                    action("Item Dimensions - Detail")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Detail';
                        RunObject = Report "Item Dimensions - Detail";
                    }
                    action("Item Dimensions - Total")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Total';
                        RunObject = Report "Item Dimensions - Total";
                    }
                    action("Opportunities Matrix")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Opportunity Analysis';
                        RunObject = Page "Opportunities";
                    }
                }
                group("Group2")
                {
                    Caption = 'Reports';
                    action("Sales Deferral Summary")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Sales Deferral Summary';
                        RunObject = Report "Deferral Summary - Sales";
                    }
                    group("Group3")
                    {
                        Caption = 'Salespeople/Teams';
                        action("Salesperson - Tasks")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Salesperson Tasks';
                            RunObject = Report "Salesperson - Tasks";
                        }
                        action("Salesperson - Commission")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Salesperson Commission';
                            RunObject = Report "Salesperson - Commission";
                        }
                        action("Salesperson - Opportunities")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Salesperson Opportunities';
                            RunObject = Report "Salesperson - Opportunities";
                        }
                        action("Sales Statistics")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Sales Statistics';
                            RunObject = Report "Sales Statistics";
                        }
                        action("Team - Tasks")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Team Tasks';
                            RunObject = Report "Team - Tasks";
                        }
                        action("Salesperson - Sales Statistics")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Salesperson Sales Statistics';
                            RunObject = Report "Salesperson - Sales Statistics";
                        }
                    }
                    group("Group4")
                    {
                        Caption = 'Contacts';
                        action("Contact - Labels")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Contact Labels';
                            RunObject = Report "Contact - Labels";
                        }
                        action("Contact - Company Summary")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Contact - Company Summary';
                            RunObject = Report "Contact - Company Summary";
                        }
                        action("Questionnaire - Handouts")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Questionnaire - Handouts';
                            RunObject = Report "Questionnaire - Handouts";
                        }
                        action("Contact - List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Contact List';
                            RunObject = Report "Contact - List";
                        }
                        action("Orgl. Profile Summary")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Contact - Person Summary';
                            RunObject = Report "Contact - Person Summary";
                        }
                        action("Contact - Cover Sheet")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Contact - Cover Sheet';
                            RunObject = Report "Contact - Cover Sheet";
                        }
                    }
                    group("Group5")
                    {
                        Caption = 'Customers';
                        action("Customer - List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - List';
                            RunObject = Report "Customer - List";
                        }
                        action("Customer - Labels")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Customer Labels';
                            RunObject = Report "Customer - Labels";
                        }
                        action("Customer - Balance to Date")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - Balance to Date';
                            RunObject = Report "Customer - Balance to Date";
                        }
                        action("Customer - Order Summary")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - Order Summary';
                            RunObject = Report "Customer - Order Summary";
                        }
                        action("Customer/Item Sales")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer/Item Sales';
                            RunObject = Report "Customer/Item Sales";
                        }
                        action("Customer Register")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer Register';
                            RunObject = Report "Customer Register";
                        }
                        action("Customer - Order Detail")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - Order Detail';
                            RunObject = Report "Customer - Order Detail";
                        }
                        action("Customer - Top 10 List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer Top 10 List';
                            RunObject = Report "Customer - Top 10 List";
                        }
                        action("Customer - Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer Trial Balance';
                            RunObject = Report "Customer - Trial Balance";
                        }
                        action("Customer - Sales List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - Sales List';
                            RunObject = Report "Customer - Sales List";
                        }
                    }
                    group("Group6")
                    {
                        Caption = 'Opportunities';
                        action("Opportunity - List")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Opportunity - List';
                            RunObject = Report "Opportunity - List";
                        }
                        action("Opportunity - Details")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Opportunity - Details';
                            RunObject = Report "Opportunity - Details";
                        }
                        action("Sales Cycle - Analysis")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Sales Cycle - Analysis';
                            RunObject = Report "Sales Cycle - Analysis";
                        }
                    }
                }
            }
            group("Group7")
            {
                Caption = 'Order Processing';
                action("Customers1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customers';
                    RunObject = Page "Customer List";
                }
                action("Contacts1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contacts';
                    RunObject = Page "Contact List";
                }
                action("Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Quotes';
                    RunObject = Page "Sales Quotes";
                }
                action("Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Orders';
                    RunObject = Page "Sales Order List";
                }
                action("Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Sales Orders';
                    RunObject = Page "Blanket Sales Orders";
                }
                action("Return Orders")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Sales Return Orders';
                    RunObject = Page "Sales Return Order List";
                }
                action("Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Invoices';
                    RunObject = Page "Sales Invoice List";
                }
                action("Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Credit Memos';
                    RunObject = Page "Sales Credit Memos";
                }
                // action("Create Electronic Invoices")
                // {
                //     ApplicationArea = Basic, Suite;
                //     Caption = 'Create Electronic Invoices';
                //     RunObject = Report 13600;
                // }
                // action("Create Electronic Credit Memos")
                // {
                //     ApplicationArea = Basic, Suite;
                //     Caption = 'Create Electronic Credit Memos';
                //     RunObject = Report 13601;
                // }
                action("Certificates of Supply")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Certificates of Supply';
                    RunObject = Page "Certificates of Supply";
                }
                action("Order Planning")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order Planning';
                    RunObject = Page "Order Planning";
                }
                group("Group8")
                {
                    Caption = 'Posted Documents';
                    action("Posted Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Invoices';
                        RunObject = Page "Posted Sales Invoices";
                    }
                    action("Posted Sales Shipments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Shipments';
                        RunObject = Page "Posted Sales Shipments";
                    }
                    action("Posted Credit Memos")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Credit Memos';
                        RunObject = Page "Posted Sales Credit Memos";
                    }
                    action("Posted Return Receipts")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Posted Return Receipts';
                        RunObject = Page "Posted Return Receipts";
                    }
                }
                group("Group9")
                {
                    Caption = 'Registers/Entries';
                    action("G/L Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Registers';
                        RunObject = Page "G/L Registers";
                    }
                    action("Item Tracing")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item Tracing';
                        RunObject = Page "Item Tracing";
                    }
                    action("Sales Quote Archive")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Quote Archives';
                        RunObject = Page "Sales Quote Archives";
                    }
                    action("Sales Order Archive")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Order Archives';
                        RunObject = Page "Sales Order Archives";
                    }
                    action("Sales Return Order Archives")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Return Order Archives';
                        RunObject = Page "Sales Return List Archive";
                    }
                    action("Customer Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Ledger Entries';
                        RunObject = Page "Customer Ledger Entries";
                    }
                    action("Detailed Cust. Ledg. Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Customer Ledgerg Entries';
                        RunObject = Page "Detailed Cust. Ledg. Entries";
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value Entries';
                        RunObject = Page "Value Entries";
                    }
                }
                group("Group10")
                {
                    Caption = 'Reports';
                    action("Customer - Order Detail1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Order Detail';
                        RunObject = Report "Customer - Order Detail";
                    }
                    action("Sales Reservation Avail.")
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Sales Reservation Avail.';
                        RunObject = Report "Sales Reservation Avail.";
                    }
                    action("Sales Statistics1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Statistics';
                        RunObject = Report "Sales Statistics";
                    }
                    action("Customer - Sales List1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Sales List';
                        RunObject = Report "Customer - Sales List";
                    }
                    action("EC Sales List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'EC Sales List';
                        RunObject = Report "EC Sales List";
                    }
                    action("Customer/Item Sales1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer/Item Sales';
                        RunObject = Report "Customer/Item Sales";
                    }
                    action("Customer - Order Summary1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Order Summary';
                        RunObject = Report "Customer - Order Summary";
                    }
                }
            }
            group("Group11")
            {
                Caption = 'Marketing';
                action("Contacts2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contacts';
                    RunObject = Page "Contact List";
                }
                action("Campaigns")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaigns';
                    RunObject = Page "Campaign List";
                }
                action("Segments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Segments';
                    RunObject = Page "Segment List";
                }
                action("Logged Segments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Logged Segments';
                    RunObject = Page "Logged Segments";
                }
                action("Opportunities1")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunities';
                    RunObject = Page "Opportunity List";
                }
                action("Tasks1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tasks';
                    RunObject = Page "Tasks";
                }
                action("Campaign - Details")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign - Details';
                    RunObject = Report "Campaign - Details";
                }
                group("Group12")
                {
                    Caption = 'Registers/Entries';
                    action("Campaign Entries")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Campaign Entries';
                        RunObject = Page "Campaign Entries";
                    }
                    action("Opportunity Entries")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Opportunity Entries';
                        RunObject = Page "Opportunity Entries";
                    }
                    action("Interaction Log Entries")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Log Entries';
                        RunObject = Page "Interaction Log Entries";
                    }
                }
            }
            group("Group13")
            {
                Caption = 'Inventory & Pricing';
                action("Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Items';
                    RunObject = Page "Item List";
                }
                action("Nonstock Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Nonstock Items';
                    RunObject = Page "Catalog Item List";
                }
                action("Item Attributes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Attributes';
                    RunObject = Page "Item Attributes";
                }
                action("Sales Price Worksheet")
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Price Worksheet';
                    RunObject = Page "Sales Price Worksheet";
                }
                action("Adjust Item Costs/Prices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjust Item Costs/Prices';
                    RunObject = Report "Adjust Item Costs/Prices";
                }
                group("Group14")
                {
                    Caption = 'Reports';
                    action("Inventory - Sales Statistics")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Inventory Sales Statistics';
                        RunObject = Report "Inventory - Sales Statistics";
                    }
                    action("Inventory Cost and Price List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Cost and Price List';
                        RunObject = Report "Inventory Cost and Price List";
                    }
                    action("Item Charges - Specification")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Charges - Specification';
                        RunObject = Report "Item Charges - Specification";
                    }
                    action("Inventory - Customer Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Customer Sales';
                        RunObject = Report "Inventory - Customer Sales";
                    }
                    action("Nonstock Item Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Nonstock Item Sales';
                        RunObject = Report "Catalog Item Sales";
                    }
                    action("Inventory Availability")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Availability';
                        RunObject = Report "Inventory Availability";
                    }
                    action("Inventory Order Details")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Order Details';
                        RunObject = Report "Inventory Order Details";
                    }
                    action("Price List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Price List';
                        RunObject = Report "Price List";
                    }
                    action("Inventory - Sales Back Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Sales Back Orders';
                        RunObject = Report "Inventory - Sales Back Orders";
                    }
                    action("Inventory - Top 10 List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Top 10 List';
                        RunObject = Report "Inventory - Top 10 List";
                    }
                    action("Item Substitutions")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Item Substitutions';
                        RunObject = Report "Item Substitutions";
                    }
                    action("Assemble to Order - Sales")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Assemble to Order - Sales';
                        RunObject = Report "Assemble to Order - Sales";
                    }
                }
            }
            group("Group15")
            {
                Caption = 'Sales - Dataverse';
                action("Sales Order List - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Orders - Dynamics 365 Sales';
                    RunObject = Page "CRM Sales Order List";
                }
                action("Quotes - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes - Dynamics 365 Sales';
                    RunObject = Page "CRM Sales Quote List";
                }
                action("Cases - Dynamics 365 for Customer Service")
                {
                    ApplicationArea = Suite;
                    Caption = 'Cases - Dynamics 365 for Customer Service';
                    RunObject = Page "CRM Case List";
                }
                action("Opportunities - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Opportunities - Dynamics 365 Sales';
                    RunObject = Page "CRM Opportunity List";
                }
                action("Accounts - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Accounts - Dynamics 365 Sales';
                    RunObject = Page "CRM Account List";
                }
                action("Transaction Currencies - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Transaction Currencies - Dynamics 365 Sales';
                    RunObject = Page "CRM TransactionCurrency List";
                }
                action("Unit Groups - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Unit Groups - Dynamics 365 Sales';
                    RunObject = Page "CRM UnitGroup List";
                }
                action("Products - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Products - Dynamics 365 Sales';
                    RunObject = Page "CRM Product List";
                }
                action("Contacts - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Contacts - Dynamics 365 Sales';
                    RunObject = Page "CRM Contact List";
                }
                action("Records Skipped For Synchronization")
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled Data Synchronization Errors';
                    RunObject = page "CRM Skipped Records";
                    AccessByPermission = tabledata 5331 = R;
                }
            }
            group("Group16")
            {
                Caption = 'Setup';
                action("Order Promising Setup")
                {
                    ApplicationArea = OrderPromising;
                    Caption = 'Order Promising Setup';
                    RunObject = Page "Order Promising Setup";
                }
                action("Sales & Receivables Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales & Receivables Setup';
                    RunObject = Page "Sales & Receivables Setup";
                }
                action("Report Selection Sales")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report Selections Sales';
                    RunObject = page "Report Selection - Sales";
                }
                action("Standard Sales Codes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Standard Sales Codes';
                    RunObject = Page "Standard Sales Codes";
                }
                action("Payment Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Terms';
                    RunObject = Page "Payment Terms";
                }
                action("Payment Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Methods';
                    RunObject = Page "Payment Methods";
                }
                action("Item Disc. Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Discount Groups';
                    RunObject = Page "Item Disc. Groups";
                }
                action("Shipment Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Shipment Methods';
                    RunObject = Page "Shipment Methods";
                }
                action("Shipping Agents")
                {
                    ApplicationArea = Suite;
                    Caption = 'Shipping Agents';
                    RunObject = Page "Shipping Agents";
                }
                action("Return Reasons")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Reasons';
                    RunObject = Page "Return Reasons";
                }
                action("Contact Conversion Templates")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact Conversion Templates';
                    RunObject = Page "Customer Template List";
                }
                group("Group17")
                {
                    Caption = 'Sales Analysis';
                    action("Analysis Types")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Analysis Types';
                        RunObject = Page "Analysis Types";
                    }
                    action("Sales Analysis by Dimensions1")
                    {
                        ApplicationArea = Dimensions, SalesAnalysis;
                        Caption = 'Sales Analysis by Dimensions';
                        RunObject = Page "Analysis View List Sales";
                    }
                    action("Analysis Column Templates")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Sales Analysis Column Templates';
                        RunObject = Report "Run Sales Analysis Col. Temp.";
                    }
                    action("Analysis Line Templates")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Sales Analysis Line Templates';
                        RunObject = Report "Run Sales Analysis Line Templ.";
                    }
                }
                group("Group18")
                {
                    Caption = 'Customer';
                    action("Customer Price Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Price Groups';
                        RunObject = Page "Customer Price Groups";
                    }
                    action("Customer Disc. Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Discount Groups';
                        RunObject = page "Customer Disc. Groups";
                    }
                }
                group("Group19")
                {
                    Caption = 'Item';
                    action("Nonstock Item Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Nonstock Item Setup';
                        RunObject = Page "Catalog Item Setup";
                    }
                    action("Item Charges")
                    {
                        ApplicationArea = ItemCharges;
                        Caption = 'Item Charges';
                        RunObject = Page "Item Charges";
                    }
                    action("Item Disc. Groups1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Discount Groups';
                        RunObject = Page "Item Disc. Groups";
                    }
                    action("Inventory Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Setup';
                        RunObject = page "Inventory Setup";
                    }
                }
                group("Group20")
                {
                    Caption = 'Marketing';
                    action("Marketing Setup")
                    {
                        ApplicationArea = Basic, Suite, RelationshipMgmt;
                        Caption = 'Marketing Setup';
                        RunObject = Page "Marketing Setup";
                    }
                    action("Interaction Template Setup")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Template Setup';
                        RunObject = Page "Interaction Template Setup";
                    }
                    action("Business Relations")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Business Relations';
                        RunObject = Page "Business Relations";
                    }
                    action("Industry Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Industry Groups';
                        RunObject = Page "Industry Groups";
                    }
                    action("Web Sources")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Web Sources';
                        RunObject = Page "Web Sources";
                    }
                    action("Job Responsibilities")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Job Responsibilities';
                        RunObject = Page "Job Responsibilities";
                    }
                    action("Organizational Levels")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Organizational Levels';
                        RunObject = Page "Organizational Levels";
                    }
                    action("Interaction Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Groups';
                        RunObject = Page "Interaction Groups";
                    }
                    action("Interaction Templates")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Templates';
                        RunObject = Page "Interaction Templates";
                    }
                    action("Salutations")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Salutations';
                        RunObject = Page "Salutations";
                    }
                    action("Mailing Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Mailing Groups';
                        RunObject = Page "Mailing Groups";
                    }
                    action("Status")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Campaign Status';
                        RunObject = Page "Campaign Status";
                    }
                    action("Sales Cycles")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Sales Cycles';
                        RunObject = Page "Sales Cycles";
                    }
                    action("Close Opportunity Codes")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Close Opportunity Codes';
                        RunObject = Page "Close Opportunity Codes";
                    }
                    action("Questionnaire Setup")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Questionnaire Setup';
                        RunObject = Page "Profile Questionnaires";
                    }
                    action("Activities")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Activities';
                        RunObject = Page "Activity List";
                    }
                }
            }
        }
    }
}