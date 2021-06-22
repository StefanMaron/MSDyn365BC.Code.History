report 1393 "Cancel Issued Reminders"
{
    AdditionalSearchTerms = 'cancel issued reminder';
    Caption = 'Cancel Issued Reminders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Issued Reminder Header"; "Issued Reminder Header")
        {
            RequestFilterFields = "No.", "Customer No.", "Posting Date";

            trigger OnAfterGetRecord()
            var
                TempErrorMessage: Record "Error Message" temporary;
                CancelIssuedReminder: Codeunit "Cancel Issued Reminder";
            begin
                CancelIssuedReminder.SetParameters(UseSameDocumentNo, UseSamePostingDate, NewPostingDate, NoOfRecords > 1);
                if CancelIssuedReminder.Run("Issued Reminder Header") then begin
                    if CancelIssuedReminder.GetErrorMessages(TempErrorMessage) then
                        AddIssuedReminderToErrorBuffer;
                    Commit();
                end else begin
                    if NoOfRecords > 1 then begin
                        TempErrorMessage.LogLastError;
                        AddIssuedReminderToErrorBuffer;
                    end else
                        Error(GetLastErrorText);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if NoOfRecords > 1 then begin
                    if not TempIssuedReminderHeader.IsEmpty then
                        AskShowNotCancelledIssuedReminders;
                end;
            end;

            trigger OnPreDataItem()
            begin
                NoOfRecords := Count;
                if NoOfRecords = 0 then
                    Error(NothingToCancelErr);

                if not UseSamePostingDate and (NewPostingDate = 0D) then
                    Error(SpecifyPostingDateErr);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(UseSameDocumentNo; UseSameDocumentNo)
                {
                    ApplicationArea = Suite;
                    Caption = 'Use Same Document No.';
                    ToolTip = 'Specifies if you want to use the same document number for corrective ledger entries. If you do not select the check box, then a document number will be assigned from the Canceled Issued Reminder Nos. number series that is defined on the Sales & Receivables Setup page.';
                }
                field(UseSamePostingDate; UseSamePostingDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Use Same Posting Date';
                    ToolTip = 'Specifies if you want to use same posting date for corrective ledger entries.';

                    trigger OnValidate()
                    begin
                        if UseSamePostingDate then
                            NewPostingDate := 0D;
                        SetEnabled;
                    end;
                }
                field(NewPostingDate; NewPostingDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'New Posting Date';
                    Enabled = NewPostingDateEnabled;
                    ToolTip = 'Specifies the new posting date for corrective ledger entries.';
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            UseSameDocumentNo := true;
            UseSamePostingDate := true;
            SetEnabled;
        end;
    }

    labels
    {
    }

    var
        TempIssuedReminderHeader: Record "Issued Reminder Header" temporary;
        NoOfRecords: Integer;
        NothingToCancelErr: Label 'There is nothing to cancel.';
        UseSameDocumentNo: Boolean;
        UseSamePostingDate: Boolean;
        NewPostingDate: Date;
        [InDataSet]
        NewPostingDateEnabled: Boolean;
        SpecifyPostingDateErr: Label 'You must specify a posting date.';
        ShowNotCancelledRemindersQst: Label 'One or more of the selected issued reminders could not be canceled.\\Do you want to see a list of the issued reminders that were not canceled?';

    local procedure SetEnabled()
    begin
        NewPostingDateEnabled := not UseSamePostingDate;
    end;

    local procedure AskShowNotCancelledIssuedReminders()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ConfirmManagement.GetResponseOrDefault(ShowNotCancelledRemindersQst, true) then
            PAGE.RunModal(PAGE::"Issued Reminder List", TempIssuedReminderHeader);
    end;

    local procedure AddIssuedReminderToErrorBuffer()
    begin
        TempIssuedReminderHeader := "Issued Reminder Header";
        TempIssuedReminderHeader.Insert();
    end;
}

