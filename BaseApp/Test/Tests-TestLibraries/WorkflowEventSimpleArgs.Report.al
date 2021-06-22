report 134300 "Workflow Event Simple Args"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            RequestFilterFields = "Buy-from Vendor No.", "Document Date", Amount;
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document Type" = FIELD("Document Type"), "Buy-from Vendor No." = FIELD("Buy-from Vendor No."), "Document No." = FIELD("No.");
                RequestFilterFields = Type, "No.", "Unit Cost";
            }
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
}

