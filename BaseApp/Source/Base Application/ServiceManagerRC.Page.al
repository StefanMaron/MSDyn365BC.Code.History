page 8908 "Service Manager Role Center"
{
    Caption = 'Service Manager Role Center';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Contracts';
                action("Service Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Items';
                    RunObject = Page "Service Item List";
                }
                action("Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Items';
                    RunObject = Page "Item List";
                }
                action("Contacts")
                {
                    ApplicationArea = Service;
                    Caption = 'Contacts';
                    RunObject = Page "Contact List";
                }
                action("Customers")
                {
                    ApplicationArea = Service;
                    Caption = 'Customers';
                    RunObject = Page "Customer List";
                }
                action("Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contracts';
                    RunObject = Page "Service Contracts";
                }
                action("Contract Quotes")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contract Quotes';
                    RunObject = Page "Service Contract Quotes";
                }
                action("Invoices")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Invoices';
                    RunObject = Page "Service Invoices";
                }
                action("Credit Memos")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Credit Memos';
                    RunObject = Page "Service Credit Memos";
                }
                action("Create Contract Orders")
                {
                    ApplicationArea = Service;
                    Caption = 'Create Contract Service Orders';
                    RunObject = Report "Create Contract Service Orders";
                }
                action("Create Contract Invoices")
                {
                    ApplicationArea = Service;
                    Caption = 'Create Service Contract Invoices';
                    RunObject = Report "Create Contract Invoices";
                }
                group("Group1")
                {
                    Caption = 'Contract Gain/Loss by';
                    action("Contract & Group")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Gain/Loss (Groups)';
                        RunObject = Page "Contract Gain/Loss (Groups)";
                    }
                    action("Contracts1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Gain/Loss (Contracts)';
                        RunObject = Page "Contract Gain/Loss (Contracts)";
                    }
                    action("Customers1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Gain/Loss (Customers)';
                        RunObject = Page "Contract Gain/Loss (Customers)";
                    }
                    action("Reason Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Gain/Loss (Reasons)';
                        RunObject = Page "Contract Gain/Loss (Reasons)";
                    }
                    action("Responsibility Center")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contract Gain/Loss (Resp.Ctr)';
                        RunObject = Page "Contract Gain/Loss (Resp.Ctr)";
                    }
                }
                group("Group2")
                {
                    Caption = 'Reports';
                    action("Contract - Salesperson")
                    {
                        ApplicationArea = Service;
                        Caption = 'Serv. Contract - Salesperson';
                        RunObject = Report "Serv. Contract - Salesperson";
                    }
                    action("Contr. GainLoss - Resp. Ctr.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contr. Gain/Loss - Resp. Ctr.';
                        RunObject = Report "Contr. Gain/Loss - Resp. Ctr.";
                    }
                    action("Contract - Customer")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Contract - Customer';
                        RunObject = Report "Service Contract - Customer";
                    }
                    action("Maintenance Visit - Planning")
                    {
                        ApplicationArea = Service;
                        Caption = 'Maintenance Visit - Planning';
                        RunObject = Report "Maintenance Visit - Planning";
                    }
                    action("Maintenance Performance")
                    {
                        ApplicationArea = Service;
                        Caption = 'Maintenance Performance';
                        RunObject = Report "Maintenance Performance";
                    }
                    action("Contract GainLoss Entries")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Gain/Loss Entries';
                        RunObject = Report "Contract Gain/Loss Entries";
                    }
                    action("Contract Quotes to Be Signed")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contract Quotes to Be Signed';
                        RunObject = Report "Contract Quotes to Be Signed";
                    }
                    action("Profit (Contracts)")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Profit (Contracts)';
                        RunObject = Report "Service Profit (Contracts)";
                    }
                    action("Service Items1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Items';
                        RunObject = Report "Service Items";
                    }
                    action("Service Items Out of Warranty")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Items Out of Warranty';
                        RunObject = Report "Service Items Out of Warranty";
                    }
                    action("Service Item Line Labels")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item Line Labels';
                        RunObject = Report "Service Item Line Labels";
                    }
                }
            }
            group("Group3")
            {
                Caption = 'Planning & Dispatching';
                action("Service Tasks")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Tasks';
                    RunObject = Page "Service Tasks";
                }
                action("Dispatch Board")
                {
                    ApplicationArea = Service;
                    Caption = 'Dispatch Board';
                    RunObject = Page "Dispatch Board";
                }
                action("Demand Overview")
                {
                    ApplicationArea = Service;
                    Caption = 'Demand Overview';
                    RunObject = Page "Demand Overview";
                    AccessByPermission = TableData 5900 = R;
                }
                group("Group4")
                {
                    Caption = 'Reports';
                    action("Service Tasks1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Tasks';
                        RunObject = Report "Service Tasks";
                    }
                    action("Dispatch Board1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Dispatch Board';
                        RunObject = Report "Dispatch Board";
                    }
                    action("Load Level")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Load Level';
                        RunObject = Report "Service Load Level";
                    }
                }
            }
            group("Group5")
            {
                Caption = 'Order Processing';
                action("Service Items2")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Items';
                    RunObject = Page "Service Item List";
                }
                action("Items1")
                {
                    ApplicationArea = Service;
                    Caption = 'Items';
                    RunObject = Page "Item List";
                }
                action("Nonstock Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Nonstock Items';
                    RunObject = Page "Catalog Item List";
                }
                action("Contacts1")
                {
                    ApplicationArea = Service;
                    Caption = 'Contacts';
                    RunObject = Page "Contact List";
                }
                action("Customers2")
                {
                    ApplicationArea = Service;
                    Caption = 'Customers';
                    RunObject = Page "Customer List";
                }
                action("Loaners")
                {
                    ApplicationArea = Service;
                    Caption = 'Loaners';
                    RunObject = Page "Loaner List";
                }
                action("Quotes")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Quotes';
                    RunObject = Page "Service Quotes";
                }
                action("Orders")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Orders';
                    RunObject = Page "Service Orders";
                }
                action("Invoices1")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Invoices';
                    RunObject = Page "Service Invoices";
                }
                action("Credit Memos1")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Credit Memos';
                    RunObject = Page "Service Credit Memos";
                }
                action("Certificates of Supply")
                {
                    ApplicationArea = Service;
                    Caption = 'Certificates of Supply';
                    RunObject = Page "Certificates of Supply";
                }
                // action("Create Elec. Service Invoices")
                // {
                //     Caption = 'Create Elec. Service Invoices';
                //     RunObject = Report 13604;
                // }
                // action("Create Elec. Service Cr. Memos")
                // {
                //     Caption = 'Create Elec. Service Cr. Memos';
                //     RunObject = Report 13605;
                // }
                action("Cases - Dynamics 365 for Customer Service")
                {
                    ApplicationArea = Service;
                    Caption = 'Cases - Dynamics 365 for Customer Service';
                    RunObject = Page "CRM Case List";
                }
                group("Group6")
                {
                    Caption = 'Posted Documents';
                    action("Posted Credit Memos")
                    {
                        ApplicationArea = Service;
                        Caption = 'Posted Service Credit Memos';
                        RunObject = Page "Posted Service Credit Memos";
                    }
                    action("Posted Invoices")
                    {
                        ApplicationArea = Service;
                        Caption = 'Posted Service Invoices';
                        RunObject = Page "Posted Service Invoices";
                    }
                    action("Posted Orders")
                    {
                        ApplicationArea = Service;
                        Caption = 'Posted Service Shipments';
                        RunObject = Page "Posted Service Shipments";
                    }
                }
                group("Group7")
                {
                    Caption = 'Register/Entries';
                    action("Service Registers")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Registers';
                        RunObject = Page "Service Register";
                    }
                    action("Service Ledger Entries")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Ledger Entries';
                        RunObject = Page "Service Ledger Entries";
                    }
                    action("Warranty Ledger Entries")
                    {
                        ApplicationArea = Service;
                        Caption = 'Warranty Ledger Entries';
                        RunObject = Page "Warranty Ledger Entries";
                    }
                    action("Loaner Entries")
                    {
                        ApplicationArea = Service;
                        Caption = 'Loaner Entries';
                        RunObject = Page "Loaner Entries";
                    }
                }
                group("Group8")
                {
                    Caption = 'Logs';
                    action("Orders1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Document Log';
                        RunObject = Page "Service Document Log";
                    }
                    action("Service Items3")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item Log';
                        RunObject = Page "Service Item Log";
                    }
                    action("View Email Queue")
                    {
                        ApplicationArea = Service;
                        Caption = 'View Email Queue';
                        RunObject = Page "Service Email Queue";
                    }
                }
                group("Group9")
                {
                    Caption = 'Reports';
                    action("Profit (Orders)")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Profit (Serv. Orders)';
                        RunObject = Report "Service Profit (Serv. Orders)";
                    }
                    action("Profit (Resp. Centers)")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Profit (Resp. Centers)';
                        RunObject = Report "Service Profit (Resp. Centers)";
                    }
                    action("Order - Response Time")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Order - Response Time';
                        RunObject = Report "Service Order - Response Time";
                    }
                    action("Pricing Profitability")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Pricing Profitability';
                        RunObject = Report "Serv. Pricing Profitability";
                    }
                    action("Service Items Out of Warranty1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Items Out of Warranty';
                        RunObject = Report "Service Items Out of Warranty";
                    }
                    action("Service Item Line Labels1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item Line Labels';
                        RunObject = Report "Service Item Line Labels";
                    }
                    action("Profit (Service Items)")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Profit (Service Items)';
                        RunObject = Report "Service Profit (Service Items)";
                    }
                    action("Service Item - Resource Usage")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item - Resource Usage';
                        RunObject = Report "Service Item - Resource Usage";
                    }
                    action("Service Item Worksheet")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item Worksheet';
                        RunObject = Report "Service Item Worksheet";
                    }
                }
            }
            group("Group10")
            {
                Caption = 'Setup';
                action("Service Setup")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Setup';
                    RunObject = Page "Service Mgt. Setup";
                }
                action("Skill Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'Skill Codes';
                    RunObject = Page "Skill Codes";
                }
                action("Fault Reason Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'Fault Reason Codes';
                    RunObject = Page "Fault Reason Codes";
                }
                action("Service Costs")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Costs';
                    RunObject = Page "Service Costs";
                }
                action("Service Zones")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Zones';
                    RunObject = Page "Service Zones";
                }
                action("Service Order Types")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Order Types';
                    RunObject = Page "Service Order Types";
                }
                action("Service Item Groups")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item Groups';
                    RunObject = Page "Service Item Groups";
                }
                action("Shelves")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Shelves';
                    RunObject = Page "Service Shelves";
                }
                action("Standard Service Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'Standard Service Codes';
                    RunObject = Page "Standard Service Codes";
                }
                action("Report Selections")
                {
                    ApplicationArea = Service;
                    Caption = 'Report Selection - Service';
                    RunObject = Page "Report Selection - Service";
                }
                group("Group11")
                {
                    Caption = 'Service Operations';
                    action("Default Service Hours")
                    {
                        ApplicationArea = Service;
                        Caption = 'Default Service Hours';
                        RunObject = Page "Default Service Hours";
                    }
                    action("Work-Hour Templates")
                    {
                        ApplicationArea = Jobs, Service;
                        Caption = 'Work-Hour Templates';
                        RunObject = Page "Work-Hour Templates";
                    }
                    action("Resource Service Zones")
                    {
                        ApplicationArea = Service;
                        Caption = 'Resource Service Zones';
                        RunObject = Page "Resource Service Zones";
                    }
                    action("Troubleshooting")
                    {
                        ApplicationArea = Service;
                        Caption = 'Troubleshooting';
                        RunObject = Page "Troubleshooting List";
                    }
                }
                group("Group12")
                {
                    Caption = 'Status';
                    action("Order Status Setup")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Order Status Setup';
                        RunObject = Page "Service Order Status Setup";
                    }
                    action("Repair Status Setup")
                    {
                        ApplicationArea = Service;
                        Caption = 'Repair Status Setup';
                        RunObject = Page "Repair Status Setup";
                    }
                }
                group("Group13")
                {
                    Caption = 'Pricing';
                    action("Price Adjustment Groups")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Price Adjustment Groups';
                        RunObject = Page "Serv. Price Adjmt. Group";
                    }
                    action("Price Groups")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Price Groups';
                        RunObject = Page "Service Price Groups";
                    }
                }
                group("Group14")
                {
                    Caption = 'Fault Reporting';
                    action("Resolution Codes")
                    {
                        ApplicationArea = Service;
                        Caption = 'Resolution Codes';
                        RunObject = Page "Resolution Codes";
                    }
                    action("Fault Areas")
                    {
                        ApplicationArea = Service;
                        Caption = 'Fault Areas';
                        RunObject = Page "Fault Areas";
                    }
                    action("Symptom Codes")
                    {
                        ApplicationArea = Service;
                        Caption = 'Symptom Codes';
                        RunObject = Page "Symptom Codes";
                    }
                    action("Fault Codes")
                    {
                        ApplicationArea = Service;
                        Caption = 'Fault Codes';
                        RunObject = Page "Fault Codes";
                    }
                    action("Fault/Resol. Codes Relationshi")
                    {
                        ApplicationArea = Service;
                        Caption = 'Fault/Resol. Codes Relationships';
                        RunObject = Page "Fault/Resol. Cod. Relationship";
                    }
                    action("Imp. IRIS to Area/Symptom Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Imp. IRIS to Area/Symptom Code';
                        RunObject = XMLport 5900;
                    }
                    action("Import IRIS to Fault Codes")
                    {
                        ApplicationArea = Service;
                        Caption = 'Import IRIS to Fault Codes';
                        RunObject = XMLport 5901;
                    }
                    action("Import IRIS to Resol. Codes")
                    {
                        ApplicationArea = Service;
                        Caption = 'Import IRIS to Resol. Codes';
                        RunObject = XMLport 5902;
                    }
                }
                group("Group15")
                {
                    Caption = 'Contracts';
                    action("Account Groups")
                    {
                        ApplicationArea = Service;
                        Caption = 'Serv. Contract Account Groups';
                        RunObject = Page "Serv. Contract Account Groups";
                    }
                    action("Templates")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Contract Templates';
                        RunObject = Page "Service Contract Template List";
                    }
                    action("Groups")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Contract Groups';
                        RunObject = Page "Service Contract Groups";
                    }
                    action("Service Item Groups1")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item Groups';
                        RunObject = Page "Service Item Groups";
                    }
                }
            }
        }
    }
}