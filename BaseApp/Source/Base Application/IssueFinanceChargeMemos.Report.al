report 193 "Issue Finance Charge Memos"
{
    Caption = 'Issue Finance Charge Memos';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Finance Charge Memo Header"; "Finance Charge Memo Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Finance Charge Memo';

            trigger OnAfterGetRecord()
            var
                InvoiceRoundingAmount: Decimal;
            begin
                InvoiceRoundingAmount := GetInvoiceRoundingAmount();
                if InvoiceRoundingAmount <> 0 then
                    if not ConfirmManagement.GetResponse(ProceedOnIssuingWithInvRoundingQst, false) then
                        CurrReport.Break();

                RecordNo := RecordNo + 1;
                Clear(FinChrgMemoIssue);
                FinChrgMemoIssue.Set("Finance Charge Memo Header", ReplacePostingDate, PostingDateReq);
                FinChrgMemoIssue.SetJournal(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                if NoOfRecords = 1 then begin
                    FinChrgMemoIssue.Run;
                    Mark := false;
                end else begin
                    NewDateTime := CurrentDateTime;
                    if (NewDateTime - OldDateTime > 100) or (NewDateTime < OldDateTime) then begin
                        NewProgress := Round(RecordNo / NoOfRecords * 100, 1);
                        if NewProgress <> OldProgress then begin
                            Window.Update(1, NewProgress * 100);
                            OldProgress := NewProgress;
                        end;
                        OldDateTime := CurrentDateTime;
                    end;
                    Mark := not FinChrgMemoIssue.Run;
                end;

                if (PrintDoc <> PrintDoc::" ") and not Mark then begin
                    FinChrgMemoIssue.GetIssuedFinChrgMemo(IssuedFinChrgMemoHeader);
                    TempIssuedFinChrgMemoHeader := IssuedFinChrgMemoHeader;
                    TempIssuedFinChrgMemoHeader.Insert;
                end;
            end;

            trigger OnPostDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                Window.Close;
                Commit;
                if PrintDoc <> PrintDoc::" " then
                    if TempIssuedFinChrgMemoHeader.FindSet then
                        repeat
                            IssuedFinChrgMemoHeader := TempIssuedFinChrgMemoHeader;
                            IsHandled := false;
                            OnBeforePrintRecords(IssuedFinChrgMemoHeader, IsHandled);
                            if not IsHandled then begin
                                IssuedFinChrgMemoHeader.SetRecFilter;
                                IssuedFinChrgMemoHeader.PrintRecords(false, PrintDoc = PrintDoc::Email, HideDialog);
                            end;
                        until TempIssuedFinChrgMemoHeader.Next = 0;
                MarkedOnly := true;
                if FindFirst then
                    if ConfirmManagement.GetResponse(Text003, true) then
                        PAGE.RunModal(0, "Finance Charge Memo Header");
            end;

            trigger OnPreDataItem()
            begin
                if ReplacePostingDate and (PostingDateReq = 0D) then
                    Error(Text000);
                NoOfRecords := Count;
                if NoOfRecords = 1 then
                    Window.Open(Text001)
                else begin
                    Window.Open(Text002);
                    OldDateTime := CurrentDateTime;
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintDoc; PrintDoc)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Print';
                        ToolTip = 'Specifies if you want the program to print the finance charge memos when they are issued.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the finance charge memos'' posting date with the date entered in the field below.';
                    }
                    field(PostingDateReq; PostingDateReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date. If you place a check mark in the check box above, the program will use this date on all finance charge memos when you post.';
                    }
                    field(HideEmailDialog; HideDialog)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Hide Email Dialog';
                        ToolTip = 'Specifies if you want to hide email dialog.';
                    }
                    field(JnlTemplateName; GenJnlLine."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';

                        trigger OnValidate()
                        begin
                            GenJnlLine."Journal Batch Name" := '';
                        end;
                    }
                    field(JnlBatchName; GenJnlLine."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;
                        ToolTip = 'Specifies the name of the journal batch that is used for the posting.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJournalTemplate.Get(GenJnlLine."Journal Template Name");
                            GenJnlBatch.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                            GenJnlBatch."Journal Template Name" := GenJnlLine."Journal Template Name";
                            GenJnlBatch.Name := GenJnlLine."Journal Batch Name";
                            if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then
                                GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLine."Journal Batch Name" <> '' then begin
                                GenJnlLine.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                            end;
                        end;
                    }
                    label(Control1010000)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Text19067972;
                        ShowCaption = false;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Text000: Label 'Enter the posting date.';
        Text001: Label 'Issuing finance charge memo...';
        Text002: Label 'Issuing finance charge memos @1@@@@@@@@@@@@@';
        Text003: Label 'It was not possible to issue some of the selected finance charge memos.\Do you want to see these finance charge memos?';
        Text19067972: Label 'When posting Interest or Additional Fees:';
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        IssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header";
        TempIssuedFinChrgMemoHeader: Record "Issued Fin. Charge Memo Header" temporary;
        FinChrgMemoIssue: Codeunit "FinChrgMemo-Issue";
        ConfirmManagement: Codeunit "Confirm Management";
        Window: Dialog;
        NoOfRecords: Integer;
        RecordNo: Integer;
        NewProgress: Integer;
        OldProgress: Integer;
        NewDateTime: DateTime;
        OldDateTime: DateTime;
        PostingDateReq: Date;
        ReplacePostingDate: Boolean;
        PrintDoc: Option " ",Print,Email;
        HideDialog: Boolean;
        ProceedOnIssuingWithInvRoundingQst: Label 'The invoice rounding amount will be added to the finance charge memo when it is posted according to invoice rounding setup.\Do you want to continue?';

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; var IsHandled: Boolean)
    begin
    end;
}

