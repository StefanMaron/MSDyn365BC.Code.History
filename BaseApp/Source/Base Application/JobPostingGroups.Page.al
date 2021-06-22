page 211 "Job Posting Groups"
{
    ApplicationArea = Jobs;
    Caption = 'Job Posting Groups';
    PageType = List;
    SourceTable = "Job Posting Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a code for the posting group that defines to which G/L account you post job transactions when the job card contains the job posting group.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a description of job posting groups.';
                }
                field("WIP Costs Account"; "WIP Costs Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the work in process (WIP) account for the calculated cost of the job WIP for job tasks with this posting group. The account is normally a balance sheet asset account.';
                }
                field("WIP Accrued Costs Account"; "WIP Accrued Costs Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies an account that accumulates postings when the costs recognized, based on the invoiced value of the job, are greater than the current usage total posted If the WIP method for the job is Cost Value or Cost of Sales. The account is normally a balance sheet accrued expense liability account.';
                }
                field("Job Costs Applied Account"; "Job Costs Applied Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account for WIP Cost account for jobs. The account is normally an expense (credit) account.';
                }
                field("Item Costs Applied Account"; "Item Costs Applied Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account for the WIP Costs account for items used in jobs. The account is normally an expense (credit) account.';
                }
                field("Resource Costs Applied Account"; "Resource Costs Applied Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account for the WIP Costs account for resources used in jobs. The account is normally an expense (credit) account.';
                }
                field("G/L Costs Applied Account"; "G/L Costs Applied Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account for the WIP Costs account.';
                }
                field("Job Costs Adjustment Account"; "Job Costs Adjustment Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account to WIP Accrued Costs account if the work in process (WIP) method for the job is Cost Value or Cost of Sales. The account is normally an expense account.';
                }
                field("G/L Expense Acc. (Contract)"; "G/L Expense Acc. (Contract)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the sales account to be used for general ledger expenses in job tasks with this posting group. If left empty, the G/L account entered on the planning line will be used.';
                }
                field("WIP Accrued Sales Account"; "WIP Accrued Sales Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies an account that will be posted to when the revenue that can be recognized for the job is greater than the current invoiced value for the job if the work in process (WIP) method for the job is Sales Value.';
                }
                field("WIP Invoiced Sales Account"; "WIP Invoiced Sales Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the account for the invoiced value, for the job for job tasks, with this posting group. The account is normally a Balance sheet liability account.';
                }
                field("Job Sales Applied Account"; "Job Sales Applied Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account to WIP Invoiced Sales Account. The account is normally a contra (or debit) income account.';
                }
                field("Job Sales Adjustment Account"; "Job Sales Adjustment Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the balancing account to the WIP Accrued Sales account if the work in process (WIP) Method for the job is the Sales Value. The account is normally an income account.';
                }
                field("Recognized Costs Account"; "Recognized Costs Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the account for recognized costs for the job. The account is normally an expense account.';
                }
                field("Recognized Sales Account"; "Recognized Sales Account")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the account for recognized sales (or revenue) for the job. The account is normally an income account.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

