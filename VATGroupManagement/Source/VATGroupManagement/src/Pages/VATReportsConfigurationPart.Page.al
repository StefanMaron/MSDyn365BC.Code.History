page 4709 "VAT Reports Configuration Part"
{
    ApplicationArea = VAT;
    Caption = 'VAT Reports Configuration';
    PageType = ListPart;
    SourceTable = "VAT Reports Configuration";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("VAT Report Version"; "VAT Report Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the version of the VAT report.';
                }
                field("Suggest Lines Codeunit ID"; "Suggest Lines Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether an ID is suggested automatically.';
                }
                field("Suggest Lines Codeunit Caption"; "Suggest Lines Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether a caption is suggested automatically.';
                }
                field("Content Codeunit ID"; "Content Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit ID.';
                }
                field("Content Codeunit Caption"; "Content Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit caption code.';
                }
                field("Submission Codeunit ID"; "Submission Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID associated with the submission codeunit.';
                }
                field("Submission Codeunit Caption"; "Submission Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption associated with the submission codeunit.';
                }
                field("Response Handler Codeunit ID"; "Response Handler Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit ID of the response handler.';
                }
                field("Resp. Handler Codeunit Caption"; "Resp. Handler Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the caption that related to the line.';
                }
                field("Validate Codeunit ID"; "Validate Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit ID for the VAT Report line.';
                }
                field("Validate Codeunit Caption"; "Validate Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption for the codeunit VAT Report.';
                }
            }
        }
    }
}

