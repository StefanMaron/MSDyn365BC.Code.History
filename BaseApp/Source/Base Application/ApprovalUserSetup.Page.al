page 663 "Approval User Setup"
{
    AdditionalSearchTerms = 'delegate approver,substitute approver';
    ApplicationArea = Basic, Suite;
    Caption = 'Approval User Setup';
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "User Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("User ID"; "User ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("Salespers./Purch. Code"; "Salespers./Purch. Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the salesperson or purchaser code that relates to the User ID field.';
                }
                field("Approver ID"; "Approver ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user ID of the person who must approve records that are made by the user in the User ID field before the record can be released.';
                }
                field("Sales Amount Approval Limit"; "Sales Amount Approval Limit")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the maximum amount in LCY that this user is allowed to approve for this record.';
                }
                field("Unlimited Sales Approval"; "Unlimited Sales Approval")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user on this line is allowed to approve sales records with no maximum amount. If you select this check box, then you cannot fill the Sales Amount Approval Limit field.';
                }
                field("Purchase Amount Approval Limit"; "Purchase Amount Approval Limit")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the maximum amount in LCY that this user is allowed to approve for this record.';
                }
                field("Unlimited Purchase Approval"; "Unlimited Purchase Approval")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user on this line is allowed to approve purchase records with no maximum amount. If you select this check box, then you cannot fill the Purchase Amount Approval Limit field.';
                }
                field("Request Amount Approval Limit"; "Request Amount Approval Limit")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the maximum amount in LCY that this user is allowed to approve for this record.';
                }
                field("Unlimited Request Approval"; "Unlimited Request Approval")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the user on this line can approve all purchase quotes regardless of their amount. If you select this check box, then you cannot fill the Request Amount Approval Limit field.';
                }
                field(Substitute; Substitute)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the User ID of the user who acts as a substitute for the original approver.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the approver that you can use if you want to send approval mail notifications.';
                }
                field(PhoneNo; "Phone No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user''s phone number.';
                }
                field("Approval Administrator"; "Approval Administrator")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user who has rights to unblock approval workflows, for example, by delegating approval requests to new substitute approvers and deleting overdue approval requests.';
                }
            }
        }
        area(factboxes)
        {
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
        area(processing)
        {
            action("&Approval User Setup Test")
            {
                ApplicationArea = Suite;
                Caption = '&Approval User Setup Test';
                Image = Evaluate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Test the approval user setup, for example, to test if approvers are set up correctly.';

                trigger OnAction()
                begin
                    REPORT.Run(REPORT::"Approval User Setup Test");
                end;
            }
        }
        area(navigation)
        {
            action("Notification Setup")
            {
                ApplicationArea = Suite;
                Caption = 'Notification Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "Notification Setup";
                RunPageLink = "User ID" = FIELD("User ID");
                ToolTip = 'Specify how the user receives notifications, for example about approval workflow steps.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        HideExternalUsers;
    end;
}

