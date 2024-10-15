page 7000009 "Bill Groups"
{
    Caption = 'Bill Groups';
    DataCaptionExpression = Caption;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Bill Group";

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
                    ToolTip = 'Specifies the number of this bill group.';

                    trigger OnAssistEdit()
                    begin
                        if AssistEdit(xRec) then
                            CurrPage.Update;
                    end;
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number or code of the bank, to which this bill group is being submitted.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        BankSel.SetCurrBillGr(Rec);
                        if ACTION::LookupOK = BankSel.RunModal then begin
                            BankSel.GetRecord(BankAcc);
                            "Dealing Type" := BankSel.IsForDiscount;
                            Clear(BankSel);
                            Validate("Bank Account No.", BankAcc."No.");
                        end else
                            Clear(BankSel);
                    end;
                }
                field("Bank Account Name"; "Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank to which this bill group is submitted.';
                }
                field("Dealing Type"; "Dealing Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of payment. Collection: The document will be sent to the bank for processing as a receivable. Discount: The document will be sent to the bank for processing as a prepayment discount. When a document is submitted for discount, the bill group bank advances the amount of the document (or a portion of it, in the case of invoices). Later, the bank is responsible for processing the collection of the document on the due date.';
                }
                field("Partner Type"; "Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the bill group is of type person or company.';
                }
                field(Factoring; Factoring)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the factoring method used for the invoices that make up this bill group.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the posting date when this bill group will be entered.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the bill group.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the sums of the documents included in the bill group.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the total amount for all of the documents included in the bill group.';
                }
            }
            part(Docs; "Docs. in BG Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = Type = CONST(Receivable),
                              "Collection Agent" = CONST(Bank),
                              "Bill Gr./Pmt. Order No." = FIELD("No.");
                SubPageView = SORTING(Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Accepted, "Due Date", Place);
            }
            group(Auditing)
            {
                Caption = 'Auditing';
                field("Reason Code"; "Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies why the entry is created. When reason codes are assigned to journal line or sales and purchase documents, all entries with a reason code will be marked during posting.';
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of copies that were printed.';
                }
            }
        }
        area(factboxes)
        {
            part("File Export Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'File Export Errors';
                Provider = Docs;
                SubPageLink = "Journal Template Name" = FILTER(''),
                              "Journal Batch Name" = FILTER('7000005'),
                              "Document No." = FIELD("Bill Gr./Pmt. Order No."),
                              "Journal Line No." = FIELD("Entry No.");
            }
            part(Control1901421207; "BG Analysis Fact Box")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("No.");
                Visible = true;
            }
            part(Control1903433307; "Bank Account Information FB")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = FIELD("Bank Account No.");
                Visible = true;
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
            group(BillGroup)
            {
                Caption = 'Bill &Group';
                Image = VoucherGroup;
                action(Comments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "BG/PO Comment Sheet";
                    RunPageLink = Type = FILTER(Receivable),
                                  "BG/PO No." = FIELD("No.");
                    ToolTip = 'View or create a comment.';
                }
                separator(Action18)
                {
                }
                action(Analysis)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis';
                    Image = "Report";
                    RunObject = Page "Bill Groups Analysis";
                    RunPageLink = "No." = FIELD("No."),
                                  "Due Date Filter" = FIELD("Due Date Filter"),
                                  "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                                  "Category Filter" = FIELD("Category Filter");
                    ToolTip = 'View details about the related documents. First you define which document category and currency you want to analyze documents for.';
                }
                separator(Action33)
                {
                }
                action(Listing)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Listing';
                    Ellipsis = true;
                    Image = List;
                    Promoted = true;
                    PromotedCategory = "Report";
                    ToolTip = 'View detailed information about the posted bill group or payment order.';

                    trigger OnAction()
                    begin
                        if Find then begin
                            BillGr.Copy(Rec);
                            BillGr.SetRecFilter;
                        end;
                        BillGr.PrintRecords(true);
                    end;
                }
            }
        }
        area(processing)
        {
            group(Posting)
            {
                Caption = 'P&osting';
                Image = Post;
                action(TestReport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'Preview the resulting entries to see the consequences before you perform the actual posting.';

                    trigger OnAction()
                    begin
                        if not Find then
                            exit;
                        BillGr.Reset();
                        BillGr := Rec;
                        BillGr.SetRecFilter;
                        REPORT.Run(REPORT::"Bill Group - Test", true, false, BillGr);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the documents to indicate that they are ready to submit to the bank for payment or collection. ';

                    trigger OnAction()
                    begin
                        if Find then
                            PostBGPO.ReceivablePostOnly(Rec);
                    end;
                }
                action(PostandPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Post and then print the documents to indicate that they are ready to submit to the bank for payment or collection.';

                    trigger OnAction()
                    begin
                        if Find then
                            PostBGPO.ReceivablePostAndPrint(Rec);
                    end;
                }
                action(ExportToFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Bill Group to File';
                    Image = ExportFile;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Export a file with the payment information on the lines.';

                    trigger OnAction()
                    begin
                        ExportToFile;
                    end;
                }
            }
            action(BillGroupsMaturity)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bill Groups Maturity';
                Image = DocumentsMaturity;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Bill Groups Maturity";
                RunPageLink = "No." = FIELD("No."),
                              "Global Dimension 1 Filter" = FIELD("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = FIELD("Global Dimension 2 Filter"),
                              "Category Filter" = FIELD("Category Filter");
                ToolTip = 'View matured bill groups.';
            }
        }
    }

    var
        BankAcc: Record "Bank Account";
        BillGr: Record "Bill Group";
        BankSel: Page "Bank Account Selection";
        PostBGPO: Codeunit "BG/PO-Post and Print";
}

