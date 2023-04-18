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
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the starting date for a time sheet.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ending date for a time sheet.';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the resource for the time sheet.';
                }
                field(ApproverUserID; "Approver User ID")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ID of the time sheet approver.';
                }
                field(Description; Rec.Description)
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
                RunObject = Page "Time Sheet Arc. Comment Sheet";
                RunPageLink = "No." = FIELD("No."),
                                  "Time Sheet Line No." = CONST(0);
                ToolTip = 'View comments about the time sheet.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(TimeSheetComments_Promoted; TimeSheetComments)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    trigger OnOpenPage()
    begin
        CheckSetDefaultOwnerFilter();

        OnAfterOnOpenPage(Rec);
    end;

    local procedure UpdateControls()
    begin
        CurrPage.TimeSheetLines.Page.SetColumns("No.");
        CurrPage.PeriodSummaryArcFactBox.PAGE.UpdateData(Rec);
    end;

    local procedure CheckSetDefaultOwnerFilter()
    var
        UserSetup: Record "User Setup";
        TimeSheetMgt: Codeunit "Time Sheet Management";
    begin
        if UserSetup.Get(UserId) then;
        if not UserSetup."Time Sheet Admin." then begin
            FilterGroup(2);
            if (GetFilter("Owner User ID") = '') and (GetFilter("Approver User ID") = '') then
                TimeSheetMgt.FilterTimeSheetsArchive(Rec, FieldNo("Owner User ID"));
            FilterGroup(0);
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var TimeSheetHeaderArchive: Record "Time Sheet Header Archive")
    begin
    end;
}