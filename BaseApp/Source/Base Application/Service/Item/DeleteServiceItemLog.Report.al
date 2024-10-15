namespace Microsoft.Service.Item;

using System.Utilities;

report 6010 "Delete Service Item Log"
{
    Caption = 'Delete Service Item Log';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Service Item Log"; "Service Item Log")
        {
            DataItemTableView = sorting("Change Date");
            RequestFilterFields = "Change Date", "Service Item No.";

            trigger OnPostDataItem()
            begin
                if CounterTotal > 1 then
                    Message(Text004, CounterTotal)
                else
                    Message(Text005, CounterTotal);
            end;

            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                CounterTotal := Count;
                if CounterTotal = 0 then begin
                    Message(Text000);
                    CurrReport.Break();
                end;
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(Text001, CounterTotal, TableCaption), true)
                then
                    Error(Text003);

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
    }

    labels
    {
    }

    var
        Text000: Label 'There is nothing to delete.';
        Text001: Label '%1 %2 records will be deleted.\\Do you want to continue?', Comment = '10 Service Item Log  record(s) will be deleted.\\Do you want to continue?';
        Text003: Label 'No records were deleted.';
        Text004: Label '%1 records were deleted.';
        Text005: Label '%1 record was deleted.';
        CounterTotal: Integer;
}

