report 189 "Suggest Reminder Lines"
{
    Caption = 'Suggest Reminder Lines';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Reminder Header"; "Reminder Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Reminder';

            trigger OnAfterGetRecord()
            begin
                RecordNo := RecordNo + 1;
                Clear(MakeReminder);
                MakeReminder.SuggestLines("Reminder Header", CustLedgEntry, OverdueEntriesOnly, IncludeEntriesOnHold, CustLedgEntryLineFeeOn);
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
                Commit();
                Window.Close;
                MarkedOnly := true;
                if FindFirst then
                    if ConfirmManagement.GetResponse(Text002, true) then
                        PAGE.RunModal(0, "Reminder Header");
            end;

            trigger OnPreDataItem()
            begin
                NoOfRecords := Count;
                if NoOfRecords = 1 then
                    Window.Open(Text000)
                else begin
                    Window.Open(Text001);
                    OldDateTime := CurrentDateTime;
                end;
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
                        ToolTip = 'Specifies if the batch job will also insert overdue open entries that are on hold.';
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

    trigger OnPreReport()
    begin
        CustLedgEntry.Copy(CustLedgEntry2)
    end;

    var
        Text000: Label 'Suggesting lines...';
        Text001: Label 'Suggesting lines @1@@@@@@@@@@@@@';
        Text002: Label 'It was not possible to process some of the selected reminders.\Do you want to see these reminders?';
        CustLedgEntry: Record "Cust. Ledger Entry";
        MakeReminder: Codeunit "Reminder-Make";
        Window: Dialog;
        NoOfRecords: Integer;
        RecordNo: Integer;
        NewProgress: Integer;
        OldProgress: Integer;
        NewDateTime: DateTime;
        OldDateTime: DateTime;
        OverdueEntriesOnly: Boolean;
        IncludeEntriesOnHold: Boolean;
}

