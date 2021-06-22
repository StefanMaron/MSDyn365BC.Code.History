page 9103 "Pending Approval FactBox"
{
    Caption = 'Pending Approval';
    PageType = CardPart;
    SourceTable = "Approval Entry";

    layout
    {
        area(content)
        {
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
                ToolTip = 'Specifies when the record must be approved, by one or more approvers.';
            }
            field(Comment; ApprovalCommentLine.Comment)
            {
                ApplicationArea = Suite;
                Caption = 'Comment';
                ToolTip = 'Specifies a comment that applies to the approval entry.';

                trigger OnDrillDown()
                var
                    ApprovalComments: Page "Approval Comments";
                begin
                    ApprovalComments.SetTableView(ApprovalCommentLine);
                    ApprovalComments.SetWorkflowStepInstanceID("Workflow Step Instance ID");
                    ApprovalComments.RunModal;
                    CurrPage.Update;
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ApprovalCommentLine.SetRange("Table ID", "Table ID");
        ApprovalCommentLine.SetRange("Record ID to Approve", "Record ID to Approve");
        if ApprovalCommentLine.FindLast then;
    end;

    var
        ApprovalCommentLine: Record "Approval Comment Line";
}

