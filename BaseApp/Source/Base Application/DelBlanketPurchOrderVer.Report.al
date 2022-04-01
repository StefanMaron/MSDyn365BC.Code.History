#if not CLEAN19
report 5173 "Del. Blanket Purch. Order Ver."
{
    Caption = 'Delete Archived Blanket Purchase Order Versions';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';
    ObsoleteReason = 'Please use the retention policy module to clean up document archive records instead.';

    dataset
    {
        dataitem("Purchase Header Archive"; "Purchase Header Archive")
        {
            DataItemTableView = SORTING("Document Type", "No.", "Doc. No. Occurrence", "Version No.") WHERE("Document Type" = CONST("Blanket Order"), "Interaction Exist" = CONST(false));
            RequestFilterFields = "No.", "Date Archived", "Buy-from Vendor No.";

            trigger OnAfterGetRecord()
            var
                PurchHeader: Record "Purchase Header";
            begin
                PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::"Blanket Order");
                PurchHeader.SetRange("No.", "No.");
                PurchHeader.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                if not PurchHeader.FindFirst() then
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