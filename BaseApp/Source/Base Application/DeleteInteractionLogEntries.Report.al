report 5190 "Delete Interaction Log Entries"
{
    Caption = 'Delete Interaction Log Entries';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Interaction Log Entry"; "Interaction Log Entry")
        {
            DataItemTableView = SORTING(Canceled, "Campaign No.", "Campaign Entry No.", Date) WHERE(Canceled = CONST(true));
            RequestFilterFields = "Entry No.", "Contact No.", Date, "Campaign No.", "Interaction Group Code", "Interaction Template Code", "Salesperson Code";

            trigger OnAfterGetRecord()
            var
                SalesHeader: Record "Sales Header";
                PurchHeader: Record "Purchase Header";
            begin
                NoOfInteractions := NoOfInteractions + 1;

                if "Version No." <> 0 then
                    case "Document Type" of
                        "Document Type"::"Sales Qte.":
                            SetSalesDocInteraction("Interaction Log Entry", SalesHeader."Document Type"::Quote);
                        "Document Type"::"Sales Ord. Cnfrmn.":
                            SetSalesDocInteraction("Interaction Log Entry", SalesHeader."Document Type"::Order);
                        "Document Type"::"Sales Blnkt. Ord":
                            SetSalesDocInteraction("Interaction Log Entry", SalesHeader."Document Type"::"Blanket Order");
                        "Document Type"::"Purch.Qte.":
                            SetPurchDocInteraction("Interaction Log Entry", PurchHeader."Document Type"::Quote);
                        "Document Type"::"Purch. Ord.":
                            SetPurchDocInteraction("Interaction Log Entry", PurchHeader."Document Type"::Order);
                        "Document Type"::"Purch. Blnkt. Ord.":
                            SetPurchDocInteraction("Interaction Log Entry", PurchHeader."Document Type"::"Blanket Order");
                    end;
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
        Message(Text000, NoOfInteractions, "Interaction Log Entry".TableCaption());
    end;

    var
        Text000: Label '%1 %2 has been deleted.';
        NoOfInteractions: Integer;

    local procedure SetPurchDocInteraction(InteractionLogEntry: Record "Interaction Log Entry"; DocumentType: Enum "Purchase Document Type")
    var
        PurchHeader: Record "Purchase Header";
        PurchHeaderArchive: Record "Purchase Header Archive";
    begin
        with InteractionLogEntry do begin
            PurchHeaderArchive.Get(DocumentType, "Document No.", "Doc. No. Occurrence", "Version No.");
            PurchHeader.SetRange("Document Type", DocumentType);
            PurchHeader.SetRange("No.", "Document No.");
            PurchHeader.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
            if not PurchHeader.IsEmpty() then begin
                PurchHeaderArchive."Interaction Exist" := false;
                PurchHeaderArchive.Modify();
            end else
                PurchHeaderArchive.Delete(true);
        end;
    end;

    local procedure SetSalesDocInteraction(InteractionLogEntry: Record "Interaction Log Entry"; DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        with InteractionLogEntry do begin
            SalesHeaderArchive.Get(DocumentType, "Document No.", "Doc. No. Occurrence", "Version No.");
            SalesHeader.SetRange("Document Type", DocumentType);
            SalesHeader.SetRange("No.", "Document No.");
            SalesHeader.SetRange("Doc. No. Occurrence", "Doc. No. Occurrence");
            if not SalesHeader.IsEmpty() then begin
                SalesHeaderArchive."Interaction Exist" := false;
                SalesHeaderArchive.Modify();
            end else
                SalesHeaderArchive.Delete(true);
        end;
    end;
}

