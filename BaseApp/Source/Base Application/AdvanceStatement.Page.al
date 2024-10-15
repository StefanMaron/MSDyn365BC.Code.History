page 12431 "Advance Statement"
{
    Caption = 'Advance Statement';
    PageType = Document;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Purchase Header";
    SourceTableView = WHERE("Document Type" = FILTER(Invoice),
                            "Empl. Purchase" = CONST(true));

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
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee No.';
                    Importance = Promoted;
                    LookupPageID = "Responsible Employees";

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Buy-from Vendor Name"; "Buy-from Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee Name';
                    Importance = Promoted;
                }
                field("Advance Purpose"; "Advance Purpose")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the advance associated with the purchase header.';
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
                field("Vendor Invoice No."; "Vendor Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the original document you received from the vendor. You can require the document number for posting, or let it be optional. By default, it''s required, so that this document references the original. Making document numbers optional removes a step from the posting process. For example, if you attach the original invoice as a PDF, you might not need to enter the document number. To specify whether document numbers are required, in the Purchases & Payables Setup window, select or clear the Ext. Doc. No. Mandatory field.';
                }
                field("Prices Including VAT"; "Prices Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the record.';
                }
            }
            part(PurchLines; "Advance Statement Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Statement)
            {
                Caption = 'Statement';
                field("No. of Documents"; "No. of Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of documents associated with the purchase header.';
                }
                field("No. of Pages"; "No. of Pages")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of pages associated with the purchase header.';
                }
                field("Remaining/Overdraft Doc. No."; "Remaining/Overdraft Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the remaining or overdraft document number associated with the purchase header.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code for the record.';

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", "Posting Date");
                        if ChangeExchangeRate.RunModal = ACTION::OK then begin
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter);
                            CurrPage.Update();
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Advance")
            {
                Caption = '&Advance';
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
                        PAGE.RunModal(PAGE::"Purchase Statistics", Rec);
                    end;
                }
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Vendor Card";
                    RunPageLink = "No." = FIELD("Buy-from Vendor No.");
                    ShortCutKey = 'Shift+F7';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "Document Type" = FIELD("Document Type"),
                                  "No." = FIELD("No.");
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;

                    trigger OnAction()
                    begin
                        ShowDocDim;
                        CurrPage.Update();
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc;
                    end;
                }
                action("Copy Document")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Document';
                    Ellipsis = true;
                    Image = CopyDocument;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;

                    trigger OnAction()
                    begin
                        CopyPurchDoc.SetPurchHeader(Rec);
                        CopyPurchDoc.RunModal;
                        Clear(CopyPurchDoc);
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
                        Clear(MoveNegPurchLines);
                        MoveNegPurchLines.SetPurchHeader(Rec);
                        MoveNegPurchLines.RunModal;
                        MoveNegPurchLines.ShowDocument;
                    end;
                }
                action("Re&lease")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Codeunit "Release Purchase Document";
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Enable the record for the next stage of processing. ';
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    var
                        ReleasePurchDoc: Codeunit "Release Purchase Document";
                    begin
                        ReleasePurchDoc.Reopen(Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintPurchHeader(Rec);
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
                    begin
                        CheckAdvStmtPostingDate;
                        CODEUNIT.Run(CODEUNIT::"Purch.-Post (Yes/No)", Rec);
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
                    begin
                        CheckAdvStmtPostingDate;
                        CODEUNIT.Run(CODEUNIT::"Purch.-Post + Print", Rec);
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
                        REPORT.RunModal(REPORT::"Batch Post Purchase Invoices", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    DocPrint.PrintAdvStmt(Rec);
                end;
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord;
        exit(ConfirmDeletion);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        PurchSetup.Get();
        if "No." = '' then begin
            PurchSetup.TestField("Advance Statement Nos.");
            NoSeriesMgt.InitSeries(
              PurchSetup."Advance Statement Nos.", xRec."No. Series", "Posting Date", "No.", "No. Series");
        end;
        if "Posting No. Series" = '' then begin
            "Posting No. Series" := "No. Series";
            "Posting No." := "No.";
        end;
        if "Receiving No. Series" = '' then begin
            "Receiving No. Series" := "No. Series";
            "Receiving No." := "No.";
        end;

        if "Empl. Purchase" = true then
            "Vendor Invoice No." := "No.";
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Responsibility Center" := UserMgt.GetPurchasesFilter;
    end;

    trigger OnOpenPage()
    begin
        if UserMgt.GetPurchasesFilter <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserMgt.GetPurchasesFilter);
            FilterGroup(0);
        end;
    end;

    var
        PurchSetup: Record "Purchases & Payables Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CopyPurchDoc: Report "Copy Purchase Document";
        MoveNegPurchLines: Report "Move Negative Purchase Lines";
        ReportPrint: Codeunit "Test Report-Print";
        UserMgt: Codeunit "User Setup Management";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DocPrint: Codeunit "Document-Print";
        Text12400: Label 'Select only one application method for advance.';
        Text12401: Label 'Posting Date %1 in Advance Statement No. %2 must not be less than Posting Date in Empl. Purchase Entry No. %3.';
        ChangeExchangeRate: Page "Change Exchange Rate";

    local procedure ApproveCalcInvDisc()
    begin
        CurrPage.PurchLines.PAGE.ApproveCalcInvDisc;
    end;

    [Scope('OnPrem')]
    procedure CalculateAmounts()
    begin
        if ("Applies-to Doc. No." <> '') and ("Applies-to ID" <> '') then
            Error(Text12400);

        if "Applies-to ID" <> '' then begin
            VendLedgEntry.Reset();
            VendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
            VendLedgEntry.SetRange("Vendor No.", "Buy-from Vendor No.");
            VendLedgEntry.SetRange(Open, true);
            VendLedgEntry.SetRange(Positive, true);
            VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
            if VendLedgEntry.FindSet then
                repeat
                    if VendLedgEntry."Currency Code" = "Currency Code" then
                        VendLedgEntry.CalcFields("Remaining Amt. (LCY)");
                until VendLedgEntry.Next() = 0;
        end;

        if "Applies-to Doc. No." <> '' then begin
            VendLedgEntry.Reset();
            VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
            VendLedgEntry.SetRange("Vendor No.", "Buy-from Vendor No.");
            VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
            VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
            VendLedgEntry.CalcSums("Remaining Amt. (LCY)");
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckAdvStmtPostingDate()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        PurchHeader.Get("Document Type", "No.");
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", "Document Type");
        PurchLine.SetRange("Document No.", "No.");
        PurchLine.SetRange(Type, PurchLine.Type::"Empl. Purchase");
        if PurchLine.Find('-') then
            repeat
                if VendLedgerEntry.Get(PurchLine."Empl. Purchase Entry No.") then
                    if PurchHeader."Posting Date" < VendLedgerEntry."Posting Date" then
                        Error(Text12401, PurchHeader."Posting Date", PurchHeader."No.", VendLedgerEntry."Entry No.");
            until PurchLine.Next() = 0;
    end;
}

