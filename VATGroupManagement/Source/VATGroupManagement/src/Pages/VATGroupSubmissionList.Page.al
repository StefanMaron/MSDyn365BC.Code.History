page 4708 "VAT Group Submission List"
{
    PageType = List;
    Caption = 'VAT Group Submissions';
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    SourceTable = "VAT Group Submission Header";
    CardPageId = "VAT Group Submission";
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Submitted On") order(descending);

    layout
    {

        area(Content)
        {
            repeater(Control1)
            {

                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identifier for the VAT return from the group member that submitted it.';
                }
                field("Member Name"; "Group Member Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the group member that submitted the VAT report.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the report period for the VAT report submission.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the report period for the VAT report submission.';
                }
                field(Company; Company)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the company from which the VAT report was submitted.';
                }
                field("Submitted On"; "Submitted On")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the timestamp during which the VAT report was submitted.';
                }
                field("Member ID"; "Group Member ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the group member that submitted the VAT report.';
                }

            }
        }
    }

}