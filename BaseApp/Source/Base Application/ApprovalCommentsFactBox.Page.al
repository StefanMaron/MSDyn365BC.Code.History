page 9104 "Approval Comments FactBox"
{
    Caption = 'Comments';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
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
            }
        }
    }

    actions
    {
    }

    procedure SetFilterFromApprovalEntry(ApprovalEntry: Record "Approval Entry"): Boolean
    begin
        SetRange("Record ID to Approve", ApprovalEntry."Record ID to Approve");
        SetRange("Workflow Step Instance ID", ApprovalEntry."Workflow Step Instance ID");
        CurrPage.Update(false);
        exit(not IsEmpty);
    end;
}

