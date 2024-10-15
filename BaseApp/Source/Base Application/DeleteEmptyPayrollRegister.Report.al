report 17417 "Delete Empty Payroll Register"
{
    Caption = 'Delete Empty Payroll Register';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Payroll Register"; "Payroll Register")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "Creation Date";

            trigger OnAfterGetRecord()
            begin
                PayLedgEntry.SetRange("Entry No.", "From Entry No.", "To Entry No.");
                if PayLedgEntry.FindFirst then
                    CurrReport.Skip();
                Window.Update(1, "No.");
                Window.Update(2, "Creation Date");
                Delete;
                NoOfDeleted := NoOfDeleted + 1;
                Window.Update(3, NoOfDeleted);
                if NoOfDeleted >= NoOfDeleted2 + 10 then begin
                    NoOfDeleted2 := NoOfDeleted;
                    Commit();
                end;
            end;

            trigger OnPreDataItem()
            begin
                if not Confirm(Text000, false) then
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
        PayLedgEntry: Record "Payroll Ledger Entry";
        Window: Dialog;
        NoOfDeleted: Integer;
        NoOfDeleted2: Integer;
        Text000: Label 'Do you want to delete the registers?';
        Text001: Label 'Deleting payroll registers...\\';
        Text002: Label 'No.                      #1######\';
        Text003: Label 'Posted on                #2######\\';
        Text004: Label 'No. of registers deleted #3######';
}

