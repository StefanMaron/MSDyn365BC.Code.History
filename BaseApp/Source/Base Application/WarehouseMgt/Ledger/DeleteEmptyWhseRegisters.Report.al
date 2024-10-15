namespace Microsoft.Warehouse.Ledger;

using System.Utilities;

report 7399 "Delete Empty Whse. Registers"
{
    Caption = 'Delete Empty Whse. Registers';
    Permissions = TableData "Warehouse Register" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Warehouse Register"; "Warehouse Register")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "Creation Date";

            trigger OnAfterGetRecord()
            begin
                WhseEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
                if WhseEntry.FindFirst() then
                    CurrReport.Skip();
                Window.Update(1, "No.");
                Window.Update(2, "Creation Date");
                Delete();
                NoOfDeleted := NoOfDeleted + 1;
                Window.Update(3, NoOfDeleted);
                if NoOfDeleted >= NoOfDeleted2 + 10 then begin
                    NoOfDeleted2 := NoOfDeleted;
                    Commit();
                end;
            end;

            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if not SkipConfirm then
                    if not ConfirmManagement.GetResponseOrDefault(DeleteRegistersQst, true) then
                        CurrReport.Break();

                Window.Open(
                  Text001 +
                  Text002 +
                  Text003 +
                  Text004);
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
        WhseEntry: Record "Warehouse Entry";
        Window: Dialog;
        NoOfDeleted: Integer;
        NoOfDeleted2: Integer;
        SkipConfirm: Boolean;

        DeleteRegistersQst: Label 'Do you want to delete the registers?';
        Text001: Label 'Deleting empty whse. registers...\\';
        Text002: Label 'No.                      #1######\';
        Text003: Label 'Registered on            #2######\\';
        Text004: Label 'No. of registers deleted #3######';

    procedure SetSkipConfirm()
    begin
        SkipConfirm := true;
    end;
}

