page 144 "Posted Sales Credit Memos"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Sales Credit Memos';
    CardPageID = "Posted Sales Credit Memo";
    Editable = false;
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Credit Memo,Cancel,Navigate,Print/Send';
    QueryCategory = 'Posted Sales Credit Memos';
    SourceTable = "Sales Cr.Memo Header";
    SourceTableView = SORTING("Posting Date")
                      ORDER(Descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer.';
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies the name of the customer that you shipped the items on the credit memo to.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code of the credit memo.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the shipment is due for payment.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the amounts on all the credit memo lines, in the currency of the credit memo. The amount does not include VAT.';

                    trigger OnDrillDown()
                    begin
                        DoDrillDown;
                    end;
                }
                field("Amount Including VAT"; "Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the amounts, including VAT, on all the lines on the document.';

                    trigger OnDrillDown()
                    begin
                        DoDrillDown;
                    end;
                }
                field("Remaining Amount"; "Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that remains to be paid for the posted sales invoice.';
                }
                field(Paid; Paid)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the posted sales invoice that relates to this sales credit memo is paid.';
                }
                field(Cancelled; Cancelled)
                {
                    ApplicationArea = Basic, Suite;
                    HideValue = NOT Cancelled;
                    Style = Unfavorable;
                    StyleExpr = Cancelled;
                    ToolTip = 'Specifies if the posted sales invoice that relates to this sales credit memo has been either corrected or canceled.';

                    trigger OnDrillDown()
                    begin
                        ShowCorrectiveInvoice;
                    end;
                }
                field(Corrective; Corrective)
                {
                    ApplicationArea = Basic, Suite;
                    HideValue = NOT Corrective;
                    Style = Unfavorable;
                    StyleExpr = Corrective;
                    ToolTip = 'Specifies if the posted sales invoice has been either corrected or canceled by this sales credit memo.';

                    trigger OnDrillDown()
                    begin
                        ShowCancelledInvoice;
                    end;
                }
                field("Sell-to Post Code"; "Sell-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the customer''s main address.';
                    Visible = false;
                }
                field("Sell-to Country/Region Code"; "Sell-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the customer''s main address.';
                    Visible = false;
                }
                field("Sell-to Contact"; "Sell-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the customer''s main address.';
                    Visible = false;
                }
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Bill-to Name"; "Bill-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Bill-to Post Code"; "Bill-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    Visible = false;
                }
                field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the customer''s billing address.';
                    Visible = false;
                }
                field("Bill-to Contact"; "Bill-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                    Visible = false;
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Ship-to Name"; "Ship-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Post Code"; "Ship-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Contact"; "Ship-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the credit memo was posted.';
                    Visible = false;
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which salesperson is associated with the credit memo.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location where the credit memo was registered.';
                }
                field("Electronic Document Status"; "Electronic Document Status")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Date/Time Stamped"; "Date/Time Stamped")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document received a digital stamp from the authorized service provider.';
                    Visible = false;
                }
                field("Date/Time Sent"; "Date/Time Sent")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document was sent to the customer.';
                    Visible = false;
                }
                field("Date/Time Canceled"; "Date/Time Canceled")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document was canceled.';
                    Visible = false;
                }
                field("Error Code"; "Error Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the error code that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("Error Description"; "Error Description")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the error message that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    Visible = false;
                }
                field("Document Exchange Status"; "Document Exchange Status")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = DocExchStatusStyle;
                    ToolTip = 'Specifies the status of the document if you are using a document exchange service to send it as an electronic document. The status values are reported by the document exchange service.';
                    Visible = DocExchStatusVisible;

                    trigger OnDrillDown()
                    var
                        DocExchServDocStatus: Codeunit "Doc. Exch. Serv.- Doc. Status";
                    begin
                        DocExchServDocStatus.DocExchStatusDrillDown(Rec);
                    end;
                }
            }
        }
        area(factboxes)
        {
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                Visible = NOT IsOfficeAddin;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Electronic Document")
            {
                Caption = '&Electronic Document';
                action("S&end")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'S&end';
                    Ellipsis = true;
                    Image = SendTo;
                    ToolTip = 'Send an email to the customer with the electronic credit memo attached as an XML file.';

                    trigger OnAction()
                    var
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                        ProgressWindow: Dialog;
                    begin
                        CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                        ProgressWindow.Open(ProcessingInvoiceMsg);
                        if SalesCrMemoHeader.FindSet then begin
                            repeat
                                SalesCrMemoHeader.RequestStampEDocument;
                                ProgressWindow.Update(1, SalesCrMemoHeader."No.");
                            until SalesCrMemoHeader.Next() = 0;
                        end;
                        ProgressWindow.Close;
                    end;
                }
                action("Export E-Document as &XML")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Export E-Document as &XML';
                    Image = ExportElectronicDocument;
                    ToolTip = 'Export the posted sales credit memo as an electronic credit memo, an XML file, and save it to a specified location.';

                    trigger OnAction()
                    begin
                        ExportEDocument;
                    end;
                }
                action(ExportEDocumentPDF)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Export E-Document as PDF';
                    Image = ExportToBank;
                    ToolTip = 'Export the posted sales credit memo as an electronic credit memo, a PDF document, when the stamp is received.';

                    trigger OnAction()
                    begin
                        ExportEDocumentPDF();
                    end;
                }
                action(CFDIRelationDocuments)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'CFDI Relation Documents';
                    Image = Allocations;
                    RunObject = Page "CFDI Relation Documents";
                    RunPageLink = "Document Table ID" = CONST(114),
                                  "Document No." = FIELD("No."),
                                  "Customer No." = FIELD("Bill-to Customer No.");
                    RunPageMode = View;
                    ToolTip = 'View or add CFDI relation documents for the record.';
                }
                action("&Cancel")
                {
                    ApplicationArea = BasicMX;
                    Caption = '&Cancel';
                    Image = Cancel;
                    ToolTip = 'Cancel the sending of the electronic credit memo invoice.';

                    trigger OnAction()
                    var
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                        ProgressWindow: Dialog;
                    begin
                        CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                        ProgressWindow.Open(ProcessingInvoiceMsg);
                        if SalesCrMemoHeader.FindSet then begin
                            repeat
                                SalesCrMemoHeader.CancelEDocument;
                                ProgressWindow.Update(1, SalesCrMemoHeader."No.");
                            until SalesCrMemoHeader.Next() = 0;
                        end;
                        ProgressWindow.Close;
                    end;
                }
            }
            group("&Credit Memo")
            {
                Caption = '&Credit Memo';
                Image = CreditMemo;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the posted sales credit memo.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"Posted Sales Credit Memo", Rec)
                    end;
                }
                action(Statistics)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        OnBeforeCalculateSalesTaxStatistics(Rec);
                        if "Tax Area Code" = '' then
                            PAGE.RunModal(PAGE::"Sales Credit Memo Statistics", Rec, "No.")
                        else
                            PAGE.RunModal(PAGE::"Sales Credit Memo Stats.", Rec, "No.");
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Posted Credit Memo"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
                action(IncomingDoc)
                {
                    AccessByPermission = TableData "Incoming Document" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Incoming Document';
                    Image = Document;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'View or create an incoming document record that is linked to the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocument: Record "Incoming Document";
                    begin
                        IncomingDocument.ShowCard("No.", "Posting Date");
                    end;
                }
                action(Customer)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Image = Customer;
                    Promoted = true;
                    PromotedCategory = Category6;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = FIELD("Sell-to Customer No.");
                    Scope = Repeater;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the customer.';
                }
                action("&Navigate")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                    Visible = NOT IsOfficeAddin;

                    trigger OnAction()
                    begin
                        Navigate;
                    end;
                }
            }
            group(Cancel)
            {
                Caption = 'Cancel';
                action(CancelCrMemo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel';
                    Image = Cancel;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'Create and post a sales invoice that reverses this posted sales credit memo. This posted sales credit memo will be canceled.';
                    Visible = not Cancelled and Corrective;

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Cancel PstdSalesCrM (Yes/No)", Rec);
                    end;
                }
                action(ShowInvoice)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Canceled/Corrective Invoice';
                    Image = Invoice;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'Open the posted sales invoice that was created when you canceled the posted sales credit memo. If the posted sales credit memo is the result of a canceled sales invoice, then canceled invoice will open.';
                    Visible = Cancelled OR Corrective;

                    trigger OnAction()
                    begin
                        ShowCanceledOrCorrInvoice;
                    end;
                }
            }
            action("Sales - Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales - Credit Memo';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Report "Sales Credit Memo NA";
                ToolTip = 'View all sales credit memos. You can print on pre-printed credit memo forms, generic forms or on plain paper. The unit price quoted on this form is the direct price adjusted by any line discounts or other adjustments.';
            }
        }
        area(reporting)
        {
            action("Outstanding Sales Order Aging")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Outstanding Sales Order Aging';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Outstanding Sales Order Aging";
                ToolTip = 'View customer orders aged by their target shipping date. Only orders that have not been shipped appear on the report.';
            }
            action("Outstanding Sales Order Status")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Outstanding Sales Order Status';
                Image = "Report";
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Report "Outstanding Sales Order Status";
                ToolTip = 'View detailed outstanding order information for each customer. This report includes shipping information, quantities ordered, and the amount that is back ordered.';
            }
            action("Daily Invoicing Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Daily Invoicing Report';
                Image = "Report";
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Daily Invoicing Report";
                ToolTip = 'View the total invoice or credit memo activity, or both. This report can be run for a particular day, or range of dates. The report shows one line for each invoice or credit memo. You can view the bill-to customer number, name, payment terms, salesperson code, amount, sales tax, amount including tax, and total of all invoices or credit memos.';
            }
            group(Send)
            {
                Caption = 'Send';
                action(SendCustom)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send';
                    Ellipsis = true;
                    Image = SendToMultiple;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'Prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens where you can confirm or select a sending profile.';

                    trigger OnAction()
                    var
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    begin
                        SalesCrMemoHeader := Rec;
                        CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                        SalesCrMemoHeader.SendRecords;
                    end;
                }
                action("&Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Print';
                    Ellipsis = true;
                    Image = Print;
                    Promoted = true;
                    PromotedCategory = Category7;
                    Scope = Repeater;
                    ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';
                    Visible = NOT IsOfficeAddin;

                    trigger OnAction()
                    var
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    begin
                        SalesCrMemoHeader := Rec;
                        CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                        OnBeforePrintRecords(SalesCrMemoHeader);
                        SalesCrMemoHeader.PrintRecords(true);
                    end;
                }
                action("Send by &Email")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send by &Email';
                    Image = Email;
                    Scope = Repeater;
                    ToolTip = 'Prepare to send the document by email. The Send Email window opens prefilled for the customer where you can add or change information before you send the email.';

                    trigger OnAction()
                    var
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    begin
                        SalesCrMemoHeader := Rec;
                        CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                        SalesCrMemoHeader.EmailRecords(true);
                    end;
                }
                action(AttachAsPDF)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attach as PDF';
                    Image = PrintAttachment;
                    Promoted = true;
                    PromotedCategory = Category7;
                    ToolTip = 'Create a PDF file and attach it to the document.';

                    trigger OnAction()
                    var
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    begin
                        SalesCrMemoHeader := Rec;
                        CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                        PrintToDocumentAttachment(SalesCrMemoHeader);
                    end;
                }
            }
            action(ActivityLog)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Activity Log';
                Image = Log;
                ToolTip = 'View the status and any errors if the document was sent as an electronic document or OCR file through the document exchange service.';

                trigger OnAction()
                begin
                    ShowActivityLog;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        if DocExchStatusVisible then
            DocExchStatusStyle := GetDocExchStatusStyle;
    end;

    trigger OnOpenPage()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OfficeMgt: Codeunit "Office Management";
        HasFilters: Boolean;
    begin
        HasFilters := GetFilters <> '';
        SetSecurityFilterOnRespCenter;
        if HasFilters and not Find() then
            if FindFirst then;
        IsOfficeAddin := OfficeMgt.IsAvailable;
        SalesCrMemoHeader.CopyFilters(Rec);
        SalesCrMemoHeader.SetFilter("Document Exchange Status", '<>%1', "Document Exchange Status"::"Not Sent");
        DocExchStatusVisible := not SalesCrMemoHeader.IsEmpty;
    end;

    local procedure DoDrillDown()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Copy(Rec);
        SalesCrMemoHeader.SetRange("No.");
        PAGE.Run(PAGE::"Posted Sales Credit Memo", SalesCrMemoHeader);
    end;

    var
        DocExchStatusStyle: Text;
        DocExchStatusVisible: Boolean;
        IsOfficeAddin: Boolean;
        ProcessingInvoiceMsg: Label 'Processing record #1#######', Comment = '%1 = Record no';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxStatistics(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;
}

