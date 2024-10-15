page 744 "VAT Report List"
{
    ApplicationArea = VAT;
    Caption = 'VAT Reports';
    CardPageID = "VAT Report";
    DeleteAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "VAT Report Header";
    UsageCategory = ReportsAndAnalysis;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("VAT Report Config. Code"; "VAT Report Config. Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the appropriate configuration code.';
                }
                field("VAT Report Type"; "VAT Report Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the VAT report is a standard report, or if it is related to a previously submitted VAT report.';
                }
                field("Start Date"; "Start Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the start date of the report period for the VAT report.';
                }
                field("End Date"; "End Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the end date of the report period for the VAT report.';
                }
                field(Status; Status)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the status of the VAT report.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = VAT;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"VAT Report", Rec);
                    end;
                }
            }
            action("Report Setup")
            {
                ApplicationArea = VAT;
                Caption = 'Report Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = "Report";
                RunObject = Page "VAT Report Setup";
                ToolTip = 'Specifies the setup that will be used for the VAT reports submission.';
                Visible = false;
            }
        }
    }
}

