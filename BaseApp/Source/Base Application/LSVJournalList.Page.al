page 3010832 "LSV Journal List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'LSV Journal List';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "LSV Journal";
    SourceTableView = SORTING("No.")
                      ORDER(Ascending);
    UsageCategory = Lists;

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
                    Editable = false;
                    ToolTip = 'Specifies the journal number that identifies the collection uniquely.';
                }
                field("LSV Bank Code"; "LSV Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = LSVBankCodeEditable;
                    ToolTip = 'Specifies the code for the bank that should carry out the collection.';
                }
                field("LSV Status"; "LSV Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the LSV journal line.';
                }
                field("LSV Journal Description"; "LSV Journal Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = LSVJournalDescriptionEditable;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("No. Of Entries Plus"; "No. Of Entries Plus")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of entries for the collection.';
                }
                field("Amount Plus"; "Amount Plus")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount for the customer ledger entries for the collection.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency code for the collection entries.';
                }
                field("Credit Date"; "Credit Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the invoice amounts should be collected by the bank on this date.';
                }
                field("Collection Completed On"; "Collection Completed On")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the collection was closed.';
                }
                field("File Written On"; "File Written On")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the collection file was generated for the first time.';
                }
                field("Collection Completed By"; "Collection Completed By")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the user who closed the collection is stored in this field.';
                }
                field("DebitDirect Orderno."; "DebitDirect Orderno.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the DebitDirect Orderno., which identifies the collection uniquely.';
                }
                field("Partner Type"; "Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the LSV collection is a person or company.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Journal")
            {
                Caption = '&Journal';
                action("LSV Journal Line")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV Journal Line';
                    Image = ListPage;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "LSV Journal";
                    RunPageLink = "LSV Journal No." = FIELD("No.");
                    ToolTip = 'Open the related LSV journal line.';
                }
                action("C&ollected Cust. Ledg. Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ollected Cust. Ledg. Entries';
                    Image = CustomerLedger;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Customer Ledger Entries";
                    RunPageLink = "LSV No." = FIELD("No.");
                    RunPageView = SORTING("LSV No.");
                    ToolTip = 'View customer ledger entries that represent LSV collections.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                action(LSVSuggestCollection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&LSV Suggest Collection';
                    Image = SuggestCustomerPayments;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Transfers open invoices to the LSV Journal. Customer entries are only suggested in CHF and EUR. Only invoices from customers that have a payment method code that matches the code entered in the LSV Payment Method Code field in the LSV Setup window are considered.';

                    trigger OnAction()
                    begin
                        Clear(LSVCollectSuggestion);
                        LSVCollectSuggestion.SetGlobals("No.");
                        LSVCollectSuggestion.RunModal;
                    end;
                }
                action("P&rint Journal")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&rint Journal';
                    Image = Print;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'View the journal contents in a report.';

                    trigger OnAction()
                    begin
                        Clear(LSVCollectionJournal);
                        LsvJournalLine.Reset();
                        LsvJournalLine.SetRange("LSV Journal No.", "No.");
                        LsvJournalLine.FindFirst;
                        LSVCollectionJournal.SetGlobals(LsvJournalLine);
                        LSVCollectionJournal.RunModal;
                    end;
                }
                action(LSVCloseCollection)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV &Close Collection';
                    Image = ReleaseDoc;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Complete the payment collection.';

                    trigger OnAction()
                    begin
                        Clear(LsvCloseCollection);
                        LsvCloseCollection.SetGlobals(Rec);
                        LsvCloseCollection.RunModal;
                        Clear(LsvCloseCollection);
                    end;
                }
                separator(Action103)
                {
                }
                action("Modify &Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Modify &Posting Date';
                    Image = ChangeDate;
                    ToolTip = 'Change one or more posting dates in the journal.';

                    trigger OnAction()
                    begin
                        LsvJournalLine.Reset();
                        LsvJournalLine.SetRange("LSV Journal No.", "No.");
                        LsvJournalLine.FindFirst;
                        LsvMgt.ModifyPostingDate(LsvJournalLine);
                    end;
                }
                action("LSV Re&open Collection")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV Re&open Collection';
                    Image = ReOpen;
                    ToolTip = 'Reopen the payment collection. You can only reopen the collection if you have not yet submitted the LSV+ file to the bank.';

                    trigger OnAction()
                    begin
                        LsvMgt.ReopenJournal(Rec);
                    end;
                }
                separator(Action105)
                {
                }
                action(WriteLSVFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Write LSV File';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Export the LSV payment collection file.';

                    trigger OnAction()
                    begin
                        Clear(WriteLSVFile);
                        WriteLSVFile.SetGlobals(Rec);
                        WriteLSVFile.RunModal;
                    end;
                }
                action("&Send LSV File")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Send LSV File';
                    Image = Web;
                    ToolTip = 'Submit the LSV payment collection file to the bank.';

                    trigger OnAction()
                    begin
                        LsvSetup.Get("LSV Bank Code");
                        LsvSetup.TestField("LSV Bank Transfer Hyperlink");
                        HyperLink(LsvSetup."LSV Bank Transfer Hyperlink");
                    end;
                }
                separator(Action108)
                {
                }
                action(WriteDebitDirectFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Write &Debit Direct File';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Export the Direct Debit payment collection file.';

                    trigger OnAction()
                    begin
                        Clear(WriteDebitDirect);
                        WriteDebitDirect.SetGlobals("No.");
                        WriteDebitDirect.RunModal;
                    end;
                }
                action("Start &Yellownet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start &Yellownet';
                    Image = Web;
                    ToolTip = 'Transfer the debit direct file via YellowNet.';

                    trigger OnAction()
                    begin
                        LsvSetup.Get("LSV Bank Code");
                        LsvSetup.TestField("Yellownet Home Page");
                        HyperLink(LsvSetup."Yellownet Home Page");
                    end;
                }
                separator(Action1150000)
                {
                }
                action(WriteSEPAFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Write SEPA File';
                    Image = Export;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Export the SEPA Direct Debit payment collection file.';

                    trigger OnAction()
                    begin
                        CreateDirectDebitFile;
                    end;
                }
            }
            group("&Print")
            {
                Caption = '&Print';
                action("LSV &Collection Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV &Collection Order';
                    Image = "Report";
                    ToolTip = 'Open the related collection order.';

                    trigger OnAction()
                    begin
                        LsvJournal.SetRange("No.", "No.");
                        REPORT.RunModal(REPORT::"LSV Collection Order", true, false, LsvJournal);
                    end;
                }
                action("LSV Collection &Advice")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV Collection &Advice';
                    Image = "Report";
                    ToolTip = 'View the summarized payments for each customer from the current journal.';

                    trigger OnAction()
                    begin
                        Clear(LsvCollectionAdvice);
                        LsvCollectionAdvice.DefineJournalName(Rec);
                        LsvCollectionAdvice.RunModal;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        xRec := Rec;
        LSVJournalDescriptionEditable := true;
        LSVBankCodeEditable := true;

        if "LSV Status" = "LSV Status"::Released then
            LSVJournalDescriptionEditable := false;
        if "No. Of Entries Plus" > 0 then
            LSVBankCodeEditable := false;
    end;

    trigger OnInit()
    begin
        LSVBankCodeEditable := true;
        LSVJournalDescriptionEditable := true;
    end;

    var
        LsvSetup: Record "LSV Setup";
        LsvJournal: Record "LSV Journal";
        LsvJournalLine: Record "LSV Journal Line";
        LsvCollectionAdvice: Report "LSV Collection Advice";
        LSVCollectSuggestion: Report "LSV Suggest Collection";
        LSVCollectionJournal: Report "LSV Collection Journal";
        LsvCloseCollection: Report "LSV Close Collection";
        WriteLSVFile: Report "Write LSV File";
        WriteDebitDirect: Report "LSV Write DebitDirect File";
        LsvMgt: Codeunit LSVMgt;
        [InDataSet]
        LSVJournalDescriptionEditable: Boolean;
        [InDataSet]
        LSVBankCodeEditable: Boolean;
}

