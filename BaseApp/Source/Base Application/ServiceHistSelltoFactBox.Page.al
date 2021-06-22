page 9085 "Service Hist. Sell-to FactBox"
{
    Caption = 'Sell-to Customer Service History';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("No."; "No.")
            {
                ApplicationArea = All;
                Caption = 'Customer No.';
                ToolTip = 'Specifies the number of the customer. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';

                trigger OnDrillDown()
                begin
                    ShowDetails;
                end;
            }
            group(Control1)
            {
                ShowCaption = false;
                Visible = RegularFastTabVisible;
                field(NoOfQuotes; NoOfQuotes)
                {
                    ApplicationArea = Service;
                    Caption = 'Quotes';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies the number of quotes that exist for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Service Quotes", ServiceHeader);
                    end;
                }
                field(NoOfOrders; NoOfOrders)
                {
                    ApplicationArea = Service;
                    Caption = 'Orders';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies the number of posted orders that exist for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Service Orders", ServiceHeader);
                    end;
                }
                field(NoOfInvoices; NoOfInvoices)
                {
                    ApplicationArea = Service;
                    Caption = 'Invoices';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies the invoice related to the customer service history.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Service Invoices", ServiceHeader);
                    end;
                }
                field(NoOfCreditMemos; NoOfCreditMemos)
                {
                    ApplicationArea = Service;
                    Caption = 'Credit Memos';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies service credit memos relating to the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Service Credit Memos", ServiceHeader);
                    end;
                }
                field(NoOfPostedShipments; NoOfPostedShipments)
                {
                    ApplicationArea = Service;
                    Caption = 'Pstd. Shipments';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies how many posted shipments have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceShipmentHdr: Record "Service Shipment Header";
                    begin
                        ServiceShipmentHdr.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Posted Service Shipments", ServiceShipmentHdr);
                    end;
                }
                field(NoOfPostedInvoices; NoOfPostedInvoices)
                {
                    ApplicationArea = Service;
                    Caption = 'Pstd. Invoices';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies how many posted invoices have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceInvoiceHdr: Record "Service Invoice Header";
                    begin
                        ServiceInvoiceHdr.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Posted Service Invoices", ServiceInvoiceHdr);
                    end;
                }
                field(NoOfPostedCreditMemos; NoOfPostedCreditMemos)
                {
                    ApplicationArea = Service;
                    Caption = 'Pstd. Credit Memos';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies how many posted credit memos have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceCrMemoHdr: Record "Service Cr.Memo Header";
                    begin
                        ServiceCrMemoHdr.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Posted Service Credit Memos", ServiceCrMemoHdr);
                    end;
                }
            }
            cuegroup(Control14)
            {
                ShowCaption = false;
                Visible = NOT RegularFastTabVisible;
                field(NoOfQuotesTile; NoOfQuotes)
                {
                    ApplicationArea = Service;
                    Caption = 'Quotes';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies the number of quotes that exist for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Service Quotes", ServiceHeader);
                    end;
                }
                field(NoOfOrdersTile; NoOfOrders)
                {
                    ApplicationArea = Service;
                    Caption = 'Orders';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies the number of posted orders that exist for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Service Orders", ServiceHeader);
                    end;
                }
                field(NoOfInvoicesTile; NoOfInvoices)
                {
                    ApplicationArea = Service;
                    Caption = 'Invoices';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies the invoice related to the customer service history.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Service Invoices", ServiceHeader);
                    end;
                }
                field(NoOfCreditMemosTile; NoOfCreditMemos)
                {
                    ApplicationArea = Service;
                    Caption = 'Credit Memos';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies service credit memos relating to the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceHeader: Record "Service Header";
                    begin
                        ServiceHeader.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Service Credit Memos", ServiceHeader);
                    end;
                }
                field(NoOfPostedShipmentsTile; NoOfPostedShipments)
                {
                    ApplicationArea = Service;
                    Caption = 'Pstd. Shipments';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies how many posted shipments have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceShipmentHdr: Record "Service Shipment Header";
                    begin
                        ServiceShipmentHdr.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Posted Service Shipments", ServiceShipmentHdr);
                    end;
                }
                field(NoOfPostedInvoicesTile; NoOfPostedInvoices)
                {
                    ApplicationArea = Service;
                    Caption = 'Pstd. Invoices';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies how many posted invoices have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceInvoiceHdr: Record "Service Invoice Header";
                    begin
                        ServiceInvoiceHdr.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Posted Service Invoices", ServiceInvoiceHdr);
                    end;
                }
                field(NoOfPostedCreditMemosTile; NoOfPostedCreditMemos)
                {
                    ApplicationArea = Service;
                    Caption = 'Pstd. Credit Memos';
                    DrillDown = true;
                    Editable = true;
                    ToolTip = 'Specifies how many posted credit memos have been registered for the customer.';

                    trigger OnDrillDown()
                    var
                        ServiceCrMemoHdr: Record "Service Cr.Memo Header";
                    begin
                        ServiceCrMemoHdr.SetRange("Customer No.", "No.");
                        PAGE.Run(PAGE::"Posted Service Credit Memos", ServiceCrMemoHdr);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcNoOfRecords;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        NoOfQuotes := 0;
        NoOfOrders := 0;
        NoOfInvoices := 0;
        NoOfCreditMemos := 0;
        NoOfPostedShipments := 0;
        NoOfPostedInvoices := 0;
        NoOfPostedCreditMemos := 0;

        exit(Find(Which));
    end;

    trigger OnOpenPage()
    begin
        CalcNoOfRecords;
        RegularFastTabVisible := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Windows;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        RegularFastTabVisible: Boolean;
        NoOfQuotes: Integer;
        NoOfOrders: Integer;
        NoOfInvoices: Integer;
        NoOfCreditMemos: Integer;
        NoOfPostedShipments: Integer;
        NoOfPostedInvoices: Integer;
        NoOfPostedCreditMemos: Integer;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Customer Card", Rec);
    end;

    local procedure CalcNoOfRecords()
    var
        ServHeader: Record "Service Header";
        ServShptHeader: Record "Service Shipment Header";
        ServInvHeader: Record "Service Invoice Header";
        ServCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServHeader.Reset();
        ServHeader.SetRange("Document Type", ServHeader."Document Type"::Quote);
        ServHeader.SetRange("Customer No.", "No.");
        NoOfQuotes := ServHeader.Count();

        ServHeader.Reset();
        ServHeader.SetRange("Document Type", ServHeader."Document Type"::Order);
        ServHeader.SetRange("Customer No.", "No.");
        NoOfOrders := ServHeader.Count();

        ServHeader.Reset();
        ServHeader.SetRange("Document Type", ServHeader."Document Type"::Invoice);
        ServHeader.SetRange("Customer No.", "No.");
        NoOfInvoices := ServHeader.Count();

        ServHeader.Reset();
        ServHeader.SetRange("Document Type", ServHeader."Document Type"::"Credit Memo");
        ServHeader.SetRange("Customer No.", "No.");
        NoOfCreditMemos := ServHeader.Count();

        ServShptHeader.Reset();
        ServShptHeader.SetRange("Customer No.", "No.");
        NoOfPostedShipments := ServShptHeader.Count();

        ServInvHeader.Reset();
        ServInvHeader.SetRange("Customer No.", "No.");
        NoOfPostedInvoices := ServInvHeader.Count();

        ServCrMemoHeader.Reset();
        ServCrMemoHeader.SetRange("Customer No.", "No.");
        NoOfPostedCreditMemos := ServCrMemoHeader.Count();
    end;
}

