page 1028 "Job WIP Totals"
{
    Caption = 'Job WIP Totals';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Job WIP Total";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Job Task No."; "Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the job task that is associated with the job WIP total. The job task number is generally the final task in a group of tasks that is set to Total or the last job task line.';
                }
                field("WIP Method"; "WIP Method")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the work in process (WIP) calculation method that is associated with a job. The value in the field comes from the WIP method specified on the job card.';
                }
                field("WIP Posting Date"; "WIP Posting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date when work in process (WIP) was last calculated and entered in the Job WIP Entries window.';
                }
                field("WIP Warnings"; "WIP Warnings")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if there are WIP warnings associated with a job for which you have calculated WIP.';
                }
                field("Schedule (Total Cost)"; "Schedule (Total Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total of the budgeted costs for the job.';
                }
                field("Schedule (Total Price)"; "Schedule (Total Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total of the budgeted prices for the job.';
                }
                field("Usage (Total Cost)"; "Usage (Total Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies job usage in relation to total cost up to the date of the last job WIP calculation.';
                }
                field("Usage (Total Price)"; "Usage (Total Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies job usage in relation to total price up to the date of the last job WIP calculation.';
                }
                field("Contract (Total Cost)"; "Contract (Total Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the value of the billable in relation to total cost up to the date of the last job WIP calculation.';
                }
                field("Contract (Total Price)"; "Contract (Total Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the value of the billable in relation to the total price up to the date of the last job WIP calculation.';
                }
                field("Contract (Invoiced Price)"; "Contract (Invoiced Price)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price amount that has been invoiced and posted in relation to the billable for the current WIP calculation.';
                }
                field("Contract (Invoiced Cost)"; "Contract (Invoiced Cost)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost amount that has been invoiced and posted in relation to the billable for the current WIP calculation.';
                }
                field("Calc. Recog. Sales Amount"; "Calc. Recog. Sales Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the calculated sum of recognized sales amounts in the current WIP calculation.';
                }
                field("Calc. Recog. Costs Amount"; "Calc. Recog. Costs Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the calculated sum of recognized costs amounts in the current WIP calculation.';
                }
                field("Cost Completion %"; "Cost Completion %")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost completion percentage for job tasks that have been budgeted in the current WIP calculation.';
                }
                field("Invoiced %"; "Invoiced %")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the percentage of contracted job tasks that have been invoiced in the current WIP calculation.';
                }
            }
        }
    }

    actions
    {
    }
}

