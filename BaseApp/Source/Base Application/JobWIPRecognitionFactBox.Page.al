page 9099 "Job WIP/Recognition FactBox"
{
    Caption = 'Job Details - WIP/Recognition';
    PageType = CardPart;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Jobs;
                Caption = 'Job No.';
                ToolTip = 'Specifies the job number.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field("WIP Posting Date"; Rec."WIP Posting Date")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the posting date that was entered when the Job Calculate WIP batch job was last run.';
            }
            field("Total WIP Cost Amount"; Rec."Total WIP Cost Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the total WIP cost amount that was last calculated for the job. The WIP Cost Amount for the job is the value WIP Cost Job WIP Entries less the value of the Recognized Cost Job WIP Entries. For jobs with WIP Methods of Sales Value or Percentage of Completion, the WIP Cost Amount is normally 0.';
            }
            field("Applied Costs G/L Amount"; Rec."Applied Costs G/L Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the sum of all applied costs of the selected job.';
                Visible = false;
            }
            field("Total WIP Sales Amount"; Rec."Total WIP Sales Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the total WIP Sales amount that was last calculated for the job. The WIP Sales Amount for the job is the value WIP Sales Job WIP Entries less the value of the Recognized Sales Job WIP Entries. For jobs with WIP Methods of Cost Value or Cost of Sales, the WIP Sales Amount is normally 0.';
            }
            field("Applied Sales G/L Amount"; Rec."Applied Sales G/L Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the sum of all applied costs of the selected job.';
                Visible = false;
            }
            field("Recog. Costs Amount"; Rec."Recog. Costs Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the Recognized Cost amount that was last calculated for the job. The Recognized Cost Amount for the job is the sum of the Recognized Cost Job WIP Entries.';
            }
            field("Recog. Sales Amount"; Rec."Recog. Sales Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the recognized sales amount that was last calculated for the job, which is the sum of the Recognized Sales Job WIP Entries.';
            }
            field("Recog. Profit Amount"; CalcRecognizedProfitAmount())
            {
                ApplicationArea = Jobs;
                Caption = 'Recog. Profit Amount';
                ToolTip = 'Specifies the recognized profit amount for the job.';
            }
            field("Recog. Profit %"; CalcRecognizedProfitPercentage())
            {
                ApplicationArea = Jobs;
                Caption = 'Recog. Profit %';
                ToolTip = 'Specifies the recognized profit percentage for the job.';
            }
            field("Acc. WIP Costs Amount"; CalcAccWIPCostsAmount())
            {
                ApplicationArea = Jobs;
                Caption = 'Acc. WIP Costs Amount';
                ToolTip = 'Specifies the total WIP costs for the job.';
                Visible = false;
            }
            field("Acc. WIP Sales Amount"; CalcAccWIPSalesAmount())
            {
                ApplicationArea = Jobs;
                Caption = 'Acc. WIP Sales Amount';
                ToolTip = 'Specifies the total WIP sales for the job.';
                Visible = false;
            }
            field("Calc. Recog. Sales Amount"; Rec."Calc. Recog. Sales Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the sum of the recognized costs of the involved job tasks.';
                Visible = false;
            }
            field("Calc. Recog. Costs Amount"; Rec."Calc. Recog. Costs Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the sum of the recognized costs of the involved job tasks.';
                Visible = false;
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Job Card", Rec);
    end;
}

