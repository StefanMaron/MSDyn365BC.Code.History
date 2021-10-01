page 975 "Time Sheet Archive Card"
{
    PageType = Document;
    SourceTable = "Time Sheet Header Archive";
    Caption = 'Time Sheet Archive';
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the starting date for a time sheet.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ending date for a time sheet.';
                }
                field("Resource No."; "Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the resource for the time sheet.';
                }
                field(ApproverUserID; "Approver User ID")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ID of the time sheet approver.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description for the time sheet.';
                }
            }
            part(TimeSheetLines; "Time Sheet Archive Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Time Sheet No." = FIELD("No.");
                UpdatePropagation = Both;
            }
        }
        area(factboxes)
        {
            part(PeriodSummaryArcFactBox; "Period Summary Archive FactBox")
            {
                ApplicationArea = Jobs;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(TimeSheetComments)
            {
                ApplicationArea = Comments;
                Caption = 'Comments';
                Image = ViewComments;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                RunObject = Page "Time Sheet Comment Sheet";
                RunPageLink = "No." = FIELD("No."),
                                  "Time Sheet Line No." = CONST(0);
                ToolTip = 'View comments about the time sheet.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    local procedure UpdateControls()
    begin
        CurrPage.TimeSheetLines.Page.SetColumns("No.");
        CurrPage.PeriodSummaryArcFactBox.PAGE.UpdateData(Rec);
    end;
}