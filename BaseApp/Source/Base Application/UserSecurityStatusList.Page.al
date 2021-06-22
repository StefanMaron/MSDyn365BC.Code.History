page 9818 "User Security Status List"
{
    AccessByPermission = TableData User = R;
    ApplicationArea = Basic, Suite;
    Caption = 'User Security Status';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "User Security Status";
    SourceTableView = WHERE("User Security ID" = FILTER(<> '{00000000-0000-0000-0000-000000000000}'));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User Name"; "User Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = NOT Reviewed;
                    ToolTip = 'Specifies the user''s name. If the user is required to present credentials when starting the client, this is the name that the user must present.';
                }
                field("Full Name"; "Full Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the full name of the user.';
                }
                field(Reviewed; Reviewed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if an administrator has reviewed this new user. When a new user is created, this field is empty to indicate that the user must be set up.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update;
                    end;
                }
                field("Belongs To Subscription Plan"; BelongsToSubscriptionPlan)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Attention;
                    StyleExpr = NOT BelongsToSubscriptionPlan;
                    ToolTip = 'Specifies that the user is covered by a subscription plan.';
                    Visible = SoftwareAsAService;
                }
                field("Belongs to User Group"; "Belongs to User Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Attention;
                    StyleExpr = NOT "Belongs to User Group";
                    ToolTip = 'Specifies that the user is assigned to a user group.';
                }
            }
        }
        area(factboxes)
        {
            part(Plans; "User Plan Members FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Plans';
                SubPageLink = "User Security ID" = FIELD("User Security ID");
                Visible = SoftwareAsAService;
            }
            part("User Groups"; "User Groups User SubPage")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Groups';
                Editable = false;
                ShowFilter = false;
                SubPageLink = "User Security ID" = FIELD("User Security ID");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Get Users from Office 365")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get Users from Office 365';
                Image = Users;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Gets updated information about users from the Office portal.';
                Visible = SoftwareAsAService;

                trigger OnAction()
                var
                    AzureADUserManagement: Codeunit "Azure AD User Management";
                begin
                    AzureADUserManagement.CreateNewUsersFromAzureAD;
                    CurrPage.Update;
                end;
            }
            action("Set as reviewed")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set as reviewed';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Set the Reviewed field to Yes for this user.';

                trigger OnAction()
                begin
                    ToggleReviewStatus(true);
                end;
            }
            action("Set as not reviewed")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set as not reviewed';
                Image = Cancel;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Set the Reviewed field to No for this user.';

                trigger OnAction()
                begin
                    ToggleReviewStatus(false);
                end;
            }
            action("User Group Members")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Group Members';
                Image = Users;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "User Group Members";
                RunPageMode = View;
                ToolTip = 'View or edit the members of the user group.';
            }
            action("Manage plan assignments")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Manage plan assignments';
                Image = Reconcile;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'View or edit the user''s service plan.';
                Visible = SoftwareAsAService;

                trigger OnAction()
                var
                    PermissionManager: Codeunit "Permission Manager";
                begin
                    HyperLink(PermissionManager.GetOfficePortalUserAdminUrl);
                end;
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        SoftwareAsAService := EnvironmentInfo.IsSaaS;
    end;

    trigger OnAfterGetRecord()
    var
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        BelongsToSubscriptionPlan := AzureADPlan.DoesUserHavePlans("User Security ID");
    end;

    var
        SoftwareAsAService: Boolean;
        BelongsToSubscriptionPlan: Boolean;

    local procedure ToggleReviewStatus(ReviewStatus: Boolean)
    var
        UserSecurityStatus: Record "User Security Status";
    begin
        CurrPage.SetSelectionFilter(UserSecurityStatus);
        if not UserSecurityStatus.FindSet then
            exit;
        repeat
            UserSecurityStatus.Reviewed := ReviewStatus;
            UserSecurityStatus.Modify(true);
            UserSecurityStatus.LogUserReviewActivity;
        until UserSecurityStatus.Next = 0;
        CurrPage.Update;
    end;
}