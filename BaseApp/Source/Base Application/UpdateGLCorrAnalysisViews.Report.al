report 14941 "Update G/L Corr.Analysis Views"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Update G/L Corr.Analysis Views';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("G/L Corr. Analysis View"; "G/L Corr. Analysis View")
        {
            DataItemTableView = SORTING(Code);
            RequestFilterFields = "Code";

            trigger OnAfterGetRecord()
            begin
                if not Blocked then
                    UpdateGLCorrAnalysisView.Update("G/L Corr. Analysis View", true)
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
        UpdateGLCorrAnalysisView: Codeunit "Update G/L Corr. Analysis View";
        BlockedOccured: Boolean;
        Text000: Label 'One or more of the selected G/L Corr. Analysis Views is Blocked, and could not be updated.';
        Text001: Label 'All selected G/L Corr. Analysis Views were updated successfully.';
}

