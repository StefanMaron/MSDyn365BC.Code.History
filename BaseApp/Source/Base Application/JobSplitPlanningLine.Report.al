report 1088 "Job Split Planning Line"
{
    ApplicationArea = Jobs;
    Caption = 'Job Split Planning Line';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Job Task"; "Job Task")
        {
            DataItemTableView = SORTING("Job No.", "Job Task No.");
            RequestFilterFields = "Job No.", "Job Task No.", "Planning Date Filter";

            trigger OnAfterGetRecord()
            begin
                Clear(CalcBatches);
                NoOfLinesSplit += CalcBatches.SplitLines("Job Task");
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
        if NoOfLinesSplit <> 0 then begin
            Message(Text000, NoOfLinesSplit);
        end else
            Message(Text001);
    end;

    trigger OnPreReport()
    begin
        NoOfLinesSplit := 0;
    end;

    var
        CalcBatches: Codeunit "Job Calculate Batches";
        NoOfLinesSplit: Integer;
        Text000: Label '%1 planning line(s) successfully split.';
        Text001: Label 'There were no planning lines to split.';
}

