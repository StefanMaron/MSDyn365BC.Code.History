page 6053 "Service Contract Quote"
{
    Caption = 'Service Contract Quote';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Service Contract Header";
    SourceTableView = WHERE("Contract Type" = FILTER(Quote));

    layout
    {
        area(content)
        {
            group(General)
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
                group("Sell-to")
                {
                    Caption = 'Sell-to';
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
                    group(Control13)
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
                field("Quote Type"; "Quote Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the service contract quote.';
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
                    Editable = true;
                    Importance = Promoted;
                    OptionCaption = ' ,,Canceled';
                    ToolTip = 'Specifies the status of the service contract or contract quote.';

                    trigger OnValidate()
                    begin
                        StatusOnAfterValidate;
                    end;
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Change Status"; "Change Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if a service contract or contract quote is locked or open for changes.';
                }
            }
            part(ServContractLines; "Service Contract Quote Subform")
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
                group(Control14)
                {
                    ShowCaption = false;
                    field("Bill-to Name"; "Bill-to Name")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    }
                    field("Bill-to Address"; "Bill-to Address")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the address of the customer to whom you will send the invoice.';
                    }
                    field("Bill-to Address 2"; "Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies an additional line of the address.';
                    }
                    field("Bill-to City"; "Bill-to City")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control23)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; "Bill-to County")
                        {
                            ApplicationArea = Service;
                            QuickEntry = false;
                            ToolTip = 'Specifies the county code of the customer''s billing address.';
                        }
                    }
                    field("Bill-to Post Code"; "Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    }
                    field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the country/region code of the customer''s billing address.';

                        trigger OnValidate()
                        begin
                            IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
                        end;
                    }
                    field("Bill-to Contact"; "Bill-to Contact")
                    {
                        ApplicationArea = Service;
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
                group(Control25)
                {
                    ShowCaption = false;
                }
                field("Ship-to Name"; "Ship-to Name")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                }
                field("Ship-to Address"; "Ship-to Address")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the address that the items are shipped to.';
                }
                field("Ship-to Address 2"; "Ship-to Address 2")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                }
                field("Ship-to City"; "Ship-to City")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the city of the address that the items are shipped to.';
                }
                group(Control33)
                {
                    ShowCaption = false;
                    Visible = IsShipToCountyVisible;
                    field("Ship-to County"; "Ship-to County")
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the county of the address.';
                    }
                }
                field("Ship-to Post Code"; "Ship-to Post Code")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                }
                field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the country/region code of the address.';
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
                    Importance = Promoted;
                    ToolTip = 'Specifies a default service period for the items in the contract.';

                    trigger OnValidate()
                    begin
                        ServicePeriodOnAfterValidate;
                    end;
                }
                field("First Service Date"; "First Service Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date of the first expected service for the service items in the contract.';
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
                field("Invoice Period"; "Invoice Period")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the invoice period for the service contract.';
                }
                field("Next Invoice Date"; "Next Invoice Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date of the next invoice for this service contract.';
                }
                field("Amount per Period"; "Amount per Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount that will be invoiced for each invoice period for the service contract.';
                }
                field(NextInvoicePeriod; NextInvoicePeriod)
                {
                    ApplicationArea = Service;
                    Caption = 'Next Invoice Period';
                    ToolTip = 'Specifies the next invoice period for the filed service contract quote: the first date of the period and the ending date.';
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
                field("Max. Labor Unit Price"; "Max. Labor Unit Price")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the maximum unit price that can be set for a resource on all service orders and lines for the service contract.';
                }
                field("Accept Before"; "Accept Before")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date before which the customer must accept this contract quote.';
                }
                field(Probability; Probability)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the probability of the customer approving the service contract quote.';
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
            group("&Quote")
            {
                Caption = '&Quote';
                Image = Quote;
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
                                  "Service Contract Type" = FILTER(Quote);
                    ToolTip = 'View the service hours that are valid for the service contract. This window displays the starting and ending service hours for the contract for each weekday.';
                }
                action("&Filed Contract Quotes")
                {
                    ApplicationArea = Service;
                    Caption = '&Filed Contract Quotes';
                    Image = Quote;
                    RunObject = Page "Filed Service Contract List";
                    RunPageLink = "Contract Type Relation" = FIELD("Contract Type"),
                                  "Contract No. Relation" = FIELD("Contract No.");
                    RunPageView = SORTING("Contract Type Relation", "Contract No. Relation", "File Date", "File Time")
                                  ORDER(Descending);
                    ToolTip = 'View filed contract quotes.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Select Contract Quote Lines")
                {
                    ApplicationArea = Service;
                    Caption = '&Select Contract Quote Lines';
                    Image = CalculateLines;
                    ToolTip = 'Open the list of all the service items that are registered to the customer and select which to include in the contract quote. ';

                    trigger OnAction()
                    begin
                        CheckRequiredFields;
                        GetServItemLine;
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
                action("&File Contract Quote")
                {
                    ApplicationArea = Service;
                    Caption = '&File Contract Quote';
                    Image = FileContract;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Record and archive a copy of the contract quote. Service contract quotes are automatically filed when you convert contract quotes to service contracts or cancel service contracts.';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if ConfirmManagement.GetResponseOrDefault(Text001, true) then
                            FiledServContract.FileContract(Rec);
                    end;
                }
                action("Update &Discount % on All Lines")
                {
                    ApplicationArea = Service;
                    Caption = 'Update &Discount % on All Lines';
                    Image = Refresh;
                    ToolTip = 'Update the quote discount on all the service items in a service contract quote. You need to specify the number that you want to add to or subtract from the quote discount percentage that you have specified in the Contract/Service Discount table. The batch job then updates the quote amounts accordingly.';

                    trigger OnAction()
                    begin
                        ServContractLine.Reset();
                        ServContractLine.SetRange("Contract Type", "Contract Type");
                        ServContractLine.SetRange("Contract No.", "Contract No.");
                        REPORT.RunModal(REPORT::"Upd. Disc.% on Contract", true, true, ServContractLine);
                    end;
                }
                action("Update with Contract &Template")
                {
                    ApplicationArea = Service;
                    Caption = 'Update with Contract &Template';
                    Image = Refresh;
                    ToolTip = 'Implement template information on the contract.';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if not ConfirmManagement.GetResponseOrDefault(Text002, true) then
                            exit;
                        CurrPage.Update(true);
                        Clear(ServContrQuoteTmplUpd);
                        ServContrQuoteTmplUpd.Run(Rec);
                        CurrPage.Update(true);
                    end;
                }
                action("Loc&k")
                {
                    ApplicationArea = Service;
                    Caption = 'Loc&k';
                    Image = Lock;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Make sure that the contract cannot be changed.';

                    trigger OnAction()
                    begin
                        LockOpenServContract.LockServContract(Rec);
                        CurrPage.Update;
                    end;
                }
                action("&Open")
                {
                    ApplicationArea = Service;
                    Caption = '&Open';
                    Image = Edit;
                    ShortCutKey = 'Return';
                    ToolTip = 'Open the service contract quote.';

                    trigger OnAction()
                    begin
                        LockOpenServContract.OpenServContract(Rec);
                        CurrPage.Update;
                    end;
                }
            }
            action("&Make Contract")
            {
                ApplicationArea = Service;
                Caption = '&Make Contract';
                Image = MakeAgreement;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to create a service contract.';

                trigger OnAction()
                var
                    SignServContractDoc: Codeunit SignServContractDoc;
                begin
                    CurrPage.Update(true);
                    SignServContractDoc.SignContractQuote(Rec);
                end;
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
            action("Service Quote Details")
            {
                ApplicationArea = Service;
                Caption = 'Service Quote Details';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Service Contract Quote-Detail";
                ToolTip = 'View details information for the quote.';
            }
            action("Contract Quotes to be Signed")
            {
                ApplicationArea = Service;
                Caption = 'Contract Quotes to be Signed';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Contract Quotes to Be Signed";
                ToolTip = 'View the contract number, customer name and address, salesperson code, starting date, probability, quoted amount, and forecast. You can print all your information about contract quotes to be signed.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CalcFields("Calcd. Annual Amount");
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
        Text001: Label 'Do you want to file the contract quote?';
        Text002: Label 'Do you want to update the contract quote using a contract template?';
        FiledServContract: Record "Filed Service Contract Header";
        ServContractLine: Record "Service Contract Line";
        CopyServDoc: Report "Copy Service Document";
        UserMgt: Codeunit "User Setup Management";
        ServContrQuoteTmplUpd: Codeunit "ServContractQuote-Tmpl. Upd.";
        Text003: Label '%1 must not be %2 in %3 %4', Comment = 'Status must not be blank in Signed SC00001';
        LockOpenServContract: Codeunit "Lock-OpenServContract";
        FormatAddress: Codeunit "Format Address";
        [InDataSet]
        PrepaidEnable: Boolean;
        [InDataSet]
        InvoiceAfterServiceEnable: Boolean;
        IsShipToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsBillToCountyVisible: Boolean;

    local procedure ActivateFields()
    begin
        PrepaidEnable := (not "Invoice after Service" or Prepaid);
        InvoiceAfterServiceEnable := (not Prepaid or "Invoice after Service");
        IsSellToCountyVisible := FormatAddress.UseCounty("Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
        IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
    end;

    local procedure CheckRequiredFields()
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
            Error(Text003, FieldCaption(Status), Format(Status), TableCaption, "Contract No.");
        if "Change Status" = "Change Status"::Locked then
            Error(Text003, FieldCaption("Change Status"), Format("Change Status"), TableCaption, "Contract No.");
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

    local procedure StatusOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure CustomerNoOnAfterValidate()
    begin
        CurrPage.Update;
    end;

    local procedure StartingDateOnAfterValidate()
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

    local procedure ServicePeriodOnAfterValidate()
    begin
        CurrPage.Update;
    end;
}

