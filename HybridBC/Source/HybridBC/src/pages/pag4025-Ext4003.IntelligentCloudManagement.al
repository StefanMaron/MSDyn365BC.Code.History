pageextension 4025 "BC Checklist Action" extends "Intelligent Cloud Management"
{
    actions
    {
        addlast(Processing)
        {
            action(SetupChecklist)
            {
                Enabled = IsSuper and IsMigratedCompany;
                Visible = not IsOnPrem and ShowSetupChecklist;
                ApplicationArea = Basic, Suite;
                Caption = 'Setup Checklist';
                ToolTip = 'Setup Checklist';
                RunObject = page "Post Migration Checklist";
                RunPageMode = Edit;
                Image = Setup;
            }
            action(MapUsers)
            {
                Enabled = IsSuper and IsMigratedCompany;
                Visible = not IsOnPrem and ShowMapUsers;
                ApplicationArea = Basic, Suite;
                Caption = 'Define User Mappings';
                ToolTip = 'Define User Mappings';
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = false;
                RunObject = page "Migration User Mapping";
                RunPageMode = Edit;
                Image = Setup;
            }
        }
    }
    trigger OnOpenPage()
    var
        IntelligentCloudStatus: Record "Intelligent Cloud Status";
        HybridCompany: Record "Hybrid Company";
        PermissionManager: Codeunit "Permission Manager";
        UserPermissions: Codeunit "User Permissions";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        IsSuper := UserPermissions.IsSuper(UserSecurityId());
        IsOnPrem := not EnvironmentInfo.IsSaaS();
        IsSetupComplete := PermissionManager.IsIntelligentCloud() OR (IsOnPrem AND not IntelligentCloudStatus.IsEmpty());
        IsMigratedCompany := HybridCompany.Get(CompanyName()) and HybridCompany.Replicate;

        CanShowSetupChecklist(ShowSetupChecklist);
        CanShowMapUsers(ShowMapUsers);
    end;

    var
        IsSetupComplete: Boolean;
        IsSuper: Boolean;
        IsOnPrem: Boolean;
        IsMigratedCompany: Boolean;
        ShowSetupChecklist: Boolean;
        ShowMapUsers: Boolean;
}