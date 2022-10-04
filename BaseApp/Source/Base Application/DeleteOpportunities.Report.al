report 5182 "Delete Opportunities"
{
    Caption = 'Delete Opportunities';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Opportunity; Opportunity)
        {
            DataItemTableView = WHERE(Closed = CONST(true));
            RequestFilterFields = "No.", "Date Closed", "Salesperson Code", "Campaign No.", "Contact No.", "Sales Cycle Code";

            trigger OnAfterGetRecord()
            begin
                RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::Opportunity);
                RMCommentLine.SetRange("No.", "No.");
                RMCommentLine.DeleteAll();

                OppEntry.SetRange("Opportunity No.", "No.");
                OppEntry.DeleteAll();

                Delete();
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
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
        OppEntry: Record "Opportunity Entry";
}

