pageextension 4025 "BC Checklist Action" extends "Intelligent Cloud Management"
{
    actions
    {
        addlast(Processing)
        {
            action(SetupChecklist)
            {
                Enabled = IsSuper and IsMigration;
                Visible = not IsOnPrem and IsBC;
                ApplicationArea = Basic, Suite;
                Caption = 'Setup Checklist';
                ToolTip = 'Setup Checklist';
                RunObject = page "Post Migration Checklist";
                RunPageMode = Edit;
                Image = Setup;
            }
            action(MapUsers)
            {
                Enabled = IsSuper and IsMigration;
                Visible = not IsOnPrem and IsBC;
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
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        PermissionManager: Codeunit "Permission Manager";
        UserPermissions: Codeunit "User Permissions";
        EnvironmentInfo: Codeunit "Environment Information";
        HybridBCWizard: Codeunit "Hybrid BC Wizard";
    begin
        if IntelligentCloudSetup.Get() then
            IsBC := (IntelligentCloudSetup."Product ID" = HybridBCWizard.ProductId());
        IsSuper := UserPermissions.IsSuper(UserSecurityId());
        IsOnPrem := NOT EnvironmentInfo.IsSaaS();
        IsSetupComplete := PermissionManager.IsIntelligentCloud() OR (IsOnPrem AND NOT IntelligentCloudStatus.IsEmpty());
        IsMigration := false;
        if HybridCompany.Get(COMPANYNAME()) then
            IsMigration := HybridCompany.Replicate;
    end;

    var
        IsSetupComplete: Boolean;
        IsSuper: Boolean;
        IsOnPrem: Boolean;
        IsMigration: Boolean;
        IsBC: Boolean;
}