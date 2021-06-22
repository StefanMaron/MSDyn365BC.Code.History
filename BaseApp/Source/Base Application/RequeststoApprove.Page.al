page 654 "Requests to Approve"
{
    ApplicationArea = Suite;
    Caption = 'Requests to Approve';
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Approval Entry";
    SourceTableView = SORTING("Approver ID", Status, "Due Date", "Date-Time Sent for Approval")
                      ORDER(Ascending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(ToApprove; RecordCaption)
                {
                    ApplicationArea = Suite;
                    Caption = 'To Approve';
                    ToolTip = 'Specifies the record that you are requested to approve. On the Home tab, in the Process group, choose Record to view the record on a new page where you can also act on the approval request.';
                    Width = 30;
                }
                field(Details; RecordDetails)
                {
                    ApplicationArea = Suite;
                    Caption = 'Details';
                    ToolTip = 'Specifies details about the approval request, such as what and who the request is about.';
                    Width = 50;
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Suite;
                    HideValue = NOT Comment;
                    ToolTip = 'Specifies whether there are comments relating to the approval of the record. If you want to read the comments, choose the field to open the Approval Comment Sheet window.';
                }
                field("Sender ID"; "Sender ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the user who sent the approval request for the document to be approved.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("Sender ID");
                    end;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Suite;
                    StyleExpr = DateStyle;
                    ToolTip = 'Specifies when the record must be approved, by one or more approvers.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the approval status for the entry:';
                    Visible = ShowAllEntries;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the total amount (excl. VAT) on the document awaiting approval.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the total amount in LCY (excl. VAT) on the document awaiting approval.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the currency of the amounts on the sales or purchase lines.';
                }
            }
        }
        area(factboxes)
        {
            part(CommentsFactBox; "Approval Comments FactBox")
            {
                ApplicationArea = Suite;
                Visible = ShowCommentFactbox;
            }
            part(Change; "Workflow Change List FactBox")
            {
                ApplicationArea = Suite;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                UpdatePropagation = SubPart;
                Visible = ShowChangeFactBox;
            }
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
        area(navigation)
        {
            group(Show)
            {
                Caption = 'Show';
                Image = View;
                action("Record")
                {
                    ApplicationArea = Suite;
                    Caption = 'Open Record';
                    Enabled = ShowRecCommentsEnabled;
                    Image = Document;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Scope = Repeater;
                    ToolTip = 'Open the document, journal line, or card that the approval is requested for.';

                    trigger OnAction()
                    begin
                        ShowRecord;
                    end;
                }
                action(Comments)
                {
                    ApplicationArea = Suite;
                    Caption = 'Comments';
                    Enabled = ShowRecCommentsEnabled;
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Process;
                    Scope = Repeater;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        RecRef: RecordRef;
                    begin
                        RecRef.Get("Record ID to Approve");
                        Clear(ApprovalsMgmt);
                        ApprovalsMgmt.GetApprovalCommentForWorkflowStepInstanceID(RecRef, "Workflow Step Instance ID");
                    end;
                }
            }
        }
        area(processing)
        {
            action(Approve)
            {
                ApplicationArea = Suite;
                Caption = 'Approve';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Approve the requested changes.';

                trigger OnAction()
                var
                    ApprovalEntry: Record "Approval Entry";
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    CurrPage.SetSelectionFilter(ApprovalEntry);
                    ApprovalsMgmt.ApproveApprovalRequests(ApprovalEntry);
                end;
            }
            action(Reject)
            {
                ApplicationArea = Suite;
                Caption = 'Reject';
                Image = Reject;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Reject the approval request.';

                trigger OnAction()
                var
                    ApprovalEntry: Record "Approval Entry";
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    CurrPage.SetSelectionFilter(ApprovalEntry);
                    ApprovalsMgmt.RejectApprovalRequests(ApprovalEntry);
                end;
            }
            action(Delegate)
            {
                ApplicationArea = Suite;
                Caption = 'Delegate';
                Image = Delegate;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Scope = Repeater;
                ToolTip = 'Delegate the approval to a substitute approver.';

                trigger OnAction()
                var
                    ApprovalEntry: Record "Approval Entry";
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    CurrPage.SetSelectionFilter(ApprovalEntry);
                    ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);
                end;
            }
            group(View)
            {
                Caption = 'View';
                action(OpenRequests)
                {
                    ApplicationArea = Suite;
                    Caption = 'Open Requests';
                    Image = Approvals;
                    ToolTip = 'Open the approval requests that remain to be approved or rejected.';

                    trigger OnAction()
                    begin
                        SetRange(Status, Status::Open);
                        ShowAllEntries := false;
                    end;
                }
                action(AllRequests)
                {
                    ApplicationArea = Suite;
                    Caption = 'All Requests';
                    Image = AllLines;
                    ToolTip = 'View all approval requests that are assigned to you.';

                    trigger OnAction()
                    begin
                        SetRange(Status);
                        ShowAllEntries := true;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        RecRef: RecordRef;
    begin
        ShowChangeFactBox := CurrPage.Change.PAGE.SetFilterFromApprovalEntry(Rec);
        ShowCommentFactbox := CurrPage.CommentsFactBox.PAGE.SetFilterFromApprovalEntry(Rec);
        ShowRecCommentsEnabled := RecRef.Get("Record ID to Approve");
    end;

    trigger OnAfterGetRecord()
    begin
        SetDateStyle;
    end;

    trigger OnOpenPage()
    begin
        FilterGroup(2);
        SetRange("Approver ID", UserId);
        FilterGroup(0);
        SetRange(Status, Status::Open);
    end;

    var
        DateStyle: Text;
        ShowAllEntries: Boolean;
        ShowChangeFactBox: Boolean;
        ShowRecCommentsEnabled: Boolean;
        ShowCommentFactbox: Boolean;

    local procedure SetDateStyle()
    begin
        DateStyle := '';
        if IsOverdue then
            DateStyle := 'Attention';
    end;
}

