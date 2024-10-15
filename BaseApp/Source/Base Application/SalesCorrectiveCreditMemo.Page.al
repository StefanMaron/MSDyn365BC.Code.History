page 14973 "Sales Corrective Credit Memo"
{
    Caption = 'Sales Corrective Credit Memo';
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Approve,Release,Posting,Prepare,Invoice,Request Approval';
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = WHERE("Document Type" = FILTER("Credit Memo"),
                            "Corrective Document" = FILTER(true));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("Sell-to Contact No."; "Sell-to Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the contact person at the customer''s main address.';
                }
                field("Sell-to Customer Name"; "Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Sell-to Address"; "Sell-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the main address of the customer.';
                }
                field("Sell-to Address 2"; "Sell-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the address.';
                }
                field("Sell-to Post Code"; "Sell-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sell-to Post Code/City';
                    ToolTip = 'Specifies the post code or city of the address that the customer''s primary address.';
                }
                field("Sell-to City"; "Sell-to City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the customer''s main address.';
                }
                field("Sell-to Contact"; "Sell-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the customer''s main address.';
                }
                field("Posting Description"; "Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the salesperson who is assigned to the customer.';

                    trigger OnValidate()
                    begin
                        CurrPage.SalesLines.PAGE.UpdateForm(true);
                    end;
                }
                field("Campaign No."; "Campaign No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the campaign the journal line is linked to.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the record.';
                }
            }
            part(SalesLines; "Sales Corr. Cr. Memo Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("Bill-to Contact No."; "Bill-to Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
                }
                field("Bill-to Name"; "Bill-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                }
                field("Bill-to Address"; "Bill-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the customer to whom you will send the credit memo.';
                }
                field("Bill-to Address 2"; "Bill-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional line of the address.';
                }
                field("Bill-to Post Code"; "Bill-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bill-to Post Code/City';
                    ToolTip = 'Specifies the post code or city of the address that the invoice will be sent to.';
                }
                field("Bill-to City"; "Bill-to City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the address.';
                }
                field("Bill-to Contact"; "Bill-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        CurrPage.SalesLines.PAGE.UpdateForm(true);
                    end;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        CurrPage.SalesLines.PAGE.UpdateForm(true);
                    end;
                }
                field("Payment Terms Code"; "Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Payment Discount %"; "Payment Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment discount percent granted if payment is made on or before the date in the Pmt. Discount Date field.';
                }
                field("Pmt. Discount Date"; "Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
                }
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("Prices Including VAT"; "Prices Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Agreement No."; "Agreement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the agreement number associated with the sales header.';
                }
                field(Correction; Correction)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry as a corrective entry. You can use the field if you need to post a corrective entry to an account.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Name"; "Ship-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                }
                field("Ship-to Address"; "Ship-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address that the items are shipped to.';
                }
                field("Ship-to Address 2"; "Ship-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                }
                field("Ship-to Post Code"; "Ship-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ship-to Post Code/City';
                    ToolTip = 'Specifies the post code or city of the address that address that the items are shipped to.';
                }
                field("Ship-to City"; "Ship-to City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the address that the items are shipped to.';
                }
                field("Ship-to Contact"; "Ship-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                }
                field("Consignor No."; "Consignor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the party who consigned the transportation.';
                }
                field("KPP Code"; "KPP Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the company registration associated with the sales header.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warehouse or other place where the involved items are handled or stored.';
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';

                    trigger OnAssistEdit()
                    begin
                        Clear(ChangeExchangeRate);
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", "Posting Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter);
                            CurrPage.Update;
                        end;
                        Clear(ChangeExchangeRate);
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.SalesLines.PAGE.UpdateForm(true);
                    end;
                }
                field("EU 3-Party Trade"; "EU 3-Party Trade")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
                }
                field("Transaction Type"; "Transaction Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Specification"; "Transaction Specification")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
                }
                field("Transport Method"; "Transport Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                }
                field("Exit Point"; "Exit Point")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the point of exit through which you ship the items out of your country/region, for reporting to Intrastat.';
                }
                field("Area"; Area)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
                }
            }
            group(Application)
            {
                Caption = 'Application';
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; "Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to ID"; "Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                }
            }
            group(VAT)
            {
                Caption = 'VAT';
                field("Include In Purch. VAT Ledger"; "Include In Purch. VAT Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the sales header is included in the purchase VAT ledger.';
                }
                field("Additional VAT Ledger Sheet"; "Additional VAT Ledger Sheet")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional VAT ledger sheet associated with the sales header.';
                }
                field("Corrected Document Date"; "Corrected Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the corrected document associated with the sales header.';
                }
                field("Posting No."; "Posting No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Corrective Document"; "Corrective Document")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document that made the correction.';
                }
                field("Corrective Doc. Type"; "Corrective Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the document that made the correction.';
                }
                field("Corrected Doc. Type"; "Corrected Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the document that was corrected.';
                }
                field("Corrected Doc. No."; "Corrected Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document that was corrected.';
                }
                field("Revision No."; "Revision No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a revision number if this document is a revision of a corrective document.';
                }
                field("VAT Entry Type"; "VAT Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT entry code according to Russian legislation. Some types of documents, such as corrective or revision invoices, must have multiple VAT entry type codes.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1903720907; "Sales Hist. Sell-to FactBox")
            {
                SubPageLink = "No." = FIELD("Sell-to Customer No.");
                Visible = false;
            }
            part(Control1907234507; "Sales Hist. Bill-to FactBox")
            {
                SubPageLink = "No." = FIELD("Sell-to Customer No.");
                Visible = false;
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("Bill-to Customer No.");
                Visible = true;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("Sell-to Customer No.");
                Visible = true;
            }
            part(Control1906127307; "Sales Line FactBox")
            {
                Provider = SalesLines;
                SubPageLink = "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("Document No."),
                              "Line No." = FIELD("Line No.");
                Visible = false;
            }
            part(Control1906354007; "Approval FactBox")
            {
                SubPageLink = "Table ID" = CONST(36),
                              "Document Type" = FIELD("Document Type"),
                              "Document No." = FIELD("No."),
                              Status = CONST(Open);
                Visible = false;
            }
            part(Control1907012907; "Resource Details FactBox")
            {
                Provider = SalesLines;
                SubPageLink = "No." = FIELD("No.");
                Visible = false;
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
            group("&Cr. Memo")
            {
                Caption = '&Cr. Memo';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        CalcInvDiscForHeader;
                        Commit();
                        PAGE.RunModal(PAGE::"Sales Statistics", Rec);
                    end;
                }
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = FIELD("Sell-to Customer No.");
                    ShortCutKey = 'Shift+F7';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = FIELD("Document Type"),
                                  "No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;

                    trigger OnAction()
                    begin
                        ShowDocDim;
                    end;
                }
                action(Approvals)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approvals';
                    Image = Approvals;

                    trigger OnAction()
                    var
                        ApprovalEntries: Page "Approval Entries";
                    begin
                        ApprovalEntries.Setfilters(DATABASE::"Sales Header", "Document Type".AsInteger(), "No.");
                        ApprovalEntries.Run;
                    end;
                }
                separator(Action171)
                {
                }
                action("Sig&natures")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sig&natures';
                    Image = Signature;
                    RunObject = Page "Document Signatures";
                    RunPageLink = "Table ID" = CONST(36),
                                  "Document Type" = FIELD("Document Type"),
                                  "Document No." = FIELD("No.");
                    ToolTip = 'View signature information for employees and warranty.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action("Calculate &Invoice Discount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc;
                    end;
                }
                separator(Action113)
                {
                }
                action("Apply Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Entries';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+F11';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Sales Header Apply", Rec);
                    end;
                }
                separator(Action126)
                {
                }
                action("Get St&d. Cust. Sales Codes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get St&d. Cust. Sales Codes';
                    Ellipsis = true;
                    Image = CustomerCode;
                    ToolTip = 'View a list of the standard sales lines that have been assigned to the customer to be used for recurring sales.';

                    trigger OnAction()
                    var
                        StdCustSalesCode: Record "Standard Customer Sales Code";
                    begin
                        StdCustSalesCode.InsertSalesLines(Rec);
                    end;
                }
                separator(Action128)
                {
                }
                action("Copy Document")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Document';
                    Ellipsis = true;
                    Image = CopyDocument;
                    Promoted = true;
                    PromotedCategory = Process;

                    trigger OnAction()
                    begin
                        CopySalesDoc.SetSalesHeader(Rec);
                        CopySalesDoc.RunModal;
                        Clear(CopySalesDoc);
                    end;
                }
                action("Move Negative Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Negative Lines';
                    Ellipsis = true;
                    Image = MoveNegativeLines;
                    ToolTip = 'Prepare to create a replacement sales order in a sales return process.';

                    trigger OnAction()
                    begin
                        Clear(MoveNegSalesLines);
                        MoveNegSalesLines.SetSalesHeader(Rec);
                        MoveNegSalesLines.RunModal;
                        MoveNegSalesLines.ShowDocument;
                    end;
                }
                action("Get Posted Doc&ument Lines to Reverse")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Posted Doc&ument Lines to Reverse';
                    Ellipsis = true;
                    Image = ReverseLines;
                    ToolTip = 'Copy one or more posted sales document lines in order to reverse the original order.';

                    trigger OnAction()
                    begin
                        GetPstdDocLinesToRevere;
                    end;
                }
                separator(Action141)
                {
                }
                action("Re&lease")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Enable the record for the next stage of processing. ';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        ReleaseSalesDoc.PerformManualRelease(Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        ReleaseSalesDoc.PerformManualReopen(Rec);
                    end;
                }
                separator("-")
                {
                    Caption = '-';
                }
                action("Get Corr. Doc. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Get Corr. Doc. Lines';
                    Image = Line;
                    ToolTip = 'Copy one or more posted sales document lines in order to correct the original order.';

                    trigger OnAction()
                    var
                        CorrDocMgt: Codeunit "Corrective Document Mgt.";
                    begin
                        CorrDocMgt.SetSalesHeader("Document Type".AsInteger(), "No.");
                        CorrDocMgt.SelectPstdSalesDocLines;
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                action("Send A&pproval Request")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = NOT OpenApprovalEntriesExist;
                    Image = SendApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category9;
                    ToolTip = 'Request approval of the document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckSalesApprovalPossible(Rec) then
                            ApprovalsMgmt.OnSendSalesDocForApproval(Rec);
                    end;
                }
                action("Cancel Approval Re&quest")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = OpenApprovalEntriesExist;
                    Image = Cancel;
                    Promoted = true;
                    PromotedCategory = Category9;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelSalesApprovalRequest(Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintSalesHeader(Rec);
                    end;
                }
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then
                            CODEUNIT.Run(CODEUNIT::"Sales-Post (Yes/No)", Rec);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then
                            CODEUNIT.Run(CODEUNIT::"Sales-Post + Print", Rec);
                    end;
                }
                action("Post &Batch")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Batch Post Sales Credit Memos", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    DocPrint.PrintSalesHeader(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetControlAppearance;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord;
        exit(ConfirmDeletion);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Responsibility Center" := UserMgt.GetSalesFilter;
        "Corrective Document" := true;
    end;

    trigger OnOpenPage()
    begin
        if UserMgt.GetSalesFilter <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserMgt.GetSalesFilter);
            FilterGroup(0);
        end;
    end;

    var
        CopySalesDoc: Report "Copy Sales Document";
        MoveNegSalesLines: Report "Move Negative Sales Lines";
        ReportPrint: Codeunit "Test Report-Print";
        UserMgt: Codeunit "User Setup Management";
        DocPrint: Codeunit "Document-Print";
        ChangeExchangeRate: Page "Change Exchange Rate";
        OpenApprovalEntriesExist: Boolean;

    local procedure ApproveCalcInvDisc()
    begin
        CurrPage.SalesLines.PAGE.ApproveCalcInvDisc;
    end;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
    end;
}

