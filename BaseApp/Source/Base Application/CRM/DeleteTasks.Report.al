report 5188 "Delete Tasks"
{
    Caption = 'Delete Tasks';
    ProcessingOnly = true;

    dataset
    {
        dataitem("To-do"; "To-do")
        {
            DataItemTableView = WHERE(Canceled = CONST(true), "System To-do Type" = FILTER(Organizer | Team));
            RequestFilterFields = "No.", Date, "Salesperson Code", "Team Code", "Campaign No.", "Contact No.";

            trigger OnAfterGetRecord()
            begin
                if ("Team Code" = '') or ("System To-do Type" = "System To-do Type"::Team) then
                    Delete(true)
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
}

