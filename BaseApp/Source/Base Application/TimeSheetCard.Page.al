page 973 "Time Sheet Card"
{
    PageType = Document;
    SourceTable = "Time Sheet Header";
    Caption = 'Time Sheet';
    InsertAllowed = false;
    DataCaptionExpression = GetDataCaption();

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
                    Editable = false;
                    Importance = Additional;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the starting date for a time sheet.';
                    Editable = false;
                    Importance = Additional;
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the ending date for a time sheet.';
                    Editable = false;
                    Importance = Additional;
                }
                field("Resource No."; "Resource No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the resource for the time sheet.';
                    Editable = false;
                }
                field("Resource Name"; "Resource Name")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the resource for the time sheet.';
                    Editable = false;
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the description for the time sheet.';
                    Importance = Additional;
                }
            }
            part(TimeSheetLines; "Time Sheet Lines Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Time Sheet No." = FIELD("No.");
                UpdatePropagation = Both;
            }
        }
        area(factboxes)
        {
            part(TimeSheetStatusFactBox; "Time Sheet Status FactBox")
            {
                ApplicationArea = Jobs;
                Caption = 'Time Sheet Status';
            }
            part(ActualSchedSummaryFactBox; "Actual/Sched. Summary FactBox")
            {
                ApplicationArea = Jobs;
                Caption = 'Actual/Budgeted Summary';
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
        area(processing)
        {
            action(Submit)
            {
                ApplicationArea = Jobs;
                Caption = '&Submit';
                Image = ReleaseDoc;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Enabled = SubmitEnabled;
                Visible = not ManagerTimeSheet;
                ShortCutKey = 'F9';
                ToolTip = 'Submit all open time sheet lines for approval. For dedicated line approval use action Submit on the subform Lines.';

                trigger OnAction()
                begin
                    SubmitLines();
                end;
            }
            action(ReopenSubmitted)
            {
                ApplicationArea = Jobs;
                Caption = '&Reopen';
                Image = ReOpen;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Enabled = ReopenSubmittedEnabled;
                Visible = not ManagerTimeSheet;
                ToolTip = 'Reopen all submitted or rejected time sheet lines. For dedicated line reopen use action Reopen on the subform Lines.';

                trigger OnAction()
                begin
                    ReopenSubmittedLines();
                end;
            }
            action(Approve)
            {
                ApplicationArea = Jobs;
                Caption = '&Approve';
                Image = ReleaseDoc;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Enabled = ApproveEnabled;
                Visible = ManagerTimeSheet;
                ToolTip = 'Approve all submitted time sheet lines. For dedicated line approval use action Approve on the subform Lines.';

                trigger OnAction()
                begin
                    ApproveLines();
                end;
            }
            action(ReopenApproved)
            {
                ApplicationArea = Jobs;
                Caption = '&Reopen';
                Image = ReOpen;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Enabled = ReopenApprovedEnabled;
                Visible = ManagerTimeSheet;
                ToolTip = 'Reopen all approved or rejected time sheet lines. For dedicated line reopen use action Reopen on the subform Lines.';

                trigger OnAction()
                begin
                    ReopenApprovedLines();
                end;
            }
            action(Reject)
            {
                ApplicationArea = Jobs;
                Caption = 'Reject';
                Image = Reject;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Enabled = ApproveEnabled;
                Visible = ManagerTimeSheet;
                ToolTip = 'Approve all submitted time sheet lines. For dedicated line approval use action Approve on the subform Lines.';

                trigger OnAction()
                begin
                    RejectLines();
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CopyLinesFromPrevTS)
                {
                    ApplicationArea = Jobs;
                    Caption = '&Copy lines from previous time sheet';
                    Image = Copy;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;
                    ToolTip = 'Copy information from the previous time sheet, such as type and description, and then modify the lines. If a line is related to a job, the job number is copied.';
                    Visible = not ManagerTimeSheet;

                    trigger OnAction()
                    begin
                        TimeSheetMgt.CheckCopyPrevTimeSheetLines(Rec);
                    end;
                }
                action(CreateLinesFromJobPlanning)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Create lines from &job planning';
                    Image = CreateLinesFromJob;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;
                    ToolTip = 'Create time sheet lines that are based on job planning lines.';
                    Visible = not ManagerTimeSheet;

                    trigger OnAction()
                    begin
                        TimeSheetMgt.CheckCreateLinesFromJobPlanning(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.TimeSheetLines.Page.SetColumns("No.");
        UpdateControls();
    end;

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
        TimeSheetApprovalMgt: Codeunit "Time Sheet Approval Management";
        RefActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject;
        SubmitEnabled: Boolean;
        ReopenSubmittedEnabled: Boolean;
        ReopenApprovedEnabled: Boolean;
        ApproveEnabled: Boolean;
        ManagerTimeSheet: Boolean;

    procedure SetManagerTimeSheetMode()
    begin
        ManagerTimeSheet := true;
        CurrPage.TimeSheetLines.Page.SetManagerTimeSheetMode();
    end;

    local procedure UpdateControls()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        CurrPage.ActualSchedSummaryFactBox.PAGE.UpdateData(Rec);
        CurrPage.TimeSheetStatusFactBox.PAGE.UpdateData(Rec);

        FilterAllLines(TimeSheetLine, RefActionType::Submit);
        SubmitEnabled := not TimeSheetLine.IsEmpty();

        FilterAllLines(TimeSheetLine, RefActionType::ReopenSubmitted);
        ReopenSubmittedEnabled := not TimeSheetLine.IsEmpty();

        FilterAllLines(TimeSheetLine, RefActionType::Approve);
        ApproveEnabled := not TimeSheetLine.IsEmpty();

        FilterAllLines(TimeSheetLine, RefActionType::ReopenApproved);
        ReopenApprovedEnabled := not TimeSheetLine.IsEmpty();
    end;

    local procedure Process(ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject)
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        FilterAllLines(TimeSheetLine, ActionType);
        OnProcessOnAfterTimeSheetLinesFiltered(TimeSheetLine, ActionType);

        if TimeSheetLine.FindSet() then
            repeat
                TimeSheetApprovalMgt.ProcessAction(TimeSheetLine, ActionType);
            until TimeSheetLine.Next() = 0;
        CurrPage.Update(true);

        OnAfterProcess(Rec, ActionType);
    end;

    local procedure SubmitLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSubmitLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if TimeSheetApprovalMgt.ConfirmAction(RefActionType::Submit) then
            Process(RefActionType::Submit);
    end;

    local procedure ApproveLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSubmitLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if TimeSheetApprovalMgt.ConfirmAction(RefActionType::Approve) then
            Process(RefActionType::Approve);
    end;

    local procedure RejectLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSubmitLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if TimeSheetApprovalMgt.ConfirmAction(RefActionType::Reject) then
            Process(RefActionType::Reject);
    end;

    local procedure ReopenSubmittedLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReopenLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if TimeSheetApprovalMgt.ConfirmAction(RefActionType::ReopenSubmitted) then
            Process(RefActionType::ReopenSubmitted);
    end;

    local procedure ReopenApprovedLines()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReopenLines(Rec, IsHandled);
        if IsHandled then
            exit;

        if TimeSheetApprovalMgt.ConfirmAction(RefActionType::ReopenApproved) then
            Process(RefActionType::ReopenApproved);
    end;

    local procedure FilterAllLines(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject)
    begin
        TimeSheetLine.SetRange("Time Sheet No.", "No.");
        TimeSheetMgt.FilterAllTimeSheetLines(TimeSheetLine, ActionType);
    end;

    local procedure GetDataCaption(): Text
    begin
        exit(TimeSheetMgt.GetTimeSheetDataCaption(Rec));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessOnAfterTimeSheetLinesFiltered(var TimeSheetLine: Record "Time Sheet Line"; ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcess(var TimeSheetHeader: Record "Time Sheet Header"; ActionType: Option Submit,ReopenSubmitted,Approve,ReopenApproved,Reject)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenLines(var TimeSheetHeader: Record "Time Sheet Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSubmitLines(var TimeSheetHeader: Record "Time Sheet Header"; var IsHandled: Boolean);
    begin
    end;
}