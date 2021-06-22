report 5178 "Delete Purchase Order Versions"
{
    Caption = 'Delete Archived Purchase Order Versions';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header Archive"; "Purchase Header Archive")
        {
            DataItemTableView = SORTING("Document Type", "No.", "Doc. No. Occurrence", "Version No.") WHERE("Document Type" = CONST(Order), "Interaction Exist" = CONST(false));
            RequestFilterFields = "No.", "Date Archived", "Buy-from Vendor No.";

            trigger OnAfterGetRecord()
            var
                PurchHeader: Record "Purchase Header";
            begin
                PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
                PurchHeader.SetRange("No.", "No.");
                PurchHeader.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                if not PurchHeader.FindFirst then begin
                    Delete(true);
                    DeletedDocuments += 1;
                end;
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

    trigger OnInitReport()
    begin
        DeletedDocuments := 0;
    end;

    trigger OnPostReport()
    begin
        Message(Text000, DeletedDocuments);
    end;

    var
        Text000: Label '%1 archived versions deleted.', Comment = '%1=Count of deleted documents';
        DeletedDocuments: Integer;
}

