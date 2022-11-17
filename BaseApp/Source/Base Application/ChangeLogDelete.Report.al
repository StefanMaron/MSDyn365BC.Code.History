#if not CLEAN22
report 510 "Change Log - Delete"
{
    Caption = 'Change Log - Delete';
    Permissions = TableData "Change Log Entry" = rid;
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'The functionality has been replaced with the retention policy module in system application.';
    ObsoleteTag = '17.0';

    dataset
    {
        dataitem("Change Log Entry"; "Change Log Entry")
        {
            DataItemTableView = SORTING("Table No.", "Primary Key Field 1 Value");
            RequestFilterFields = "Date and Time", "Table No.";

            trigger OnPostDataItem()
            begin
                TryDeleteProtectedRecords();
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Protected, false);
                SetRange("Field Log Entry Feature", "Field Log Entry Feature"::"Change Log");
                DeleteAll();
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if "Change Log Entry".GetFilter("Date and Time") = '' then
                "Change Log Entry".SetFilter("Date and Time", '..%1', CreateDateTime(CalcDate('<-1Y>', Today), 0T));
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            ChangeLogEntry: Record "Change Log Entry";
            ConfirmManagement: Codeunit "Confirm Management";
        begin
            if CloseAction = ACTION::Cancel then
                exit(true);
            if "Change Log Entry".GetFilter("Date and Time") <> '' then begin
                ChangeLogEntry.CopyFilters("Change Log Entry");
                if not ChangeLogEntry.FindLast() then
                    Error(NothingToDeleteErr);
                if DT2Date(ChangeLogEntry."Date and Time") > CalcDate('<-1Y>', Today) then
                    if not ConfirmManagement.GetResponse(Text002, false) then
                        exit(false);
            end else
                if not ConfirmManagement.GetResponse(Text001, false) then
                    exit(false);
            exit(true);
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not GuiAllowed then
            exit;
        Window.Close();
        if not TempErrorMessage.IsEmpty() then begin
            if ConfirmManagement.GetResponse(SomeEntriesNotDeletedQst, true) then
                PAGE.RunModal(PAGE::"Error Messages", TempErrorMessage);
        end else
            Message(DeletedMsg);
    end;

    trigger OnPreReport()
    begin
        if GuiAllowed then
            Window.Open(DialogMsg);
    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        Window: Dialog;
        DialogMsg: Label 'Entries are being deleted...\\@1@@@@@@@@@@@@';
        CounterTotal: Integer;
        Counter: Integer;
        Text001: Label 'You have not defined a date filter. Do you want to continue?';
        Text002: Label 'Your date filter allows deletion of entries that are less than one year old. Do you want to continue?';
        NothingToDeleteErr: Label 'There are no entries within the filter.';
        DeletedMsg: Label 'The selected entries were deleted.';
        SomeEntriesNotDeletedQst: Label 'One or more entries cannot be deleted.\\Do you want to open the list of errors?';

    local procedure TryDeleteProtectedRecords()
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        ChangeLogEntry.CopyFilters("Change Log Entry");
        ChangeLogEntry.SetRange(Protected, true);
        CounterTotal := ChangeLogEntry.Count();
        if ChangeLogEntry.FindSet(true) then
            repeat
                Counter += 1;
                if GuiAllowed then
                    Window.Update(1, Round(Counter / CounterTotal * 10000, 1));
                Commit();
#pragma warning disable AL0432
                if not CODEUNIT.Run(CODEUNIT::"Change Log Entry - Delete", ChangeLogEntry) then
#pragma warning restore AL0432
                    TempErrorMessage.LogLastError();
            until ChangeLogEntry.Next() = 0;
    end;
}
#endif