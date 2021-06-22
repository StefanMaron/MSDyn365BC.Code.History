page 9321 "Service Contracts"
{
    ApplicationArea = Service;
    Caption = 'Service Contracts';
    CardPageID = "Service Contract";
    Editable = false;
    PageType = List;
    SourceTable = "Service Contract Header";
    SourceTableView = WHERE("Contract Type" = CONST(Contract));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract or service contract quote.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the status of the service contract or contract quote.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service contract.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns the service items in the service contract/contract quote.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer in the service contract.';
                    Visible = false;
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field("Ship-to Name"; "Ship-to Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the service contract.';
                }
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service contract expires.';
                }
                field("Change Status"; "Change Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if a service contract or contract quote is locked or open for changes.';
                    Visible = false;
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the currency used to calculate the amounts in the documents related to this contract.';
                    Visible = false;
                }
                field("First Service Date"; "First Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the first expected service for the service items in the contract.';
                    Visible = false;
                }
                field("Service Order Type"; "Service Order Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order type assigned to service orders linked to this contract.';
                    Visible = false;
                }
                field("Invoice Period"; "Invoice Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the invoice period for the service contract.';
                    Visible = false;
                }
                field("Next Price Update Date"; "Next Price Update Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the next date you want contract prices to be updated.';
                    Visible = false;
                }
                field("Last Price Update Date"; "Last Price Update Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date you last updated the contract prices.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Bill-to Customer No."),
                              "Date Filter" = FIELD("Date Filter");
                Visible = true;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Customer No."),
                              "Date Filter" = FIELD("Date Filter");
                Visible = true;
            }
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
            group("&Contract")
            {
                Caption = '&Contract';
                Image = Agreement;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                        CurrPage.SaveRecord;
                    end;
                }
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Service Contract No." = FIELD("Contract No.");
                    RunPageView = SORTING("Service Contract No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
                action("&Warranty Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Warranty Ledger Entries';
                    Image = WarrantyLedger;
                    RunObject = Page "Warranty Ledger Entries";
                    RunPageLink = "Service Contract No." = FIELD("Contract No.");
                    RunPageView = SORTING("Service Contract No.", "Posting Date", "Document No.");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
                }
                action("Service Dis&counts")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Dis&counts';
                    Image = Discount;
                    RunObject = Page "Contract/Service Discounts";
                    RunPageLink = "Contract Type" = FIELD("Contract Type"),
                                  "Contract No." = FIELD("Contract No.");
                    ToolTip = 'View or edit the discounts that you grant for the contract on spare parts in particular service item groups, the discounts on resource hours for resources in particular resource groups, and the discounts on particular service costs.';
                }
                action("Service &Hours")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Hours';
                    Image = ServiceHours;
                    RunObject = Page "Service Hours";
                    RunPageLink = "Service Contract No." = FIELD("Contract No."),
                                  "Service Contract Type" = FILTER(Contract);
                    ToolTip = 'View the service hours that are valid for the service contract. This window displays the starting and ending service hours for the contract for each weekday.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Service Contract"),
                                  "Table Subtype" = FIELD("Contract Type"),
                                  "No." = FIELD("Contract No."),
                                  "Table Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
                group(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action(Action1102601013)
                    {
                        ApplicationArea = Service;
                        Caption = 'Statistics';
                        Image = Statistics;
                        Promoted = true;
                        PromotedCategory = Process;
                        RunObject = Page "Contract Statistics";
                        RunPageLink = "Contract Type" = CONST(Contract),
                                      "Contract No." = FIELD("Contract No.");
                        ShortCutKey = 'F7';
                        ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    }
                    action("Tr&endscape")
                    {
                        ApplicationArea = Service;
                        Caption = 'Tr&endscape';
                        Image = Trendscape;
                        RunObject = Page "Contract Trendscape";
                        RunPageLink = "Contract Type" = CONST(Contract),
                                      "Contract No." = FIELD("Contract No.");
                        ToolTip = 'View a detailed account of service item transactions by time intervals.';
                    }
                }
                action("Filed Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Filed Contracts';
                    Image = Agreement;
                    RunObject = Page "Filed Service Contract List";
                    RunPageLink = "Contract Type Relation" = FIELD("Contract Type"),
                                  "Contract No. Relation" = FIELD("Contract No.");
                    RunPageView = SORTING("Contract Type Relation", "Contract No. Relation", "File Date", "File Time")
                                  ORDER(Descending);
                    ToolTip = 'View service contracts that are filed.';
                }
                group("Ser&vice Overview")
                {
                    Caption = 'Ser&vice Overview';
                    Image = Tools;
                    action("Service Orders")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Orders';
                        Image = Document;
                        RunObject = Page "Service List";
                        RunPageLink = "Document Type" = CONST(Order),
                                      "Contract No." = FIELD("Contract No.");
                        RunPageView = SORTING("Contract No.");
                        ToolTip = 'Open the list of ongoing service orders.';
                    }
                    action("Posted Service Invoices")
                    {
                        ApplicationArea = Service;
                        Caption = 'Posted Service Invoices';
                        Image = PostedServiceOrder;
                        RunObject = Page "Service Document Registers";
                        RunPageLink = "Source Document No." = FIELD("Contract No.");
                        RunPageView = SORTING("Source Document Type", "Source Document No.", "Destination Document Type", "Destination Document No.")
                                      WHERE("Source Document Type" = CONST(Contract),
                                            "Destination Document Type" = CONST("Posted Invoice"));
                        ToolTip = 'Open the list of posted service invoices.';
                    }
                }
                action("C&hange Log")
                {
                    ApplicationArea = Service;
                    Caption = 'C&hange Log';
                    Image = ChangeLog;
                    RunObject = Page "Contract Change Log";
                    RunPageLink = "Contract No." = FIELD("Contract No.");
                    RunPageView = SORTING("Contract No.")
                                  ORDER(Descending);
                    ToolTip = 'View all changes that have been made to the service contract.';
                }
                action("&Gain/Loss Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Gain/Loss Entries';
                    Image = GainLossEntries;
                    RunObject = Page "Contract Gain/Loss Entries";
                    RunPageLink = "Contract No." = FIELD("Contract No.");
                    RunPageView = SORTING("Contract No.", "Change Date")
                                  ORDER(Descending);
                    ToolTip = 'View the contract number, reason code, contract group code, responsibility center, customer number, ship-to code, customer name, and type of change, as well as the contract gain and loss. You can print all your service contract gain/loss entries.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Si&gn Contract")
                {
                    ApplicationArea = Service;
                    Caption = 'Si&gn Contract';
                    Image = Signature;
                    ToolTip = 'Confirm the contract.';

                    trigger OnAction()
                    var
                        SignServContractDoc: Codeunit SignServContractDoc;
                    begin
                        CurrPage.Update;
                        SignServContractDoc.SignContract(Rec);
                        CurrPage.Update;
                    end;
                }
                action("&Lock Contract")
                {
                    ApplicationArea = Service;
                    Caption = '&Lock Contract';
                    Image = Lock;
                    ToolTip = 'Make sure that the changes will be part of the contract.';

                    trigger OnAction()
                    var
                        LockOpenServContract: Codeunit "Lock-OpenServContract";
                    begin
                        CurrPage.Update;
                        LockOpenServContract.LockServContract(Rec);
                        CurrPage.Update;
                    end;
                }
                action("&Open Contract")
                {
                    ApplicationArea = Service;
                    Caption = '&Open Contract';
                    Image = ReOpen;
                    ToolTip = 'Open the service contract.';

                    trigger OnAction()
                    var
                        LockOpenServContract: Codeunit "Lock-OpenServContract";
                    begin
                        CurrPage.Update;
                        LockOpenServContract.OpenServContract(Rec);
                        CurrPage.Update;
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Service;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintServiceContract(Rec);
                end;
            }
        }
        area(reporting)
        {
            action("Contract, Service Order Test")
            {
                ApplicationArea = Service;
                Caption = 'Contract, Service Order Test';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Contr. Serv. Orders - Test";
                ToolTip = 'View the numbers of contracts, the numbers and the names of customers, as well as some other information relating to the service orders that are created for the period that you have specified. You can test which service contracts include service items that are due for service within the specified period.';
            }
            action("Maintenance Visit - Planning")
            {
                ApplicationArea = Service;
                Caption = 'Maintenance Visit - Planning';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Maintenance Visit - Planning";
                ToolTip = 'View the service zone code, group code, contract number, customer number, service period, as well as the service date. You can select the schedule for one or more responsibility centers. The report shows the service dates of all the maintenance visits for the chosen responsibility centers. You can print all your schedules for maintenance visits.';
            }
            action("Service Contract Details")
            {
                ApplicationArea = Service;
                Caption = 'Service Contract Details';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Service Contract-Detail";
                ToolTip = 'View detailed information for the service contract.';
            }
            action("Service Contract Profit")
            {
                ApplicationArea = Service;
                Caption = 'Service Contract Profit';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Service Profit (Contracts)";
                ToolTip = 'View profit information for the service contract.';
            }
            action("Contract Invoice Test")
            {
                ApplicationArea = Service;
                Caption = 'Contract Invoice Test';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Contract Invoicing";
                ToolTip = 'Specifies billable profits for the job task that are related to items.';
            }
            action("Service Contract-Customer")
            {
                ApplicationArea = Service;
                Caption = 'Service Contract-Customer';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Service Contract - Customer";
                ToolTip = 'View information about status, next invoice date, invoice period, amount per period, and annual amount. You can print a list of service contracts for each customer in a selected time period.';
            }
            action("Service Contract-Salesperson")
            {
                ApplicationArea = Service;
                Caption = 'Service Contract-Salesperson';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Serv. Contract - Salesperson";
                ToolTip = 'View customer number, name, description, starting date and the annual amount for each service contract. You can use the report to calculate and document sales commission. You can print a list of service contracts for each salesperson for a selected period.';
            }
            action("Contract Price Update - Test")
            {
                ApplicationArea = Service;
                Caption = 'Contract Price Update - Test';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Contract Price Update - Test";
                ToolTip = 'View the contracts numbers, customer numbers, contract amounts, price update percentages, and any errors that occur. You can test which service contracts need price updates up to the date that you have specified.';
            }
            action("Service Items Out of Warranty")
            {
                ApplicationArea = Service;
                Caption = 'Service Items Out of Warranty';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Service Items Out of Warranty";
                ToolTip = 'View information about warranty end dates, serial numbers, number of active contracts, items description, and names of customers. You can print a list of service items that are out of warranty.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetSecurityFilterOnRespCenter;
    end;
}

