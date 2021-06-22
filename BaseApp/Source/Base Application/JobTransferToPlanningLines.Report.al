report 1091 "Job Transfer To Planning Lines"
{
    Caption = 'Job Transfer To Planning Lines';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(TransferTo; LineType)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Transfer To';
                        OptionCaption = 'Budget,Billable,Both Budget and Billable';
                        ToolTip = 'Specifies the type of planning lines that should be created.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        JobCalcBatches.TransferToPlanningLine(JobLedgEntry, LineType + 1);
    end;

    var
        JobLedgEntry: Record "Job Ledger Entry";
        JobCalcBatches: Codeunit "Job Calculate Batches";
        LineType: Option Budget,Billable,"Both Budget and Billable";

    procedure GetJobLedgEntry(var JobLedgEntry2: Record "Job Ledger Entry")
    begin
        JobLedgEntry.Copy(JobLedgEntry2);
    end;
}

