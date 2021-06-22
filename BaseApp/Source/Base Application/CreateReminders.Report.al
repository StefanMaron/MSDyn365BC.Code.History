report 188 "Create Reminders"
{
    Caption = 'Create Reminders';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                RecordNo := RecordNo + 1;
                Clear(MakeReminder);
                MakeReminder.Set(Customer, CustLedgEntry, ReminderHeaderReq, OverdueEntriesOnly, IncludeEntriesOnHold, CustLedgEntryLineFeeOn);
                if NoOfRecords = 1 then begin
                    MakeReminder.Code;
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
                    Mark := not MakeReminder.Code;
                end;
            end;

            trigger OnPostDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                Window.Close;
                MarkedOnly := true;
                Commit();
                if FindFirst then
                    if ConfirmManagement.GetResponse(Text003, true) then
                        PAGE.RunModal(0, Customer);
            end;

            trigger OnPreDataItem()
            var
                SalesSetup: Record "Sales & Receivables Setup";
            begin
                if ReminderHeaderReq."Document Date" = 0D then
                    Error(Text000, ReminderHeaderReq.FieldCaption("Document Date"));
                FilterGroup := 2;
                SetFilter("Reminder Terms Code", '<>%1', '');
                FilterGroup := 0;
                NoOfRecords := Count;
                SalesSetup.Get();
                SalesSetup.TestField("Reminder Nos.");
                if NoOfRecords = 1 then
                    Window.Open(Text001)
                else begin
                    Window.Open(Text002);
                    OldDateTime := CurrentDateTime;
                end;
                ReminderHeaderReq."Use Header Level" := UseHeaderLevel;
            end;
        }
        dataitem(CustLedgEntry2; "Cust. Ledger Entry")
        {
            DataItemTableView = SORTING("Customer No.");
            RequestFilterFields = "Document Type";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem(CustLedgEntryLineFeeOn; "Cust. Ledger Entry")
        {
            DataItemTableView = SORTING("Entry No.") ORDER(Ascending);
            RequestFilterFields = "Document Type";
            RequestFilterHeading = 'Apply Fee per Line On';

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
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
                    field("ReminderHeaderReq.""Posting Date"""; ReminderHeaderReq."Posting Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the date that will appear as the posting date on the header of the reminder that is created by the batch job.';
                    }
                    field(DocumentDate; ReminderHeaderReq."Document Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the date that will appear as the document date on the header of the reminder that is created by the batch job. This date is used for any interest calculations and to determine the due date of the reminder.';
                    }
                    field(OverdueEntriesOnly; OverdueEntriesOnly)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Entries with Overdue Amounts';
                        MultiLine = true;
                        ToolTip = 'Specifies if the batch job will only insert open entries that are overdue, meaning they have a due date earlier than the document date on the reminder header.';
                    }
                    field(IncludeEntriesOnHold; IncludeEntriesOnHold)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Entries On Hold';
                        ToolTip = 'Specifies if you want to create reminders for entries that are on hold.';
                    }
                    field(UseHeaderLevel; UseHeaderLevel)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Header Level';
                        ToolTip = 'Specifies if the batch job will apply the condition of the reminder level to all the reminder lines.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if ReminderHeaderReq."Document Date" = 0D then begin
                ReminderHeaderReq."Document Date" := WorkDate;
                ReminderHeaderReq."Posting Date" := WorkDate;
            end;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        OverdueEntriesOnly := true;
    end;

    trigger OnPostReport()
    begin
        OnBeforeOnPostReport;
    end;

    trigger OnPreReport()
    begin
        OnBeforeOnPreReport;

        CustLedgEntry.Copy(CustLedgEntry2);
        if CustLedgEntryLineFeeOnFilters.GetFilters <> '' then
            CustLedgEntryLineFeeOn.CopyFilters(CustLedgEntryLineFeeOnFilters);
    end;

    var
        Text000: Label '%1 must be specified.';
        Text001: Label 'Making reminders...';
        Text002: Label 'Making reminders @1@@@@@@@@@@@@@';
        Text003: Label 'It was not possible to create reminders for some of the selected customers.\Do you want to see these customers?';
        CustLedgEntry: Record "Cust. Ledger Entry";
        ReminderHeaderReq: Record "Reminder Header";
        CustLedgEntryLineFeeOnFilters: Record "Cust. Ledger Entry";
        MakeReminder: Codeunit "Reminder-Make";
        Window: Dialog;
        NoOfRecords: Integer;
        RecordNo: Integer;
        NewProgress: Integer;
        OldProgress: Integer;
        NewDateTime: DateTime;
        OldDateTime: DateTime;
        OverdueEntriesOnly: Boolean;
        UseHeaderLevel: Boolean;
        IncludeEntriesOnHold: Boolean;

    procedure InitializeRequest(DocumentDate: Date; PostingDate: Date; OverdueEntries: Boolean; NewUseHeaderLevel: Boolean; IncludeEntries: Boolean)
    begin
        ReminderHeaderReq."Document Date" := DocumentDate;
        ReminderHeaderReq."Posting Date" := PostingDate;
        OverdueEntriesOnly := OverdueEntries;
        UseHeaderLevel := NewUseHeaderLevel;
        IncludeEntriesOnHold := IncludeEntries;
    end;

    procedure SetApplyLineFeeOnFilters(var CustLedgEntryLineFeeOn2: Record "Cust. Ledger Entry")
    begin
        CustLedgEntryLineFeeOnFilters.CopyFilters(CustLedgEntryLineFeeOn2);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPostReport()
    begin
    end;
}

