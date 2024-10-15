namespace Microsoft.Sales.FinanceCharge;

report 186 "Update Finance Charge Text"
{
    Caption = 'Update Finance Charge Text';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Finance Charge Memo Header"; "Finance Charge Memo Header")
        {
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            begin
                FinChrgMemoHeader.UpdateLines("Finance Charge Memo Header");
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
        FinChrgMemoHeader: Record "Finance Charge Memo Header";
}

