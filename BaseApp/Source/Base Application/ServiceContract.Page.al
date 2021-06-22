page 6050 "Service Contract"
{
    Caption = 'Service Contract';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Print/Send,Contract';
    RefreshOnActivate = true;
    SourceTable = "Service Contract Header";
    SourceTableView = WHERE("Contract Type" = FILTER(Contract));

    layout
    {
        area(content)
        {
            group(Control1)
            {
                Caption = 'General';
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the service contract or service contract quote.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service contract.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer who owns the service items in the service contract/contract quote.';

                    trigger OnValidate()
                    begin
                        CustomerNoOnAfterValidate;
                    end;
                }
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contact who will receive the service delivery.';
                }
                group(Control13)
                {
                    ShowCaption = false;
                    field(Name; Name)
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the customer in the service contract.';
                    }
                    field(Address; Address)
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the customer''s address.';
                    }
                    field("Address 2"; "Address 2")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field(City; City)
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the name of the city in where the customer is located.';
                    }
                    group(Control24)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field(County; County)
                        {
                            ApplicationArea = Service;
                            QuickEntry = false;
                        }
                    }
                    field("Post Code"; "Post Code")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Country/Region Code"; "Country/Region Code")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the country/region of the address.';

                        trigger OnValidate()
                        begin
                            IsSellToCountyVisible := FormatAddress.UseCounty("Country/Region Code");
                        end;
                    }
                    field("Contact Name"; "Contact Name")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the person you regularly contact when you do business with the customer in this service contract.';
                    }
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the customer phone number.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Service;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the customer''s email address.';
                }
                field("Contract Group Code"; "Contract Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the contract group code assigned to the service contract.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the salesperson assigned to this service contract.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the starting date of the service contract.';

                    trigger OnValidate()
                    begin
                        StartingDateOnAfterValidate;
                    end;
                }
                field(Status; Status)
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the service contract or contract quote.';

                    trigger OnValidate()
                    begin
                        ActivateFields;
                        StatusOnAfterValidate;
                    end;
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Change Status"; "Change Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if a service contract or contract quote is locked or open for changes.';
                }
            }
            part(ServContractLines; "Service Contract Subform")
            {
                ApplicationArea = Service;
                SubPageLink = "Contract No." = FIELD("Contract No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';

                    trigger OnValidate()
                    begin
                        BilltoCustomerNoOnAfterValidat;
                    end;
                }
                field("Bill-to Contact No."; "Bill-to Contact No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
                }
                group(Control27)
                {
                    ShowCaption = false;
                    field("Bill-to Name"; "Bill-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    }
                    field("Bill-to Address"; "Bill-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the address of the customer to whom you sent the invoice.';
                    }
                    field("Bill-to Address 2"; "Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies an additional line of the address.';
                    }
                    field("Bill-to City"; "Bill-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control33)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; "Bill-to County")
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                            QuickEntry = false;
                        }
                    }
                    field("Bill-to Post Code"; "Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    }
                    field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        QuickEntry = false;

                        trigger OnValidate()
                        begin
                            IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
                        end;
                    }
                    field("Bill-to Contact"; "Bill-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                    }
                }
                field("Your Reference"; "Your Reference")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the customer''s reference number.';
                }
                field("Serv. Contract Acc. Gr. Code"; "Serv. Contract Acc. Gr. Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code associated with the service contract account group.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("Direct Debit Mandate ID"; "Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the direct-debit mandate that the customer has signed to allow direct-debit collection of payments.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency used to calculate the amounts in the documents related to this contract.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';

                    trigger OnValidate()
                    begin
                        ShiptoCodeOnAfterValidate;
                    end;
                }
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Ship-to Name"; "Ship-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    }
                    field("Ship-to Address"; "Ship-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; "Ship-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    field("Ship-to City"; "Ship-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address that the items are shipped to.';
                    }
                    group(Control38)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; "Ship-to County")
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                            QuickEntry = false;
                        }
                    }
                    field("Ship-to Post Code"; "Ship-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        DrillDown = false;
                        Importance = Promoted;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        QuickEntry = false;
                    }
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field("Service Zone Code"; "Service Zone Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the service zone of the customer ship-to address.';
                }
                field("Service Period"; "Service Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a default service period for the items in the contract.';

                    trigger OnValidate()
                    begin
                        ServicePeriodOnAfterValidate;
                    end;
                }
                field("First Service Date"; "First Service Date")
                {
                    ApplicationArea = Service;
                    Editable = FirstServiceDateEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date of the first expected service for the service items in the contract.';

                    trigger OnValidate()
                    begin
                        FirstServiceDateOnAfterValidat;
                    end;
                }
                field("Response Time (Hours)"; "Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the response time for the service contract.';

                    trigger OnValidate()
                    begin
                        ResponseTimeHoursOnAfterValida;
                    end;
                }
                field("Service Order Type"; "Service Order Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order type assigned to service orders linked to this contract.';
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Annual Amount"; "Annual Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount that will be invoiced annually for the service contract or contract quote.';

                    trigger OnValidate()
                    begin
                        AnnualAmountOnAfterValidate;
                    end;
                }
                field("Allow Unbalanced Amounts"; "Allow Unbalanced Amounts")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if the contents of the Calcd. Annual Amount field are copied into the Annual Amount field in the service contract or contract quote.';

                    trigger OnValidate()
                    begin
                        AllowUnbalancedAmountsOnAfterV;
                    end;
                }
                field("Calcd. Annual Amount"; "Calcd. Annual Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the sum of the Line Amount field values on all contract lines associated with the service contract or contract quote.';
                }
                field(InvoicePeriod; "Invoice Period")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the invoice period for the service contract.';
                }
                field(NextInvoiceDate; "Next Invoice Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date of the next invoice for this service contract.';
                }
                field(AmountPerPeriod; "Amount per Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount that will be invoiced for each invoice period for the service contract.';
                }
                field(NextInvoicePeriod; NextInvoicePeriod)
                {
                    ApplicationArea = Service;
                    Caption = 'Next Invoice Period';
                    ToolTip = 'Specifies the ending date of the next invoice period for the service contract.';
                }
                field("Last Invoice Date"; "Last Invoice Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when this service contract was last invoiced.';
                }
                field(Prepaid; Prepaid)
                {
                    ApplicationArea = Service;
                    Enabled = PrepaidEnable;
                    ToolTip = 'Specifies that this service contract is prepaid.';

                    trigger OnValidate()
                    begin
                        PrepaidOnAfterValidate;
                    end;
                }
                field("Automatic Credit Memos"; "Automatic Credit Memos")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that a credit memo is created when you remove a contract line.';
                }
                field("Invoice after Service"; "Invoice after Service")
                {
                    ApplicationArea = Service;
                    Enabled = InvoiceAfterServiceEnable;
                    ToolTip = 'Specifies that you can only invoice the contract if you have posted a service order since last time you invoiced the contract.';

                    trigger OnValidate()
                    begin
                        InvoiceafterServiceOnAfterVali;
                    end;
                }
                field("Combine Invoices"; "Combine Invoices")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies you want to combine invoices for this service contract with invoices for other service contracts with the same bill-to customer.';
                }
                field("Contract Lines on Invoice"; "Contract Lines on Invoice")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you want the lines for this contract to appear as text on the invoice.';
                }
                field("No. of Unposted Invoices"; "No. of Unposted Invoices")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of unposted service invoices linked to the service contract.';
                }
                field("No. of Unposted Credit Memos"; "No. of Unposted Credit Memos")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of unposted credit memos linked to the service contract.';
                }
                field("No. of Posted Invoices"; "No. of Posted Invoices")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of posted service invoices linked to the service contract.';
                }
                field("No. of Posted Credit Memos"; "No. of Posted Credit Memos")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of posted credit memos linked to this service contract.';
                }
            }
            group("Price Update")
            {
                Caption = 'Price Update';
                field("Price Update Period"; "Price Update Period")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the price update period for this service contract.';
                }
                field("Next Price Update Date"; "Next Price Update Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the next date you want contract prices to be updated.';
                }
                field("Last Price Update %"; "Last Price Update %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the price update percentage you used the last time you updated the contract prices.';
                }
                field("Last Price Update Date"; "Last Price Update Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date you last updated the contract prices.';
                }
                field("Print Increase Text"; "Print Increase Text")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the standard text code printed on service invoices, informing the customer which prices have been updated since the last invoice.';
                }
                field("Price Inv. Increase Code"; "Price Inv. Increase Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the standard text code printed on service invoices, informing the customer which prices have been updated since the last invoice.';
                }
            }
            group(Details)
            {
                Caption = 'Details';
                field("Expiration Date"; "Expiration Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service contract expires.';

                    trigger OnValidate()
                    begin
                        ExpirationDateOnAfterValidate;
                    end;
                }
                field("Cancel Reason Code"; "Cancel Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a reason code for canceling the service contract.';
                }
                field("Max. Labor Unit Price"; "Max. Labor Unit Price")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the maximum unit price that can be set for a resource on all service orders and lines for the service contract.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Bill-to Customer No.");
                Visible = true;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("Customer No.");
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
            group(Overview)
            {
                Caption = 'Overview';
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
                    action("Posted Service Shipments")
                    {
                        ApplicationArea = Service;
                        Caption = 'Posted Service Shipments';
                        Image = PostedShipment;
                        ToolTip = 'Open the list of posted service shipments.';

                        trigger OnAction()
                        var
                            TempServShptHeader: Record "Service Shipment Header" temporary;
                        begin
                            CollectShpmntsByLineContractNo(TempServShptHeader);
                            PAGE.RunModal(PAGE::"Posted Service Shipments", TempServShptHeader);
                        end;
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
            }
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
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                        CurrPage.SaveRecord;
                    end;
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
                group(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action(Action178)
                    {
                        ApplicationArea = Service;
                        Caption = 'Statistics';
                        Image = Statistics;
                        Promoted = true;
                        PromotedCategory = Category5;
                        PromotedIsBig = true;
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
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = CONST("Service Contract"),
                                  "Table Subtype" = FIELD("Contract Type"),
                                  "No." = FIELD("Contract No."),
                                  "Table Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
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
            group(History)
            {
                Caption = 'History';
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
            }
        }
        area(processing)
        {
            group(General)
            {
                Caption = 'General';
                action("&Print")
                {
                    ApplicationArea = Service;
                    Caption = '&Print';
                    Ellipsis = true;
                    Image = Print;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        DocPrint: Codeunit "Document-Print";
                    begin
                        DocPrint.PrintServiceContract(Rec);
                    end;
                }
            }
            group("New Documents")
            {
                Caption = 'New Documents';
                action("Create Service Credit &Memo")
                {
                    ApplicationArea = Service;
                    Caption = 'Create Service Credit &Memo';
                    Image = CreateCreditMemo;
                    ToolTip = 'Create a new credit memo for the related service invoice.';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                        W1: Dialog;
                        CreditNoteNo: Code[20];
                        i: Integer;
                        j: Integer;
                        LineFound: Boolean;
                    begin
                        CurrPage.Update;
                        TestField(Status, Status::Signed);
                        if "No. of Unposted Credit Memos" <> 0 then
                            if not ConfirmManagement.GetResponseOrDefault(Text009, true) then
                                exit;

                        ServContractMgt.CopyCheckSCDimToTempSCDim(Rec);

                        if not ConfirmManagement.GetResponseOrDefault(Text010, true) then
                            exit;

                        ServContractLine.Reset();
                        ServContractLine.SetCurrentKey("Contract Type", "Contract No.", Credited, "New Line");
                        ServContractLine.SetRange("Contract Type", "Contract Type");
                        ServContractLine.SetRange("Contract No.", "Contract No.");
                        ServContractLine.SetRange(Credited, false);
                        ServContractLine.SetFilter("Credit Memo Date", '>%1&<=%2', 0D, WorkDate);
                        i := ServContractLine.Count();
                        j := 0;
                        if ServContractLine.Find('-') then begin
                            LineFound := true;
                            W1.Open(
                              Text011 +
                              '@1@@@@@@@@@@@@@@@@@@@@@');
                            Clear(ServContractMgt);
                            ServContractMgt.InitCodeUnit;
                            repeat
                                ServContractLine1 := ServContractLine;
                                CreditNoteNo := ServContractMgt.CreateContractLineCreditMemo(ServContractLine1, false);
                                j := j + 1;
                                W1.Update(1, Round(j / i * 10000, 1));
                            until ServContractLine.Next = 0;
                            ServContractMgt.FinishCodeunit;
                            W1.Close;
                            CurrPage.Update(false);
                        end;
                        ServContractLine.SetFilter("Credit Memo Date", '>%1', WorkDate);
                        if CreditNoteNo <> '' then
                            Message(StrSubstNo(Text012, CreditNoteNo))
                        else
                            if not ServContractLine.Find('-') or LineFound then
                                Message(Text013)
                            else
                                Message(Text016, ServContractLine.FieldCaption("Credit Memo Date"), ServContractLine."Credit Memo Date");
                    end;
                }
                action(CreateServiceInvoice)
                {
                    ApplicationArea = Service;
                    Caption = 'Create Service &Invoice';
                    Image = NewInvoice;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create a service invoice for a service contract that is due for invoicing. ';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        CurrPage.Update;
                        TestField(Status, Status::Signed);
                        TestField("Change Status", "Change Status"::Locked);

                        if "No. of Unposted Invoices" <> 0 then
                            if not ConfirmManagement.GetResponseOrDefault(Text003, true) then
                                exit;

                        if "Invoice Period" = "Invoice Period"::None then
                            Error(
                              Text004,
                              TableCaption, "Contract No.", FieldCaption("Invoice Period"), Format("Invoice Period"));

                        if "Next Invoice Date" > WorkDate then
                            if ("Last Invoice Date" = 0D) and
                               ("Starting Date" < "Next Invoice Period Start")
                            then begin
                                Clear(ServContractMgt);
                                ServContractMgt.InitCodeUnit;
                                if ServContractMgt.CreateRemainingPeriodInvoice(Rec) <> '' then
                                    Message(Text006);
                                ServContractMgt.FinishCodeunit;
                                exit;
                            end else
                                Error(Text005);

                        ServContractMgt.CopyCheckSCDimToTempSCDim(Rec);

                        if ConfirmManagement.GetResponseOrDefault(Text007, true) then begin
                            Clear(ServContractMgt);
                            ServContractMgt.InitCodeUnit;
                            ServContractMgt.CreateInvoice(Rec);
                            ServContractMgt.FinishCodeunit;
                            Message(Text008);
                        end;
                    end;
                }
            }
            group(Lock)
            {
                Caption = 'Lock';
                action(LockContract)
                {
                    ApplicationArea = Service;
                    Caption = '&Lock Contract';
                    Image = Lock;
                    Promoted = true;
                    PromotedCategory = Process;
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
                action(OpenContract)
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SelectContractLines)
                {
                    ApplicationArea = Service;
                    Caption = '&Select Contract Lines';
                    Image = CalculateLines;
                    ToolTip = 'Open the list of all the service items that are registered to the customer and select which to include in the contract. ';

                    trigger OnAction()
                    begin
                        CheckRequiredFields;
                        GetServItemLine;
                    end;
                }
                action("&Remove Contract Lines")
                {
                    ApplicationArea = Service;
                    Caption = '&Remove Contract Lines';
                    Image = RemoveLine;
                    ToolTip = 'Remove the selected contract lines from the service contract, for example because you remove the corresponding service items as they are expired or broken.';

                    trigger OnAction()
                    begin
                        ServContractLine.Reset();
                        ServContractLine.SetRange("Contract Type", "Contract Type");
                        ServContractLine.SetRange("Contract No.", "Contract No.");
                        REPORT.RunModal(REPORT::"Remove Lines from Contract", true, true, ServContractLine);
                        CurrPage.Update;
                    end;
                }
                action(SignContract)
                {
                    ApplicationArea = Service;
                    Caption = 'Si&gn Contract';
                    Image = Signature;
                    Promoted = true;
                    PromotedCategory = Process;
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
                action("C&hange Customer")
                {
                    ApplicationArea = Service;
                    Caption = 'C&hange Customer';
                    Image = ChangeCustomer;
                    ToolTip = 'Change the customer in a service contract. If a service item that is subject to a service contract is registered in other contracts owned by the customer, the owner is automatically changed for all service item-related contracts and all contract-related service items.';

                    trigger OnAction()
                    begin
                        Clear(ChangeCustomerinContract);
                        ChangeCustomerinContract.SetRecord("Contract No.");
                        ChangeCustomerinContract.RunModal;
                    end;
                }
                action("Copy &Document...")
                {
                    ApplicationArea = Service;
                    Caption = 'Copy &Document...';
                    Image = CopyDocument;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Copy document lines and header information from another service contractor to this contract to quickly create a similar document.';

                    trigger OnAction()
                    begin
                        CheckRequiredFields;
                        Clear(CopyServDoc);
                        CopyServDoc.SetServContractHeader(Rec);
                        CopyServDoc.RunModal;
                    end;
                }
                action("&File Contract")
                {
                    ApplicationArea = Service;
                    Caption = '&File Contract';
                    Image = Agreement;
                    ToolTip = 'Record and archive a copy of the contract. Service contracts are automatically filed when you convert contract quotes to service contracts or cancel service contracts.';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if ConfirmManagement.GetResponseOrDefault(Text014, true) then
                            FiledServContract.FileContract(Rec);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Contract Details")
            {
                ApplicationArea = Service;
                Caption = 'Contract Details';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Service Contract-Detail";
                ToolTip = 'Specifies billable prices for the job task that are related to items.';
            }
            action("Contract Gain/Loss Entries")
            {
                ApplicationArea = Service;
                Caption = 'Contract Gain/Loss Entries';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Contract Gain/Loss Entries";
                ToolTip = 'Specifies billable prices for the job task that are related to G/L accounts, expressed in the local currency.';
            }
            action("Contract Invoicing")
            {
                ApplicationArea = Service;
                Caption = 'Contract Invoicing';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Contract Invoicing";
                ToolTip = 'Specifies all billable profits for the job task.';
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
            action("Prepaid Contract")
            {
                ApplicationArea = Prepayments;
                Caption = 'Prepaid Contract';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Prepaid Contr. Entries - Test";
                ToolTip = 'View the prepaid service contract.';
            }
            action("Expired Contract Lines")
            {
                ApplicationArea = Service;
                Caption = 'Expired Contract Lines';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Expired Contract Lines - Test";
                ToolTip = 'View the service contract, the service items to be removed, the contract expiration dates, and the line amounts.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CalcFields("Calcd. Annual Amount", "No. of Posted Invoices", "No. of Unposted Invoices");
        ActivateFields;
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateShiptoCode;
    end;

    trigger OnInit()
    begin
        InvoiceAfterServiceEnable := true;
        PrepaidEnable := true;
        FirstServiceDateEditable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Responsibility Center" := UserMgt.GetServiceFilter;
    end;

    trigger OnOpenPage()
    begin
        if UserMgt.GetServiceFilter <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserMgt.GetServiceFilter);
            FilterGroup(0);
        end;

        ActivateFields;
    end;

    var
        Text000: Label '%1 must not be blank in %2 %3', Comment = 'Contract No. must not be blank in Service Contract Header SC00004';
        Text003: Label 'There are unposted invoices associated with this contract.\\Do you want to continue?';
        Text004: Label 'You cannot create an invoice for %1 %2 because %3 is %4.', Comment = 'You cannot create an invoice for Service Contract Header Contract No. because Invoice Period is Month.';
        Text005: Label 'The next invoice date has not expired.';
        Text006: Label 'An invoice was created successfully.';
        Text007: Label 'Do you want to create an invoice for the contract?';
        Text008: Label 'The invoice was created successfully.';
        Text009: Label 'There are unposted credit memos associated with this contract.\\Do you want to continue?';
        Text010: Label 'Do you want to create a credit note for the contract?';
        Text011: Label 'Processing...        \\';
        Text012: Label 'Contract lines have been credited.\\Credit memo %1 was created.';
        Text013: Label 'A credit memo cannot be created. There must be at least one invoiced and expired service contract line which has not yet been credited.';
        Text014: Label 'Do you want to file the contract?';
        ServContractLine: Record "Service Contract Line";
        ServContractLine1: Record "Service Contract Line";
        FiledServContract: Record "Filed Service Contract Header";
        ChangeCustomerinContract: Report "Change Customer in Contract";
        CopyServDoc: Report "Copy Service Document";
        ServContractMgt: Codeunit ServContractManagement;
        UserMgt: Codeunit "User Setup Management";
        Text015: Label '%1 must not be %2 in %3 %4', Comment = 'Status must not be Locked in Service Contract Header SC00005';
        Text016: Label 'A credit memo cannot be created, because the %1 %2 is after the work date.', Comment = 'A credit memo cannot be created, because the Credit Memo Date 03-02-11 is after the work date.';
        FormatAddress: Codeunit "Format Address";
        [InDataSet]
        FirstServiceDateEditable: Boolean;
        [InDataSet]
        PrepaidEnable: Boolean;
        [InDataSet]
        InvoiceAfterServiceEnable: Boolean;
        IsShipToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsBillToCountyVisible: Boolean;

    local procedure CollectShpmntsByLineContractNo(var TempServShptHeader: Record "Service Shipment Header" temporary)
    var
        ServShptHeader: Record "Service Shipment Header";
        ServShptLine: Record "Service Shipment Line";
    begin
        TempServShptHeader.Reset();
        TempServShptHeader.DeleteAll();
        ServShptLine.Reset();
        ServShptLine.SetCurrentKey("Contract No.");
        ServShptLine.SetRange("Contract No.", "Contract No.");
        if ServShptLine.Find('-') then
            repeat
                if ServShptHeader.Get(ServShptLine."Document No.") then begin
                    TempServShptHeader.Copy(ServShptHeader);
                    if TempServShptHeader.Insert() then;
                end;
            until ServShptLine.Next = 0;
    end;

    local procedure ActivateFields()
    begin
        FirstServiceDateEditable := Status <> Status::Signed;
        PrepaidEnable := (not "Invoice after Service" or Prepaid);
        InvoiceAfterServiceEnable := (not Prepaid or "Invoice after Service");
        IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty("Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
    end;

    procedure CheckRequiredFields()
    begin
        if "Contract No." = '' then
            Error(Text000, FieldCaption("Contract No."), TableCaption, "Contract No.");
        if "Customer No." = '' then
            Error(Text000, FieldCaption("Customer No."), TableCaption, "Contract No.");
        if Format("Service Period") = '' then
            Error(Text000, FieldCaption("Service Period"), TableCaption, "Contract No.");
        if "First Service Date" = 0D then
            Error(Text000, FieldCaption("First Service Date"), TableCaption, "Contract No.");
        if Status = Status::Canceled then
            Error(Text015, FieldCaption(Status), Format(Status), TableCaption, "Contract No.");
        if "Change Status" = "Change Status"::Locked then
            Error(Text015, FieldCaption("Change Status"), Format("Change Status"), TableCaption, "Contract No.");
    end;

    local procedure GetServItemLine()
    var
        ContractLineSelection: Page "Contract Line Selection";
    begin
        Clear(ContractLineSelection);
        ContractLineSelection.SetSelection("Customer No.", "Ship-to Code", "Contract Type", "Contract No.");
        ContractLineSelection.RunModal;
        CurrPage.Update(false);
    end;

    local procedure StartingDateOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure StatusOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure CustomerNoOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure BilltoCustomerNoOnAfterValidat()
    begin
        CurrPage.Update;
    end;

    local procedure ShiptoCodeOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure ResponseTimeHoursOnAfterValida()
    begin
        CurrPage.Update(true);
    end;

    local procedure ServicePeriodOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure AnnualAmountOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure InvoiceafterServiceOnAfterVali()
    begin
        ActivateFields;
    end;

    local procedure AllowUnbalancedAmountsOnAfterV()
    begin
        CurrPage.Update;
    end;

    local procedure PrepaidOnAfterValidate()
    begin
        ActivateFields;
    end;

    local procedure ExpirationDateOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure FirstServiceDateOnAfterValidat()
    begin
        CurrPage.Update;
    end;
}

