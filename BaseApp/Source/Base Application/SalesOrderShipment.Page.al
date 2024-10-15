page 10026 "Sales Order Shipment"
{
    Caption = 'Sales Order Shipment';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = FILTER(Order));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the number of the customer that you shipped the items to.';

                    trigger OnValidate()
                    begin
                        SelltoCustomerNoOnAfterValidat;
                    end;
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer that you shipped the items to.';
                }
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the number of the customer that the items are shipped to.';
                }
                field("Bill-to Name"; "Bill-to Name")
                {
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer that the items are shipped to.';
                }
                field("Tax Liable"; "Tax Liable")
                {
                    Editable = false;
                    ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
                }
                field("Posting Date"; "Posting Date")
                {
                    Editable = "Posting DateEditable";
                    ToolTip = 'Specifies the date when the sales order was shipped.';
                }
                field("Order Date"; "Order Date")
                {
                    Editable = "Order DateEditable";
                    ToolTip = 'Specifies the date on which the related sales order was created.';
                }
                field("Document Date"; "Document Date")
                {
                    Editable = "Document DateEditable";
                    ToolTip = 'Specifies the date on which you created the sales document.';
                }
                field("Requested Delivery Date"; "Requested Delivery Date")
                {
                    ToolTip = 'Specifies the date that your customer has requested to have the items delivered. The value in this field is used to calculate the shipment date, which is the date when the items must be available in inventory. If the customer does not request a date, leave the field blank, and the earliest possible date.';
                }
                field("Promised Delivery Date"; "Promised Delivery Date")
                {
                    Editable = false;
                    ToolTip = 'Specifies the delivery date that you promised the customer for the items on this line as a result of the Order Promising function.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    Editable = "Salesperson CodeEditable";
                    ToolTip = 'Specifies the salesperson that is assigned to the order.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the dimension value code that the sales line is associated with.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the dimension value code that the sales line is associated with.';
                }
                field(Status; Status)
                {
                    Editable = false;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("On Hold"; "On Hold")
                {
                    Editable = false;
                    ToolTip = 'Specifies if the document was put on hold when it was posted, for example because payment of the resulting customer ledger entries is overdue.';
                }
            }
            part(SalesLines; "Sales Order Shipment Subform")
            {
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; "Ship-to Code")
                {
                    Editable = "Ship-to CodeEditable";
                    ToolTip = 'Specifies the address that items were shipped to. This field is used when multiple the customer has multiple ship-to addresses.';
                }
                field("Ship-to Name"; "Ship-to Name")
                {
                    Editable = "Ship-to NameEditable";
                    ToolTip = 'Specifies the name of the customer at the address that the items were shipped to.';
                }
                field("Ship-to Address"; "Ship-to Address")
                {
                    Editable = "Ship-to AddressEditable";
                    ToolTip = 'Specifies the address that the items were shipped to.';
                }
                field("Ship-to Address 2"; "Ship-to Address 2")
                {
                    Editable = "Ship-to Address 2Editable";
                    ToolTip = 'Specifies an additional part of the address that the items were shipped to.';
                }
                field("Ship-to City"; "Ship-to City")
                {
                    Editable = "Ship-to CityEditable";
                    ToolTip = 'Specifies the city that the items were shipped to.';
                }
                field("Ship-to County"; "Ship-to County")
                {
                    Caption = 'Ship-to State / ZIP Code';
                    Editable = "Ship-to CountyEditable";
                    ToolTip = 'Specifies the ship-state, ZIP code, ship-to province code, state code, postal code, or ZIP code as a part of the address.';
                }
                field("Ship-to Post Code"; "Ship-to Post Code")
                {
                    Editable = "Ship-to Post CodeEditable";
                    ToolTip = 'Specifies the post code at the address that the items were shipped to.';
                }
                field("Ship-to Contact"; "Ship-to Contact")
                {
                    Editable = "Ship-to ContactEditable";
                    ToolTip = 'Specifies the contact person at the address that the items were shipped to.';
                }
                field("Ship-to UPS Zone"; "Ship-to UPS Zone")
                {
                    ToolTip = 'Specifies a UPS Zone code for this document, if UPS is used for shipments.';
                }
                field("Tax Area Code"; "Tax Area Code")
                {
                    Editable = "Tax Area CodeEditable";
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
                }
                field(FreightAmount; FreightAmount)
                {
                    Caption = 'Freight Amount';
                    ToolTip = 'Specifies the freight amount for the shipment. When you create a sales order, you can specify freight charges as item charges on the sales order, or you can specify the freight charges in the Sales Order Shipment window.';
                }
                field("Location Code"; "Location Code")
                {
                    Editable = "Location CodeEditable";
                    ToolTip = 'Specifies the location from where inventory items are to be shipped by default, to the customer on the sales document.';
                }
                field("Outbound Whse. Handling Time"; "Outbound Whse. Handling Time")
                {
                    ToolTip = 'Specifies the outbound warehouse handling time, which is used to calculate the planned shipment date.';
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    Editable = "Shipment Method CodeEditable";
                    ToolTip = 'Specifies how items on the sales document are shipped to the customer. By default, the field is filled with the value in the Shipment Method Code field on the customer card.';
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    Editable = "Shipping Agent CodeEditable";
                    ToolTip = 'Specifies which shipping company will be used when you ship items to the customer.';
                }
                field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                {
                    ToolTip = 'Specifies the code for the shipping agent service to use for this customer.';
                }
                field("Shipping Time"; "Shipping Time")
                {
                    ToolTip = 'Specifies the shipping time of the order. That is, the time it takes from when the order is shipped from the warehouse to when the order is delivered to the customer''s address.';
                }
                field("Late Order Shipping"; "Late Order Shipping")
                {
                    ToolTip = 'Specifies that the shipment of one or more lines has been delayed, or that the shipment date is before the work date.';
                }
                field("Package Tracking No."; "Package Tracking No.")
                {
                    Editable = "Package Tracking No.Editable";
                    ToolTip = 'Specifies the shipping agent''s package number.';
                }
                field("Shipment Date"; "Shipment Date")
                {
                    Editable = "Shipment DateEditable";
                    ToolTip = 'Specifies the date when the items were shipped.';
                }
                field("Shipping Advice"; "Shipping Advice")
                {
                    ToolTip = 'Specifies if the customer accepts partial shipment of orders. If you select Partial, then the Qty. To Ship field can be lower than the Quantity field on sales lines.  ';
                }
            }
        }
        area(factboxes)
        {
            part(Control1903720907; "Sales Hist. Sell-to FactBox")
            {
                Editable = false;
                SubPageLink = "No." = FIELD("Sell-to Customer No.");
                Visible = true;
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                Editable = false;
                SubPageLink = "No." = FIELD("Bill-to Customer No.");
                Visible = true;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                Editable = false;
                SubPageLink = "No." = FIELD("Sell-to Customer No.");
                Visible = true;
            }
            part(Control1906127307; "Sales Line FactBox")
            {
                Editable = false;
                Provider = SalesLines;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No."),
                              "Line No." = FIELD("Line No.");
                Visible = true;
            }
            part(Control1901314507; "Item Invoicing FactBox")
            {
                Editable = false;
                Provider = SalesLines;
                SubPageLink = "No." = FIELD("No.");
                Visible = true;
            }
            part(Control1906354007; "Approval FactBox")
            {
                Editable = false;
                SubPageLink = "Table ID" = CONST(36),
                              "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No."),
                              Status = CONST(Open);
                Visible = true;
            }
            part(Control1901796907; "Item Warehouse FactBox")
            {
                Editable = false;
                Provider = SalesLines;
                SubPageLink = "No." = FIELD("No.");
                Visible = false;
            }
            part(Control1907234507; "Sales Hist. Bill-to FactBox")
            {
                Editable = false;
                SubPageLink = "No." = FIELD("Bill-to Customer No.");
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Editable = true;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        SalesSetup.Get();
                        if SalesSetup."Calc. Inv. Discount" then begin
                            CurrPage.SalesLines.PAGE.CalcInvDisc;
                            Commit
                        end;
                        OnBeforeCalculateSalesTaxStatistics(Rec, true);
                        if "Tax Area Code" = '' then
                            PAGE.RunModal(PAGE::"Sales Order Statistics", Rec)
                        else
                            PAGE.RunModal(PAGE::"Sales Order Stats.", Rec)
                    end;
                }
                action(Card)
                {
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = FIELD("Sell-to Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the card for the customer.';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = FIELD("Document Type"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View comments that apply.';
                }
                action("S&hipments")
                {
                    Caption = 'S&hipments';
                    Image = Shipment;
                    RunObject = Page "Posted Sales Shipments";
                    RunPageLink = "Order No." = FIELD("No.");
                    RunPageView = SORTING("Order No.");
                    ToolTip = 'View posted sales shipments for the customer.';
                }
                action(Invoices)
                {
                    Caption = 'Invoices';
                    Image = Invoice;
                    RunObject = Page "Posted Sales Invoices";
                    RunPageLink = "Order No." = FIELD("No.");
                    RunPageView = SORTING("Order No.");
                    ToolTip = 'View the history of posted sales invoices that have been posted for the document.';
                }
                action(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDocDim;
                        CurrPage.SaveRecord;
                    end;
                }
                action("Order &Promising")
                {
                    Caption = 'Order &Promising';
                    Image = OrderPromising;
                    ToolTip = 'View any order promising lines that are related to the shipment.';

                    trigger OnAction()
                    var
                        OrderPromisingLine: Record "Order Promising Line" temporary;
                    begin
                        OrderPromisingLine.SetRange("Source Type", "Document Type");
                        OrderPromisingLine.SetRange("Source ID", "No.");
                        PAGE.RunModal(PAGE::"Order Promising Lines", OrderPromisingLine);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Sales Shipment per Package")
            {
                Caption = 'Sales Shipment per Package';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Sales Shipment per Package";
                ToolTip = 'View sales shipment information for each package. Information includes shipment number, shipment date, number of units, items shipped, items ordered, and items placed on back order.';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Re&open")
                {
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        ReleaseSalesDoc.Reopen(Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        OnBeforeCalculateSalesTaxStatistics(Rec, false);
                        ReportPrint.PrintSalesHeader(Rec);
                    end;
                }
                action("P&ost")
                {
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        PrepaymentMgt: Codeunit "Prepayment Mgt.";
                    begin
                        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then begin
                            if PrepaymentMgt.TestSalesPrepayment(Rec) then
                                Error(Text001, "Document Type", "No.");

                            if PrepaymentMgt.TestSalesPayment(Rec) then
                                Error(Text002, "Document Type", "No.");

                            SalesLine.Validate("Document Type", "Document Type");
                            SalesLine.Validate("Document No.", "No.");
                            SalesLine.InsertFreightLine(FreightAmount);
                            CODEUNIT.Run(CODEUNIT::"Ship-Post (Yes/No)", Rec);
                            if "Shipping No." = '-1' then
                                Error('');
                        end;
                    end;
                }
                action("Post and &Print")
                {
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        PrepaymentMgt: Codeunit "Prepayment Mgt.";
                    begin
                        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then begin
                            if PrepaymentMgt.TestSalesPrepayment(Rec) then
                                Error(Text001, "Document Type", "No.");

                            if PrepaymentMgt.TestSalesPayment(Rec) then
                                Error(Text002, "Document Type", "No.");

                            SalesLine.Validate("Document Type", "Document Type");
                            SalesLine.Validate("Document No.", "No.");
                            SalesLine.InsertFreightLine(FreightAmount);
                            CODEUNIT.Run(CODEUNIT::"Ship-Post + Print", Rec);
                            if "Shipping No." = '-1' then
                                Error('');
                        end;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord;
        exit(ConfirmDeletion);
    end;

    trigger OnInit()
    begin
        "Tax Area CodeEditable" := true;
        "Package Tracking No.Editable" := true;
        "Shipment Method CodeEditable" := true;
        "Shipping Agent CodeEditable" := true;
        "Shipment DateEditable" := true;
        "Location CodeEditable" := true;
        "Ship-to CountyEditable" := true;
        "Ship-to CodeEditable" := true;
        "Ship-to Post CodeEditable" := true;
        "Ship-to ContactEditable" := true;
        "Ship-to CityEditable" := true;
        "Ship-to Address 2Editable" := true;
        "Ship-to AddressEditable" := true;
        "Ship-to NameEditable" := true;
        "Document DateEditable" := true;
        "Salesperson CodeEditable" := true;
        "Posting DateEditable" := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Responsibility Center" := UserMgt.GetSalesFilter;
        AfterGetCurrentRecord;
    end;

    trigger OnOpenPage()
    begin
        if UserMgt.GetSalesFilter <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserMgt.GetSalesFilter);
            FilterGroup(0);
        end;

        SetRange("Date Filter", 0D, WorkDate - 1);
    end;

    var
        Text000: Label 'Unable to run this function while in View mode.';
        SalesLine: Record "Sales Line";
        ReportPrint: Codeunit "Test Report-Print";
        SalesSetup: Record "Sales & Receivables Setup";
        UserMgt: Codeunit "User Setup Management";
        FreightAmount: Decimal;
        Text001: Label 'There are non posted Prepayment Amounts on %1 %2.';
        Text002: Label 'There are unpaid Prepayment Invoices related to %1 %2.';
        [InDataSet]
        "Posting DateEditable": Boolean;
        [InDataSet]
        "Order DateEditable": Boolean;
        [InDataSet]
        "Salesperson CodeEditable": Boolean;
        [InDataSet]
        "Document DateEditable": Boolean;
        [InDataSet]
        "Ship-to NameEditable": Boolean;
        [InDataSet]
        "Ship-to AddressEditable": Boolean;
        [InDataSet]
        "Ship-to Address 2Editable": Boolean;
        [InDataSet]
        "Ship-to CityEditable": Boolean;
        [InDataSet]
        "Ship-to ContactEditable": Boolean;
        [InDataSet]
        "Ship-to Post CodeEditable": Boolean;
        [InDataSet]
        "Ship-to CodeEditable": Boolean;
        [InDataSet]
        "Ship-to CountyEditable": Boolean;
        [InDataSet]
        "Location CodeEditable": Boolean;
        [InDataSet]
        "Shipment DateEditable": Boolean;
        [InDataSet]
        "Shipping Agent CodeEditable": Boolean;
        [InDataSet]
        "Shipment Method CodeEditable": Boolean;
        [InDataSet]
        "Package Tracking No.Editable": Boolean;
        [InDataSet]
        "Tax Area CodeEditable": Boolean;

    procedure UpdateAllowed(): Boolean
    begin
        if CurrPage.Editable = false then
            Error(Text000);
        exit(true);
    end;

    procedure OrderOnHold(OnHold: Boolean)
    begin
        "Posting DateEditable" := not OnHold;
        "Order DateEditable" := not OnHold;
        "Salesperson CodeEditable" := not OnHold;
        "Document DateEditable" := not OnHold;
        "Ship-to NameEditable" := not OnHold;
        "Ship-to AddressEditable" := not OnHold;
        "Ship-to Address 2Editable" := not OnHold;
        "Ship-to CityEditable" := not OnHold;
        "Ship-to ContactEditable" := not OnHold;
        "Ship-to Post CodeEditable" := not OnHold;
        "Ship-to CodeEditable" := not OnHold;
        "Ship-to CountyEditable" := not OnHold;
        // CurrForm."Ship-to UPS Zone".EDITABLE := NOT OnHold;
        "Location CodeEditable" := not OnHold;
        "Shipment DateEditable" := not OnHold;
        "Shipping Agent CodeEditable" := not OnHold;
        "Shipment Method CodeEditable" := not OnHold;
        "Package Tracking No.Editable" := not OnHold;
        "Tax Area CodeEditable" := not OnHold;

        CurrPage.SalesLines.PAGE.OrderOnHold(OnHold);
    end;

    local procedure SelltoCustomerNoOnAfterValidat()
    begin
        CurrPage.Update;
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        SetRange("Date Filter", 0D, WorkDate - 1);

        OrderOnHold("On Hold" <> '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxStatistics(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
    end;
}

