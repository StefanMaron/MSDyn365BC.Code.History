page 10028 "Sales Order Invoice"
{
    Caption = 'Sales Order Invoice';
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
                    ToolTip = 'Specifies the number of the customer that you invoiced the items to.';

                    trigger OnValidate()
                    begin
                        SelltoCustomerNoOnAfterValidat;
                    end;
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer that you invoiced the items to.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ToolTip = 'Specifies the date when the sales order was invoiced.';
                }
                field("Order Date"; "Order Date")
                {
                    ToolTip = 'Specifies the date on which the related sales order was created.';
                }
                field("Document Date"; "Document Date")
                {
                    ToolTip = 'Specifies the date on which you created the sales document.';
                }
                field("External Document No."; "External Document No.")
                {
                    ToolTip = 'Specifies the number that the customer uses in their own system to refer to this sales document. You can fill this field to use it later to search for sales lines using the customer''s order number.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the salesperson that is assigned to the order.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ToolTip = 'Specifies the currency of amounts on the sales document. By default, the field is filled with the value in the Currency Code field on the customer card.';

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", "Posting Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter);
                            CurrPage.Update;
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field(Status; Status)
                {
                    ToolTip = 'Specifies the status of the document.';
                }
            }
            part(SalesLines; "Sales Order Invoice Subform")
            {
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ToolTip = 'Specifies the number of the customer that the invoice is sent to.';

                    trigger OnValidate()
                    begin
                        BilltoCustomerNoOnAfterValidat;
                    end;
                }
                field("Bill-to Name"; "Bill-to Name")
                {
                    ToolTip = 'Specifies the name of the customer that the items are shipped to.';
                }
                field("Bill-to Address"; "Bill-to Address")
                {
                    ToolTip = 'Specifies the address of the customer that the invoice is sent to.';
                }
                field("Bill-to Address 2"; "Bill-to Address 2")
                {
                    ToolTip = 'Specifies an additional part of the address of the customer that the invoice is sent to.';
                }
                field("Bill-to City"; "Bill-to City")
                {
                    ToolTip = 'Specifies the city of the customer that the invoice is sent to.';
                }
                field("Bill-to County"; "Bill-to County")
                {
                    Caption = 'State / ZIP Code';
                    ToolTip = 'Specifies the state or province code, and postal code, as a part of the address.';
                }
                field("Bill-to Post Code"; "Bill-to Post Code")
                {
                    ToolTip = 'Specifies the post code of the of the customer that the invoice is sent to.';
                }
                field("Bill-to Contact"; "Bill-to Contact")
                {
                    ToolTip = 'Specifies the name of the contact at the customer that the invoice is sent to.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the dimension value code that the sales line is associated with.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension1CodeOnAfterV;
                    end;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the dimension value code that the sales line is associated with.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension2CodeOnAfterV;
                    end;
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount on sales documents. By default, the payment term from the customer card is entered.';
                }
                field("Due Date"; "Due Date")
                {
                    ToolTip = 'Specifies when the sales invoice must be paid';
                }
                field("Payment Discount %"; "Payment Discount %")
                {
                    ToolTip = 'Specifies the payment discount percent that is granted if the customer pays on or before the date entered in the Pmt. Discount Date field. The percentage is calculated from the Payment Terms Code field.';
                }
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ToolTip = 'Specifies the last date the customer can pay the invoice and still receive a payment discount.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ToolTip = 'Specifies how the customer must pay for products on the sales document. By default, the payment method is copied from the customer card.';
                }
                field("Tax Liable"; "Tax Liable")
                {
                    ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
                }
                field("Tax Area Code"; "Tax Area Code")
                {
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Editable = false;
                Visible = false;
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
                        SalesSetup.Get;
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
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Calculate &Invoice Discount")
                {
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;
                    ToolTip = 'Calculate the invoice discount for the entire document.';

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc;
                    end;
                }
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

                            CODEUNIT.Run(CODEUNIT::"Invoice-Post (Yes/No)", Rec);
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

                            CODEUNIT.Run(CODEUNIT::"Invoice-Post + Print", Rec);
                        end;
                    end;
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord;
        exit(ConfirmDeletion);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Responsibility Center" := UserMgt.GetSalesFilter;
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
        ReportPrint: Codeunit "Test Report-Print";
        SalesSetup: Record "Sales & Receivables Setup";
        ChangeExchangeRate: Page "Change Exchange Rate";
        UserMgt: Codeunit "User Setup Management";
        Text001: Label 'There are non posted Prepayment Amounts on %1 %2.';
        Text002: Label 'There are unpaid Prepayment Invoices related to %1 %2.';

    procedure UpdateAllowed(): Boolean
    begin
        if CurrPage.Editable = false then
            Error(Text000);
        exit(true);
    end;

    local procedure ApproveCalcInvDisc()
    begin
        CurrPage.SalesLines.PAGE.ApproveCalcInvDisc;
    end;

    local procedure SelltoCustomerNoOnAfterValidat()
    begin
        CurrPage.Update;
    end;

    local procedure BilltoCustomerNoOnAfterValidat()
    begin
        CurrPage.Update;
    end;

    local procedure ShortcutDimension1CodeOnAfterV()
    begin
        CurrPage.SalesLines.PAGE.UpdateForm(true);
    end;

    local procedure ShortcutDimension2CodeOnAfterV()
    begin
        CurrPage.SalesLines.PAGE.UpdateForm(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxStatistics(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
    end;
}

