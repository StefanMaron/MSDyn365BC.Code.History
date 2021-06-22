page 832 Approvals
{
    Caption = 'Approvals';
    Editable = false;
    PageType = List;
    SourceTable = "Workflows Entries Buffer";
    SourceTableTemporary = true;
    SourceTableView = SORTING("Record ID", "Last Date-Time Modified")
                      ORDER(Ascending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Created by Application"; "Created by Application")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the integrated app or product that the approval request comes from. ';
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the approval is due.';
                }
                field("Record ID"; RecordIDText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Record ID';
                    ToolTip = 'Specifies the Record ID field.';

                    trigger OnDrillDown()
                    var
                        ApprovalEntry: Record "Approval Entry";
                        WorkflowWebhookEntries: Page "Workflow Webhook Entries";
                    begin
                        if "Created by Application" = "Created by Application"::"Microsoft Flow" then begin
                            WorkflowWebhookEntries.Setfilters("Record ID");
                            WorkflowWebhookEntries.Run;
                        end else begin
                            ApprovalEntry.SetRange("Record ID to Approve", "Record ID");
                            PAGE.Run(PAGE::"Approval Entries", ApprovalEntry);
                        end;
                    end;
                }
                field("Initiated By User ID"; "Initiated By User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the User ID which has initiated the approval.';
                }
                field("To Be Approved By User ID"; "To Be Approved By User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user ID that needs to approve the action.';
                }
                field("Date-Time Initiated"; "Date-Time Initiated")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time that the approvals were initiated.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the approval on the line.';
                }
                field(Response; Response)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related workflow response.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        RecordIDText := Format("Record ID", 0, 1);
    end;

    trigger OnOpenPage()
    var
        WorkflowWebhookEntry: Record "Workflow Webhook Entry";
        ApprovalEntry: Record "Approval Entry";
        WorkflowsCounter: Integer;
    begin
        WorkflowsCounter := 0;

        // get all records from Workflow Webhook Entry table
        if WorkflowWebhookEntry.Find('-') then begin
            repeat
                AddWorkflowWebhookEntry(WorkflowWebhookEntry, WorkflowsCounter);
            until WorkflowWebhookEntry.Next = 0;
        end;

        // add all records from Approval Entry table
        if ApprovalEntry.Find('-') then begin
            repeat
                AddApprovalEntry(ApprovalEntry, WorkflowsCounter);
            until ApprovalEntry.Next = 0;
        end;
    end;

    var
        RecordIDText: Text;

    procedure Setfilters(RecordIDValue: RecordID)
    begin
        SetRange("Record ID", RecordIDValue);
    end;
}

