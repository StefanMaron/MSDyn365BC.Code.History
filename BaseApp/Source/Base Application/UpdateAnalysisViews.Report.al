report 84 "Update Analysis Views"
{
    ApplicationArea = Dimensions;
    Caption = 'Update Analysis Views';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Analysis View"; "Analysis View")
        {
            DataItemTableView = SORTING(Code);
            RequestFilterFields = "Code";

            trigger OnAfterGetRecord()
            begin
                if not Blocked then
                    UpdateAnalysisView.Update("Analysis View", 2, true)
                else
                    BlockedOccured := true;
            end;

            trigger OnPostDataItem()
            begin
                if BlockedOccured then
                    Message(Text000)
                else
                    Message(Text001);
            end;

            trigger OnPreDataItem()
            begin
                LockTable();
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
        UpdateAnalysisView: Codeunit "Update Analysis View";
        Text000: Label 'One or more of the selected Analysis Views is Blocked, and could not be updated.';
        BlockedOccured: Boolean;
        Text001: Label 'All selected Analysis Views were updated successfully.';
}

