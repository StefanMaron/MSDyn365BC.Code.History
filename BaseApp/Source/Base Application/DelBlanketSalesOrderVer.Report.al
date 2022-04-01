#if not CLEAN19
report 5175 "Del. Blanket Sales Order Ver."
{
    Caption = 'Delete Archived Blanket Sales Order Versions';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';
    ObsoleteReason = 'Please use the retention policy module to clean up document archive records instead.';

    dataset
    {
        dataitem("Sales Header Archive"; "Sales Header Archive")
        {
            DataItemTableView = SORTING("Document Type", "No.", "Doc. No. Occurrence", "Version No.") WHERE("Document Type" = CONST("Blanket Order"), "Interaction Exist" = CONST(false));
            RequestFilterFields = "No.", "Date Archived", "Sell-to Customer No.";

            trigger OnAfterGetRecord()
            var
                SalesHeader: Record "Sales Header";
            begin
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Blanket Order");
                SalesHeader.SetRange("No.", "No.");
                SalesHeader.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                if not SalesHeader.FindFirst() then
                    Delete(true);
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

    trigger OnPostReport()
    begin
        Message(ArchivedVersionsDeletedMsg);
    end;

    var
        ArchivedVersionsDeletedMsg: Label 'Archived versions deleted.';
}
#endif