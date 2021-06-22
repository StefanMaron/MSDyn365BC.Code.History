page 660 "Approval Comments"
{
    Caption = 'Approval Comments';
    DataCaptionFields = "Record ID to Approve";
    DelayedInsert = true;
    DeleteAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Approval Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Comment; Comment)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the comment. You can enter a maximum of 250 characters, both numbers and letters.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the user who created this approval comment.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field("Date and Time"; "Date and Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and time when the comment was made.';
                }
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        "Workflow Step Instance ID" := WorkflowStepInstanceID;
    end;

    var
        WorkflowStepInstanceID: Guid;

    procedure SetWorkflowStepInstanceID(NewWorkflowStepInstanceID: Guid)
    begin
        WorkflowStepInstanceID := NewWorkflowStepInstanceID;
    end;
}

