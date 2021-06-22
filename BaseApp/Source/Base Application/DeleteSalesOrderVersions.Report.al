report 5180 "Delete Sales Order Versions"
{
    Caption = 'Delete Archived Sales Order Versions';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Header Archive"; "Sales Header Archive")
        {
            DataItemTableView = SORTING("Document Type", "No.", "Doc. No. Occurrence", "Version No.") WHERE("Document Type" = CONST(Order), "Interaction Exist" = CONST(false));
            RequestFilterFields = "No.", "Date Archived", "Sell-to Customer No.";

            trigger OnAfterGetRecord()
            var
                SalesHeader: Record "Sales Header";
            begin
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                SalesHeader.SetRange("No.", "No.");
                SalesHeader.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
                if not SalesHeader.FindFirst then begin
                    Delete(true);
                    DeletedDocuments += 1;
                end;

                OnAfterGetRecordSalesHeaderArchive("Sales Header Archive", DeletedDocuments);
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

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordSalesHeaderArchive(var SalesHeaderArchive: Record "Sales Header Archive"; var DeletedDocuments: Integer)
    begin
    end;
}

