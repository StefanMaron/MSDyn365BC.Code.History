pageextension 3998 "Reten. Pol. Setup Card - JQ" extends "Retention Policy Setup Card"
{
    actions
    {
        // Add changes to page actions here
        addafter(RetentionPeriods)
        {
            action(JobQueueEntries)
            {
                ApplicationArea = All;
                Caption = 'Job Queue Entries';
                ToolTip = 'Open the Job Queue Entries page to view a list of all jobs.';
                RunObject = Page "Job Queue Entries";
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;
                PromotedCategory = Category4;
                AccessByPermission = TableData "Job Queue Entry" = R;
            }
        }
    }
}