page 5975 "Posted Service Shipment"
{
    Caption = 'Posted Service Shipment';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Service Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies a description of the order from which the shipment was posted.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer who owns the items on the service order.';
                }
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contact person at the customer''s site.';
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field(Name; Name)
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer.';
                    }
                    field(Address; Address)
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the address of the customer of the posted service shipment.';
                    }
                    field("Address 2"; "Address 2")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field(City; City)
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control17)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field(County; County)
                        {
                            ApplicationArea = Service;
                            Editable = false;
                            ToolTip = 'Specifies the state, province or county related to the posted service shipment.';
                        }
                    }
                    field("Post Code"; "Post Code")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Country/Region Code"; "Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the country/region of the address.';
                    }
                    field("Contact Name"; "Contact Name")
                    {
                        ApplicationArea = Service;
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the customer company.';
                    }
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the customer phone number.';
                }
                field("Phone No. 2"; "Phone No. 2")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies your customer''s alternate phone number.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the customer.';
                }
                field("Notify Customer"; "Notify Customer")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies in what way the customer wants to receive notifications about the service completed.';
                }
                field("Service Order Type"; "Service Order Type")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the type of the service order from which the shipment was created.';
                }
                field("Contract No."; "Contract No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contract associated with the service order.';
                }
                field("Response Date"; "Response Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the approximate date when work on the service order started.';
                }
                field("Response Time"; "Response Time")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the approximate time when work on the service order started.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the priority of the posted service order.';
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the service order from which the shipment was created.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
            }
            part(ServShipmentItemLines; "Posted Service Shpt. Subform")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = FIELD("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                }
                group("Bill-to")
                {
                    Caption = 'Bill-to';
                    field("Bill-to Name"; "Bill-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = ' Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    }
                    field("Bill-to Address"; "Bill-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address of the customer to whom you sent the invoice.';
                    }
                    field("Bill-to Address 2"; "Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional line of the address.';
                    }
                    field("Bill-to City"; "Bill-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control21)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; "Bill-to County")
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                            Editable = false;
                            ToolTip = 'Specifies the state, province or county for the customer that the invoice is sent to.';
                        }
                    }
                    field("Bill-to Post Code"; "Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    }
                    field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Bill-to Contact"; "Bill-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                    }
                }
                field("Your Reference"; "Your Reference")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies a reference to the customer.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the code of the salesperson assigned to the service order.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the shipment was posted.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Ship-to Name"; "Ship-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    }
                    field("Ship-to Address"; "Ship-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; "Ship-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    field("Ship-to City"; "Ship-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the address that the items are shipped to.';
                    }
                    group(Control29)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; "Ship-to County")
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                            Editable = false;
                        }
                    }
                    field("Ship-to Post Code"; "Ship-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Ship-to Contact"; "Ship-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    }
                }
                field("Ship-to Phone"; "Ship-to Phone")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the customer phone number.';
                }
                field("Ship-to Phone 2"; "Ship-to Phone 2")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies an additional phone number at address that the items are shipped to.';
                }
                field("Ship-to E-Mail"; "Ship-to E-Mail")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the email address at the address that the items are shipped to.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location, such as warehouse or distribution center, from where the items on the order were shipped.';
                }
            }
            group(Details)
            {
                Caption = 'Details';
                field("Warning Status"; "Warning Status")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the warning status for the response time on the original service order.';
                }
                field("Link Service to Service Item"; "Link Service to Service Item")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the value in this field from the Link Service to Service Item field on the service header.';
                }
                field("Allocated Hours"; "Allocated Hours")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of hours allocated to the items within the posted service order.';
                }
                field("Service Zone Code"; "Service Zone Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the service zone code assigned to the customer.';
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the related order was created.';
                }
                field("Order Time"; "Order Time")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the time when the service order was created.';
                }
                field("Expected Finishing Date"; "Expected Finishing Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when service on the order is expected to be finished.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the starting date of the service on the shipment.';
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the starting time of the service on the shipment.';
                }
                field("Actual Response Time (Hours)"; "Actual Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the hours since the creation of the service order, to the time when the order status was changed from Pending to In Process.';
                }
                field("Finishing Date"; "Finishing Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when the service is finished.';
                }
                field("Finishing Time"; "Finishing Time")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the time when the service is finished.';
                }
                field("Service Time (Hours)"; "Service Time (Hours)")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the total time in hours that the service on the service order has taken.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the currency code for various amounts on the shipment.';
                }
                field("EU 3-Party Trade"; "EU 3-Party Trade")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
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
            group("&Shipment")
            {
                Caption = '&Shipment';
                Image = Shipment;
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Document Type" = CONST(Shipment),
                                  "Document No." = FIELD("No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
                action("&Warranty Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Warranty Ledger Entries';
                    Image = WarrantyLedger;
                    RunObject = Page "Warranty Ledger Entries";
                    RunPageLink = "Document No." = FIELD("No.");
                    RunPageView = SORTING("Document No.", "Posting Date");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
                }
                action("&Job Ledger Entries")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Job Ledger Entries';
                    Image = JobLedger;
                    RunObject = Page "Job Ledger Entries";
                    RunPageLink = "Document No." = FIELD("No.");
                    ToolTip = 'View all the job ledger entries that result from posting transactions in the service document that involve a job.';
                }
                action("&Allocations")
                {
                    ApplicationArea = Service;
                    Caption = '&Allocations';
                    Image = Allocations;
                    RunObject = Page "Service Order Allocations";
                    RunPageLink = "Document Type" = CONST(Order),
                                  "Document No." = FIELD("Order No.");
                    RunPageView = SORTING(Status, "Document Type", "Document No.", "Service Item Line No.", "Allocation Date", "Starting Time", Posted);
                    ToolTip = 'View allocation of resources, such as technicians, to service items in service orders.';
                }
                action("S&tatistics")
                {
                    ApplicationArea = Service;
                    Caption = 'S&tatistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Service Shipment Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View information about the physical contents of the shipment, such as quantity of the shipped items, resource hours or costs, and weight and volume of the shipped items.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "No." = FIELD("No."),
                                  "Table Name" = CONST("Service Shipment Header"),
                                  Type = CONST(General);
                    ToolTip = 'View or add comments for the record.';
                }
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
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
                action("Service Document Lo&g")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Document Lo&g';
                    Image = Log;
                    ToolTip = 'View a list of the service document changes that have been logged. The program creates entries in the window when, for example, the response time or service order status changed, a resource was allocated, a service order was shipped or invoiced, and so on. Each line in this window identifies the event that occurred to the service document. The line contains the information about the field that was changed, its old and new value, the date and time when the change took place, and the ID of the user who actually made the changes.';

                    trigger OnAction()
                    var
                        TempServDocLog: Record "Service Document Log" temporary;
                    begin
                        TempServDocLog.Reset();
                        TempServDocLog.DeleteAll();
                        TempServDocLog.CopyServLog(TempServDocLog."Document Type"::Shipment, "No.");
                        TempServDocLog.CopyServLog(TempServDocLog."Document Type"::Order, "Order No.");

                        TempServDocLog.Reset();
                        TempServDocLog.SetCurrentKey("Change Date", "Change Time");
                        TempServDocLog.Ascending(false);

                        PAGE.Run(0, TempServDocLog);
                    end;
                }
                action("Service Email &Queue")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Email &Queue';
                    Image = Email;
                    RunObject = Page "Service Email Queue";
                    RunPageLink = "Document Type" = CONST("Service Order"),
                                  "Document No." = FIELD("Order No.");
                    RunPageView = SORTING("Document Type", "Document No.");
                    ToolTip = 'View the emails that are waiting to be sent to notify customers that their service item is ready.';
                }
                action(CertificateOfSupplyDetails)
                {
                    ApplicationArea = Service;
                    Caption = 'Certificate of Supply Details';
                    Image = Certificate;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Certificates of Supply";
                    RunPageLink = "Document Type" = FILTER("Service Shipment"),
                                  "Document No." = FIELD("No.");
                    ToolTip = 'View the certificate of supply that you must send to your customer for signature as confirmation of receipt. You must print a certificate of supply if the shipment uses a combination of VAT business posting group and VAT product posting group that have been marked to require a certificate of supply in the VAT Posting Setup window.';
                }
                action(PrintCertificateofSupply)
                {
                    ApplicationArea = Service;
                    Caption = 'Print Certificate of Supply';
                    Image = PrintReport;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Print the certificate of supply that you must send to your customer for signature as confirmation of receipt.';

                    trigger OnAction()
                    var
                        CertificateOfSupply: Record "Certificate of Supply";
                    begin
                        CertificateOfSupply.SetRange("Document Type", CertificateOfSupply."Document Type"::"Service Shipment");
                        CertificateOfSupply.SetRange("Document No.", "No.");
                        CertificateOfSupply.Print;
                    end;
                }
            }
        }
        area(processing)
        {
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
                begin
                    CurrPage.SetSelectionFilter(ServShptHeader);
                    ServShptHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Service;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Find(Which) then
            exit(true);
        SetRange("No.");
        exit(Find(Which));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"Shipment Header - Edit", Rec);
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        SetSecurityFilterOnRespCenter;

        ActivateFields;
    end;

    var
        ServShptHeader: Record "Service Shipment Header";
        FormatAddress: Codeunit "Format Address";
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        IsBillToCountyVisible: Boolean;

    local procedure ActivateFields()
    begin
        IsSellToCountyVisible := FormatAddress.UseCounty("Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
        IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
    end;
}

