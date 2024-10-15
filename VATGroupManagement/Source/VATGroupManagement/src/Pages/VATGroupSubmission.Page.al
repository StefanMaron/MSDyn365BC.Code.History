page 4707 "VAT Group Submission"
{
    PageType = Card;
    Caption = 'VAT Group Submission';
    SourceTable = "VAT Group Submission Header";
    ModifyAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
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
            }
            part(VATGroupSubmissionLines; "VAT Group Sub. Lines Subform")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Report Lines';
                SubPageLink = "VAT Group Submission ID" = field(ID);
            }
        }
    }

}