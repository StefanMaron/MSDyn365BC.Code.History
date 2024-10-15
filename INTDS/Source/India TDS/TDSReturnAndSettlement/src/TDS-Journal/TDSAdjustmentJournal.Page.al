page 18747 "TDS Adjustment Journal"
{
    AutoSplitKey = true;
    Caption = 'TDS Adjustment Journal';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = false;
    SourceTable = "TDS Journal Line";
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
                    ToolTip = 'Specifies the name of the tax journal batch.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        TDSJnlManagement.LookupNameTax(CurrentJnlBatchName, Rec);
                    end;

                    trigger OnValidate()
                    begin
                        TDSJnlManagement.CheckNameTax(CurrentJnlBatchName, Rec);
                        CurrentJnlBatchNameOnAfterVali();
                    end;
                }
                field("Transaction No"; TransactionNo)
                {
                    Caption = 'Transaction No';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction number of the posted entry.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TDSEntry: Record "TDS Entry";
                        TDSJnlBatch: Record "TDS Journal Batch";
                        NoSeriesMgt: Codeunit NoSeriesManagement;
                        TDSEntriesList: Page "TDS Entries";
                        DocumentNo: Code[20];
                    begin
                        TDSEntry.Reset();
                        TDSEntry.SetRange("TDS Paid", false);
                        TDSEntry.SetFilter("TDS Base Amount", '<>%1', 0);
                        if not TDSEntry.IsEmpty() then
                            TDSEntriesList.SetTableView(TDSEntry);
                        TDSEntriesList.LookupMode(true);
                        if TDSEntriesList.RunModal() = Action::LookupOK then begin
                            TDSEntriesList.GetRecord(TDSEntry);
                            TransactionNo := TDSEntry."Entry No.";
                            InsertTDSJnlLine(TransactionNo);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        InsertTDSJnlLine(TransactionNo);
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
                field("Document Date"; "Document Date")
                {
                    Visible = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the creation date of the the entry';
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document of the entry on the adjustment journal line.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies document number for the adjustment journal.';
                }
                field("Assessee Code"; "Assessee Code")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the assessee code for the entry on the journal line.';
                }
                field("TDS Section Code"; "TDS Section Code")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TDS section code for the entry on the journal line.';
                }
                field("TDS Base Amount"; "TDS Base Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total base amount including (TDS) on the adjustment journal line.';
                }
                field("TDS Base Amount Applied"; "TDS Base Amount Applied")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TDS base amount to be applied on the adjustment journal line.';
                }
                field("TDS %"; "TDS %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TDS % of the TDS entry the journal line is linked to.';
                }
                field("TDS % Applied"; "TDS % Applied")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the TDS % to be applied on the adjustment journal line.';
                }
                field("Surcharge %"; "Surcharge %")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surcharge % of the TDS entry the journal line is linked to.';
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
                    ToolTip = 'Specifies the eCess % of the TDS entry the journal line is linked to.';
                }
                field("eCESS % Applied"; "eCESS % Applied")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the eCess % to be applied on the adjustment journal line.';
                }
                field("SHE Cess %"; "SHE Cess %")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SHE Cess % of the TDS entry the journal line is linked to.';
                }
                field("SHE Cess % Applied"; "SHE Cess % Applied")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SHE Cess % to be applied on the adjustment journal line.';
                }
                field("Bal. TDS Including SHECESS"; "Bal. TDS Including SHE CESS")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the balance TDS including SHE Cess on the adjustment journal line.';
                }
                field("Debit Amount"; "Debit Amount")
                {
                    Caption = 'TDS Deducted';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the TDS deducted to be adjusted on the journal line.';
                }
                field("External Document No."; "External Document No.")
                {
                    Editable = false;
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    ToolTip = 'Displays the external document number entered in the purchase/sales document/journal bank charges Line.';
                }
                field("Account Type"; "Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the entry on the adjustment journal line to be posted to.';
                    trigger OnValidate()
                    begin
                        TDSJnlManagement.GetAccountsTax(Rec, AccName, BalAccName);
                    end;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number that the entry on the adjustment journal line to be posted to.';

                    trigger OnValidate()
                    begin
                        TDSJnlManagement.GetAccountsTax(Rec, AccName, BalAccName);
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
                    ToolTip = 'Specifies the total of amount including adjustment amount on the adjustment journal.';
                }
                field("Bal. Account Type"; "Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the balancing account type that should be used in adjustment journal line.';
                }
                field("Bal. Account No."; "Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of balancing account type to which the balancing entry on the journal line will be posted.';
                    trigger OnValidate()
                    begin
                        TDSJnlManagement.GetAccountsTax(Rec, AccName, BalAccName);
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
                    ToolTip = 'View or edit dimensions that you can assign to sales and purchase documents to distribute costs and analyze transaction history. (Alt+D)';
                    ApplicationArea = Basic, Suite;
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';

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
                ToolTip = 'View or change detailed information about the record on the document or journal line. (Shift +F7)';
                action(Card)
                {
                    Caption = 'Card';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'View or change detailed information about the record on the document or journal line. (Shift +F7)';
                    Image = EditLines;
                    RunObject = Codeunit 15;
                    ShortCutKey = 'Shift+F7';
                }
                action("Ledger E&ntries")
                {
                    Caption = 'Ledger E&ntries';
                    ToolTip = 'View the history of transactions that have been posted for the selected record. (Ctrl + F7)';
                    ApplicationArea = Basic, Suite;
                    Image = LedgerEntries;
                    RunObject = Codeunit "Gen. Jnl.-Show Entries";
                    ShortCutKey = 'Ctrl+F7';
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                ToolTip = 'Click Pay to transfer the total of the selected entries to the amount field of payment journal.';
                action("P&ost")
                {
                    Caption = 'P&ost';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books. (F9)';
                    Image = Post;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ShortCutKey = F9;

                    trigger OnAction()
                    var
                        TDSAdjPost: Codeunit "TDS Adjustment Post";
                    begin
                        TDSAdjPost.PostTaxJournal(Rec);
                        CurrentJnlBatchName := GETRANGEMAX("Journal Batch Name");
                        CurrPage.UPDATE(FALSE);
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
        TotalBalanceVisible := TRUE;
        BalanceVisible := TRUE;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine(xRec, FALSE);
        CLEAR(ShortcutDimCode);
        CLEAR(AccName);
        AfterGetCurrentRecord();
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
        FromTemplate: Enum "TDS Template Type";
    begin
        BalAccName := '';
        OpenedFromBatch := ("Journal Batch Name" <> '') AND ("Journal Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := "Journal Batch Name";
            TDSJnlManagement.OpenTaxJnl(CurrentJnlBatchName, Rec);
            exit
        end;
        TDSJnlManagement.TaxTemplateSelection(PAGE::"TDS Adjustment Journal", FromTemplate::"TDS Adjustments", Rec, JnlSelected);
        if NOT JnlSelected then
            ERROR('');
        TDSJnlManagement.OpenTaxJnl(CurrentJnlBatchName, Rec);
    end;

    var
        TDSEntry: Record "TDS Entry";
        TDSJnlManagement: Codeunit "TDS Jnl Management";
        TransactionNo: Integer;
        TotalBalance: Decimal;
        CurrentJnlBatchName: Code[10];
        ShortcutDimCode: array[8] of Code[20];
        BalAccName: Text[100];
        AccName: Text[100];
        ShowBalance: Boolean;
        ShowTotalBalance: Boolean;
        OpenedFromBatch: Boolean;
        [InDataSet]
        BalanceVisible: Boolean;
        [InDataSet]
        TotalBalanceVisible: Boolean;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SAVERECORD();
        TDSJnlManagement.SetNameTax(CurrentJnlBatchName, Rec);
        CurrPage.UPDATE(FALSE);
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        TDSJnlManagement.GetAccountsTax(Rec, AccName, BalAccName);
    end;

    local procedure InsertTDSJnlLine(TransactionNo: Integer)
    var
        GetTDSEntry: Record "TDS Entry";
        TDSJnlLine: Record "TDS Journal Line";
        TDSJnlBatch: Record "TDS Journal Batch";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DocumentNo: Code[20];
        LineNo: Integer;
    begin
        TDSJnlBatch.GET("Journal Template Name", "Journal Batch Name");
        if TDSJnlBatch."No. Series" <> '' then begin
            CLEAR(NoSeriesMgt);
            DocumentNo := NoSeriesMgt.TryGetNextNo(TDSJnlBatch."No. Series", "Posting Date");
        end;
        TDSJnlLine.LockTable();
        TDSJnlLine.SETRANGE("Journal Template Name", "Journal Template Name");
        TDSJnlLine.SETRANGE("Journal Batch Name", "Journal Batch Name");
        if TDSJnlLine.FindLast() then
            LineNo := TDSJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        GetTDSEntry.GET(TransactionNo);
        IF GetTDSEntry."TDS Base Amount" <> 0 then
            InsertTDSJnlLineWithTDSAmt(TDSJnlLine, GetTDSEntry, DocumentNo, LineNo);
        IF GetTDSEntry."Work Tax Amount" <> 0 then
            InsertTDSJnlLineWithWorkTaxAmt(TDSJnlLine, GetTDSEntry, DocumentNo, LineNo);
    end;

    local procedure InsertTDSJnlLineWithTDSAmt(TDSJnlLine: Record "TDS Journal Line"; TDSEntry: Record "TDS Entry"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        TDSJnlLine.Init();
        TDSJnlLine."Document No." := DocumentNo;
        TDSJnlLine."Journal Template Name" := "Journal Template Name";
        TDSJnlLine."Journal Batch Name" := "Journal Batch Name";
        TDSJnlLine."Line No." := LineNo;
        TDSJnlLine.Adjustment := TRUE;
        TDSJnlLine."Posting Date" := WorkDate();
        TDSJnlLine."Account Type" := TDSJnlLine."Account Type"::Vendor;
        TDSJnlLine."Account No." := TDSEntry."Vendor No.";
        TDSJnlLine."TDS Section Code" := TDSEntry.Section;
        TDSJnlLine."Document Type" := TDSEntry."Document Type";
        TDSJnlLine.Description := TDSEntry.Description;
        TDSJnlLine."Concessional Code" := TDSEntry."Concessional Code";
        TDSJnlLine."Per Contract" := TDSEntry."Per Contract";
        TDSJnlLine."Assessee Code" := TDSEntry."Assessee Code";
        TDSJnlLine."TDS Base Amount" := ABS(TDSEntry."TDS Base Amount");
        TDSJnlLine."Surcharge Base Amount" := ABS(TDSEntry."Surcharge Base Amount");
        TDSJnlLine."eCESS Base Amount" := ABS(TDSEntry."TDS Amount Including Surcharge");
        TDSJnlLine."SHE Cess Base Amount" := ABS(TDSEntry."TDS Amount Including Surcharge");
        IF TDSEntry.Adjusted THEN BEGIN
            TDSJnlLine."TDS %" := TDSEntry."Adjusted TDS %";
            TDSJnlLine."Surcharge %" := TDSEntry."Adjusted Surcharge %";
            TDSJnlLine."eCESS %" := TDSEntry."Adjusted eCESS %";
            TDSJnlLine."SHE Cess %" := TDSEntry."Adjusted SHE CESS %"
        END ELSE BEGIN
            TDSJnlLine."TDS %" := TDSEntry."TDS %";
            TDSJnlLine."Surcharge %" := TDSEntry."Surcharge %";
            TDSJnlLine."eCESS %" := TDSEntry."eCESS %";
            TDSJnlLine."SHE Cess %" := TDSEntry."SHE Cess %";
        END;
        TDSJnlLine."Debit Amount" := TDSEntry."Total TDS Including SHE CESS";
        TDSJnlLine."TDS Amount" := TDSEntry."TDS Amount";
        TDSJnlLine."Surcharge Amount" := TDSEntry."Surcharge Amount";
        TDSJnlLine."eCESS on TDS Amount" := TDSEntry."eCESS Amount";
        TDSJnlLine."SHE Cess on TDS Amount" := TDSEntry."SHE Cess Amount";
        TDSJnlLine."Bal. Account No." := TDSEntry."Account No.";
        TDSJnlLine."TDS Invoice No." := TDSEntry."Document No.";
        TDSJnlLine."TDS Transaction No." := TDSEntry."Entry No.";
        TDSJnlLine."T.A.N. No." := TDSEntry."T.A.N. No.";
        TDSJnlLine."Document Type" := TDSJnlLine."Document Type"::" ";
        TDSJnlLine."Bal. TDS Including SHE CESS" := TDSEntry."Bal. TDS Including SHE CESS";
        TDSJnlLine.Insert();
        CurrPage.Update(false);
    end;

    local procedure InsertTDSJnlLineWithWorkTaxAmt(TDSJnlLine: Record "TDS Journal Line"; TDSEntry: Record "TDS Entry"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        TDSJnlLine.Init();
        TDSJnlLine."Document No." := DocumentNo;
        TDSJnlLine."Journal Template Name" := "Journal Template Name";
        TDSJnlLine."Journal Batch Name" := "Journal Batch Name";
        TDSJnlLine."Line No." := LineNo + 10000;
        TDSJnlLine.Adjustment := TRUE;
        TDSJnlLine."Posting Date" := WorkDate();
        TDSJnlLine."Account Type" := TDSJnlLine."Account Type"::Vendor;
        TDSJnlLine."Account No." := TDSEntry."Vendor No.";
        TDSJnlLine."Document Type" := TDSEntry."Document Type";
        TDSJnlLine.Description := TDSEntry.Description;
        TDSJnlLine."TDS Section Code" := TDSEntry.Section;
        TDSJnlLine."Assessee Code" := TDSEntry."Assessee Code";
        TDSJnlLine."Work Tax Nature Of Deduction" := TDSEntry."Work Tax Nature Of Deduction";
        TDSJnlLine."Work Tax Base Amount" := ABS(TDSEntry."Work Tax Base Amount");
        IF TDSEntry.Adjusted THEN
            TDSJnlLine."Work Tax %" := TDSEntry."Adjusted Work Tax %"
        ELSE
            TDSJnlLine."Work Tax %" := TDSEntry."Work Tax %";
        TDSJnlLine."Debit Amount" := TDSEntry."Balance Work Tax Amount";
        TDSJnlLine."Work Tax Amount" := TDSEntry."Work Tax Amount";
        TDSJnlLine."Surcharge Amount" := TDSEntry."Surcharge Amount";
        TDSJnlLine."eCESS on TDS Amount" := TDSEntry."eCESS Amount";
        TDSJnlLine."SHE Cess on TDS Amount" := TDSEntry."SHE Cess Amount";
        TDSJnlLine."Bal. Account No." := TDSEntry."Work Tax Account";
        TDSJnlLine."TDS Invoice No." := TDSEntry."Document No.";
        TDSJnlLine."TDS Transaction No." := TDSEntry."Entry No.";
        TDSJnlLine."T.A.N. No." := TDSEntry."T.A.N. No.";
        TDSJnlLine."Document Type" := TDSJnlLine."Document Type"::" ";
        TDSJnlLine."Bal. TDS Including SHE CESS" := TDSEntry."Bal. TDS Including SHE CESS";
        TDSJnlLine."Work Tax" := TRUE;
        TDSJnlLine.Insert();
        CurrPage.Update(false);
    end;
}

