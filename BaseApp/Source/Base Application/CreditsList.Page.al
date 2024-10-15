page 31052 "Credits List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Credits (Obsolete)';
    CardPageID = "Credit Card";
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Approve,Request Approval';
    SourceTable = "Credit Header";
    UsageCategory = Lists;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    layout
    {
        area(content)
        {
            repeater(Control1220007)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the credit card.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies description for credit.';
                }
                field("Company No."; "Company No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of customer or vendor.';
                }
                field("Company City"; "Company City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of customer or vendor.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user associated with the entry.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of registration log';
                }
                field("Balance (LCY)"; "Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the balance on this credit card.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1220016; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control1220017; Notes)
            {
                ApplicationArea = Notes;
            }
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Credit)
            {
                Caption = 'Credit';
                Image = Document;
                action("A&pprovals")
                {
                    ApplicationArea = Suite;
                    Caption = 'A&pprovals';
                    Image = Approvals;
                    ToolTip = 'Relations to the workflow.';

                    trigger OnAction()
                    var
                        ApprovalEntries: Page "Approval Entries";
                    begin
                        ApprovalEntries.Setfilters(DATABASE::"Credit Header", 0, "No.");
                        ApprovalEntries.Run;
                    end;
                }
            }
        }
        area(processing)
        {
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = NOT OpenApprovalEntriesExist;
                    Image = SendApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Relations to the workflow.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckCreditApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendCreditDocForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = OpenApprovalEntriesExist;
                    Image = CancelApprovalRequest;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'Relations to the workflow.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelCreditApprovalRequest(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
        SetControlAppearance;
    end;

    var
        OpenApprovalEntriesExist: Boolean;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(RecordId);
    end;
}

