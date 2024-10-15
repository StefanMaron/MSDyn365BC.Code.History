report 190 "Issue Reminders"
{
    Caption = 'Issue Reminders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Reminder Header"; "Reminder Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Reminder';

            trigger OnAfterGetRecord()
            var
                InvoiceRoundingAmount: Decimal;
            begin
                InvoiceRoundingAmount := GetInvoiceRoundingAmount();
                if InvoiceRoundingAmount <> 0 then
                    if not ConfirmManagement.GetResponse(ProceedOnIssuingWithInvRoundingQst, false) then
                        CurrReport.Break();

                RecordNo := RecordNo + 1;
                Clear(ReminderIssue);
                ReminderIssue.Set("Reminder Header", ReplacePostingDate, PostingDateReq);
                ReminderIssue.SetJournal(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                if NoOfRecords = 1 then begin
                    ReminderIssue.Run;
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
                    Commit();
                    Mark := not ReminderIssue.Run;
                end;

                if PrintDoc <> PrintDoc::" " then begin
                    ReminderIssue.GetIssuedReminder(IssuedReminderHeader);
                    TempIssuedReminderHeader := IssuedReminderHeader;
                    TempIssuedReminderHeader.Insert();
                end;
            end;

            trigger OnPostDataItem()
            var
                IssuedReminderHeaderPrint: Record "Issued Reminder Header";
                ConfirmManagement: Codeunit "Confirm Management";
                IsHandled: Boolean;
            begin
                Window.Close;
                Commit();
                if PrintDoc <> PrintDoc::" " then
                    if TempIssuedReminderHeader.FindSet then
                        repeat
                            IssuedReminderHeaderPrint := TempIssuedReminderHeader;
                            IsHandled := false;
                            OnBeforePrintIssuedReminderHeader(IssuedReminderHeaderPrint, IsHandled);
                            if not IsHandled then begin
                                IssuedReminderHeaderPrint.SetRecFilter;
                                IssuedReminderHeaderPrint.PrintRecords(false, PrintDoc = PrintDoc::Email, HideDialog);
                            end;
                        until TempIssuedReminderHeader.Next = 0;
                MarkedOnly := true;
                if FindFirst then
                    if ConfirmManagement.GetResponse(Text003, true) then
                        PAGE.RunModal(0, "Reminder Header");
            end;

            trigger OnPreDataItem()
            begin
                if ReplacePostingDate and (PostingDateReq = 0D) then
                    Error(Text000);
                if ReminderNoFilter <> '' then
                    SetFilter("No.", ReminderNoFilter);
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
                        Enabled = NOT IsOfficeAddin;
                        ToolTip = 'Specifies it you want to print or email the reminders when they are issued.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies if you want to replace the reminders'' posting date with the date entered in the field below.';
                    }
                    field(PostingDateReq; PostingDateReq)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date. If you place a check mark in the check box above, the program will use this date on all reminders when you post.';
                    }
                    field(HideEmailDialog; HideDialog)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Hide Email Dialog';
                        ToolTip = 'Specifies if you want to hide email dialog.';
                    }
                    field(ReminderNoFilter; ReminderNoFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reminder No. Filter';
                        ToolTip = 'Specifies a filter for the reminder numbers to issue.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ReminderList: Page "Reminder List";
                        begin
                            "Reminder Header".Reset();
                            ReminderList.LookupMode(true);
                            if not (ReminderList.RunModal = ACTION::LookupOK) then
                                exit(false);
                            Text := ReminderList.GetSelectionFilter;
                            exit(true);
                        end;
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
                    label(Control1010004)
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

        trigger OnOpenPage()
        begin
            ReminderNoFilter := '';
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        OfficeMgt: Codeunit "Office Management";
    begin
        IsOfficeAddin := OfficeMgt.IsAvailable;
        if IsOfficeAddin then
            PrintDoc := 2;
    end;

    var
        Text000: Label 'Enter the posting date.';
        Text001: Label 'Issuing reminder...';
        Text002: Label 'Issuing reminders @1@@@@@@@@@@@@@';
        Text003: Label 'It was not possible to issue some of the selected reminders.\Do you want to see these reminders?';
        IssuedReminderHeader: Record "Issued Reminder Header";
        TempIssuedReminderHeader: Record "Issued Reminder Header" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        ReminderIssue: Codeunit "Reminder-Issue";
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
        [InDataSet]
        IsOfficeAddin: Boolean;
        ReminderNoFilter: Text;
        ProceedOnIssuingWithInvRoundingQst: Label 'The invoice rounding amount will be added to the reminder when it is posted according to invoice rounding setup.\Do you want to continue?';	
        Text19067972: Label 'When posting Interest or Additional Fees:';

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintIssuedReminderHeader(var IssuedReminderHeader: Record "Issued Reminder Header"; var IsHandled: Boolean)
    begin
    end;
}

