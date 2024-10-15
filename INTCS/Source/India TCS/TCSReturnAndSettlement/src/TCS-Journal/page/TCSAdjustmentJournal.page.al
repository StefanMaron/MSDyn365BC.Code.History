page 18870 "TCS Adjustment Journal"
{
    AutoSplitKey = true;
    Caption = 'TCS Adjustment Journal';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = false;
    SourceTable = "TCS Journal Line";
    UsageCategory = Tasks;
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Current Jnl Batch Name"; CurrentJnlBatchName)
                {
                    Caption = 'Batch Name';
                    Lookup = true;
                    Visible = true;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the current journal batch';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        TCSAdjustment.LookupNameTCS(CurrentJnlBatchName, Rec);
                    end;

                    trigger OnValidate()
                    begin
                        TCSAdjustment.CheckNameTCS(CurrentJnlBatchName, Rec);
                        CurrentJnlBatchNameOnAfterVali();
                    end;
                }
                field("Transaction No"; TransactionNo)
                {
                    BlankZero = true;
                    Caption = 'Transaction No';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction number that the TCS entry is linked to.';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TCSEntry: Record "TCS Entry";
                    begin
                        TCSEntry.Reset();
                        TCSEntry.SetRange("TCS Paid", false);
                        TCSEntry.SetFilter("TCS Amount", '<>%1', 0);
                        if not TCSEntry.IsEmpty() then
                            if Page.runmodal(Page::"TCS Entries", TCSEntry) = Action::LookupOK then
                                TransactionNo := TCSEntry."Entry No.";
                        InsertTCSAdjJnlOnTransactionNo();
                    end;

                    trigger OnValidate()
                    var
                    begin
                        InsertTCSAdjJnlOnTransactionNo();
                    end;
                }
            }
            repeater(Line)
            {
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that the entry on the adjustment journal line is.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies document number for the adjustment journal line.';
                }
                field("Assessee Code"; "Assessee Code")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the assessee code of the entry on the adjustment journal line.';
                }
                field("TCS Base Amount"; "TCS Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total base amount including (TCS) on the adjustment journal line.';
                }
                field("TCS %"; "TCS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TCS % of the TCS entry the journal line is linked to.';
                }
                field("TCS % Applied"; "TCS % Applied")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TCS % to be applied on the adjustment journal line.';
                }
                field("Surcharge %"; "Surcharge %")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surcharge % of the TCS entry the journal line is linked to.';
                }
                field("Surcharge % Applied"; "Surcharge % Applied")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surcharge % to be applied on the adjustment journal line.';
                }
                field("eCESS %"; "eCESS %")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the eCess % of the TCS entry the journal line is linked to.';
                }
                field("eCESS % Applied"; "eCESS % Applied")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the eCess % to be applied on the adjustment journal line.';
                }
                field("SHE Cess % on TCS"; "SHE Cess % on TCS")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SHE Cess % of the TCS entry the journal line is linked to.';
                }
                field("SHE Cess % Applied"; "SHE Cess % Applied")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SHE Cess % to be applied on the adjustment journal line.';
                }
                field("TCS Base Amount Applied"; "TCS Base Amount Applied")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TCS base amount to be applied on the adjustment journal line.';
                }
                field("T.C.A.N. No."; "T.C.A.N. No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the T.C.A.N. number on the adjustment journal line.';
                }
                field("Debit Amount"; "Debit Amount")
                {
                    Caption = 'TCS Collected';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the TCS collected to be adjusted on the adjustment journal line.';
                }
                field("External Document No."; "External Document No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Specifies the external document number that the TCS entry is linked to.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the entry on the adjustment journal line to be posted to.';

                    trigger OnValidate()
                    begin
                        TCSAdjustment.GetAccountsTCS(Rec, AccName, BalAccName);
                    end;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number that the entry on the adjustment journal line to be posted to.';

                    trigger OnValidate()
                    begin
                        TCSAdjustment.GetAccountsTCS(Rec, AccName, BalAccName);
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description on adjustment journal line to be adjusted.';
                }
                field(Amount; Amount)
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of amount including adjustment on the adjustment journal to be posted to.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the balancing account type that should be used in adjustment journal line.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of balancing account type to which the balancing entry for the journal line will be posted.';

                    trigger OnValidate()
                    begin
                        TCSAdjustment.GetAccountsTCS(Rec, AccName, BalAccName);
                        ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    Caption = 'Dimensions';
                    ApplicationArea = Basic, Suite;
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions that you can be assigned to sales and purchase documents to distribute costs and analyze transaction history (Alt+D).';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                        CurrPage.SAVERECORD();
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Card)
                {
                    Caption = 'Card';
                    ApplicationArea = Basic, Suite;
                    Image = EditLines;
                    RunObject = Codeunit "Gen. Jnl.-Show Card";
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line (Shift +F7).';
                }
                action("Ledger E&ntries")
                {
                    Caption = 'Ledger E&ntries';
                    Image = LedgerEntries;
                    ApplicationArea = Basic, Suite;
                    RunObject = Codeunit 14;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record (Ctrl + F7).';
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    Caption = 'P&ost';
                    ApplicationArea = Basic, Suite;
                    Image = Post;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedOnly = true;
                    PromotedIsBig = true;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books (F9).';
                    trigger OnAction()
                    var
                        TCSTCSJnlManagement: Codeunit "Post-TCS Jnl. Line";
                    begin
                        TCSTCSJnlManagement.PostTCSJournal(Rec);
                        CurrentJnlBatchName := GetRANGEMAX("Journal Batch Name");
                        CurrPage.Update(False);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ShowShortcutDimCode(ShortcutDimCode);
        AfterGetCurrentRecord();
    end;

    trigger OnInit()
    begin
        TotalBalanceVisible := True;
        BalanceVisible := True;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine(xRec, Balance, False);
        Clear(ShortcutDimCode);
        Clear(AccName);
        AfterGetCurrentRecord();
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        BalAccName := '';
        OpenedFromBatch := ("Journal Batch Name" <> '') and ("Journal Template Name" = '');
        if OpenedFromBatch then Begin
            CurrentJnlBatchName := "Journal Batch Name";
            TCSAdjustment.OpenTCSJnl(CurrentJnlBatchName, Rec);
            Exit;
        end;
        TCSAdjustment.TCSTemplateSelection(Page::"TCS Adjustment Journal", Rec, JnlSelected);
        if Not JnlSelected then
            Error('');
        TCSAdjustment.OpenTCSJnl(CurrentJnlBatchName, Rec);
    end;

    var
        TCSAdjustment: Codeunit "TCS Adjustment";
        Balance: Decimal;
        TransactionNo: Integer;
        CurrentJnlBatchName: Code[10];
        ShortcutDimCode: array[8] of Code[20];
        BalAccName: Text[100];
        AccName: Text[100];
        OpenedFromBatch: Boolean;
        BalanceVisible: Boolean;
        TotalBalanceVisible: Boolean;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SAVERECORD();
        TCSAdjustment.SetNameTCS(CurrentJnlBatchName, Rec);
        CurrPage.Update(False);
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        TCSAdjustment.GetAccountsTCS(Rec, AccName, BalAccName);
    end;

    local procedure GetDocumentNo(): Code[20]
    var
        TCSJnlBatch: Record "TCS Journal Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        TCSJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        if TCSJnlBatch."No. Series" <> '' then begin
            Clear(NoSeriesMgt);
            exit(NoSeriesMgt.TryGetNextNo(TCSJnlBatch."No. Series", "Posting Date"));
        end;
    end;

    local procedure GetTCSJnlLineNo(): Integer
    var
        TCSJnlLine: Record "TCS Journal Line";
    begin
        TCSJnlLine.LOCKTABLE();
        TCSJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        TCSJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if TCSJnlLine.FindLast() then
            exit(TCSJnlLine."Line No." + 10000)
        else
            exit(10000);
    end;

    local procedure InsertTCSAdjJnlOnTransactionNo()
    var
        TCSJnlLine: Record "TCS Journal Line";
        TCSEntry: Record "TCS Entry";
    begin
        TCSEntry.Get(TransactionNo);
        TCSJnlLine.Init();
        TCSJnlLine."Document No." := GetDocumentNo();
        TCSJnlLine."Journal Template Name" := "Journal Template Name";
        TCSJnlLine."Journal Batch Name" := "Journal Batch Name";
        TCSJnlLine."Line No." := GetTCSJnlLineNo();
        TCSJnlLine.Adjustment := True;
        TCSJnlLine."Posting Date" := WORKDATE();
        TCSJnlLine."Account Type" := TCSJnlLine."Account Type"::Customer;
        TCSJnlLine.VALIDATE("Account No.", TCSEntry."Customer No.");
        TCSJnlLine."Document Type" := TCSEntry."Document Type";
        TCSJnlLine.Description := TCSEntry.Description;
        TCSJnlLine."TCS Nature of Collection" := TCSEntry."TCS Nature of Collection";
        TCSJnlLine."Assessee Code" := TCSEntry."Assessee Code";
        TCSJnlLine."TCS Base Amount" := ABS(TCSEntry."TCS Base Amount");
        TCSJnlLine."Surcharge Base Amount" := ABS(TCSEntry."Surcharge Base Amount");
        TCSJnlLine."eCESS Base Amount" := ABS(TCSEntry."TCS Amount Including Surcharge");
        TCSJnlLine."SHE Cess Base Amount" := ABS(TCSEntry."TCS Amount Including Surcharge");
        if TCSEntry.Adjusted then begin
            TCSJnlLine."TCS %" := TCSEntry."Adjusted TCS %";
            TCSJnlLine."Surcharge %" := TCSEntry."Adjusted Surcharge %";
            TCSJnlLine."eCESS %" := TCSEntry."Adjusted eCESS %";
            TCSJnlLine."SHE Cess % on TCS" := TCSEntry."Adjusted SHE CESS %";
        end
        else begin
            TCSJnlLine."TCS %" := TCSEntry."TCS %";
            TCSJnlLine."Surcharge %" := TCSEntry."Surcharge %";
            TCSJnlLine."eCESS %" := TCSEntry."eCESS %";
            TCSJnlLine."SHE Cess % on TCS" := TCSEntry."SHE Cess %";
        end;
        TCSJnlLine."Debit Amount" := TCSEntry."Total TCS Including SHE CESS";
        TCSJnlLine."TCS Amount" := TCSEntry."TCS Amount";
        TCSJnlLine."Surcharge Amount" := TCSEntry."Surcharge Amount";
        TCSJnlLine."eCESS on TCS Amount" := TCSEntry."eCESS Amount";
        TCSJnlLine."SHE Cess on TCS Amount" := TCSEntry."SHE Cess Amount";
        TCSJnlLine."Bal. Account No." := TCSEntry."Account No.";
        TCSJnlLine."TCS Invoice No." := TCSEntry."Document No.";
        TCSJnlLine."TCS Transaction No." := TCSEntry."Entry No.";
        TCSJnlLine."T.C.A.N. No." := TCSEntry."T.C.A.N. No.";
        TCSJnlLine."Document Type" := TCSJnlLine."Document Type"::" ";
        TCSJnlLine.Insert();
        CurrPage.Update(false);
    end;
}