page 5555 "Permission Conflicts Overview"
{
    PageType = List;
    ShowFilter = false;
    SourceTable = "Permission Conflicts Overview";
    SourceTableTemporary = true;
    Extensible = false;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(PermissionSet; PermissionSetID)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Permission Set ID';
                    Tooltip = 'Specifies the identifier for the permission set.';
                }
                field(Type; Type)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Type';
                    Tooltip = 'Specifies whether the permission set is part of standard Business Central, or a user created it.';
                }
                field(Basic; BasicTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Basic';
                    ToolTip = 'Basic License.';
                    Visible = HasBasic;

                    trigger OnDrillDown()
                    begin
                        if not Basic then
                            EffectivePermissionsMgt.OpenPermissionConflicts(PermissionSetID, PlanOrRole::Basic);
                    end;
                }
                field("Team Member"; TeamMemberTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Team Member';
                    ToolTip = 'Team Member License.';
                    Visible = HasTeamMember;

                    trigger OnDrillDown()
                    begin
                        if not "Team Member" then
                            EffectivePermissionsMgt.OpenPermissionConflicts(PermissionSetID, PlanOrRole::"Team Member");
                    end;
                }
                field(Essential; EssentialTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Essential';
                    ToolTip = 'Essential License.';
                    Visible = HasEssential;

                    trigger OnDrillDown()
                    begin
                        if not Essential then
                            EffectivePermissionsMgt.OpenPermissionConflicts(PermissionSetID, PlanOrRole::Essential);
                    end;
                }
                field(Premium; PremiumTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Premium';
                    ToolTip = 'Premium License.';
                    Visible = HasPremium;

                    trigger OnDrillDown()
                    begin
                        if not Premium then
                            EffectivePermissionsMgt.OpenPermissionConflicts(PermissionSetID, PlanOrRole::Premium);
                    end;
                }
                field(Device; DeviceTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Device';
                    ToolTip = 'Device License.';
                    Visible = HasDevice;

                    trigger OnDrillDown()
                    begin
                        if not Device then
                            EffectivePermissionsMgt.OpenPermissionConflicts(PermissionSetID, PlanOrRole::Device);
                    end;
                }
                field("External Accountant"; ExternalAccountantTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'External Accountant';
                    ToolTip = 'External Accountant License.';
                    Visible = HasExternalAccountant;

                    trigger OnDrillDown()
                    begin
                        if not "External Accountant" then
                            EffectivePermissionsMgt.OpenPermissionConflicts(PermissionSetID, PlanOrRole::"External Accountant");
                    end;
                }
                field("Internal Admin"; InternalAdminTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Internal Admin';
                    ToolTip = 'Internal Admin License.';
                    Visible = HasInternalAdmin;

                    trigger OnDrillDown()
                    begin
                        if not "Internal Admin" then
                            EffectivePermissionsMgt.OpenPermissionConflicts(PermissionSetID, PlanOrRole::"Internal Admin");
                    end;
                }
                field("Delegated Admin"; DelegatedAdminTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Delegated Admin';
                    ToolTip = 'Delegated Admin License.';
                    Visible = HasDelegatedAdmin;

                    trigger OnDrillDown()
                    begin
                        if not "Delegated Admin" then
                            EffectivePermissionsMgt.OpenPermissionConflicts(PermissionSetID, PlanOrRole::"Delegated Admin");
                    end;
                }
                field(HelpDesk; HelpDeskTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'HelpDesk';
                    ToolTip = 'HelpDesk License.';
                    Visible = HasHelpDesk;

                    trigger OnDrillDown()
                    begin
                        if not HelpDesk then
                            EffectivePermissionsMgt.OpenPermissionConflicts(PermissionSetID, PlanOrRole::HelpDesk);
                    end;
                }
            }
        }
    }

    var
        EffectivePermissionsMgt: Codeunit "Effective Permissions Mgt.";
        [InDataSet]
        BasicTxt: Text[20];
        [InDataSet]
        TeamMemberTxt: Text[20];
        [InDataSet]
        EssentialTxt: Text[20];
        [InDataSet]
        PremiumTxt: Text[20];
        [InDataSet]
        DeviceTxt: Text[20];
        [InDataSet]
        ExternalAccountantTxt: Text[20];
        [InDataSet]
        InternalAdminTxt: Text[20];
        [InDataSet]
        DelegatedAdminTxt: Text[20];
        [InDataSet]
        HelpDeskTxt: Text[20];
        HasBasic: Boolean;
        HasTeamMember: Boolean;
        HasEssential: Boolean;
        HasPremium: Boolean;
        HasDevice: Boolean;
        HasExternalAccountant: Boolean;
        HasInternalAdmin: Boolean;
        HasDelegatedAdmin: Boolean;
        HasHelpDesk: Boolean;
        PlansExist: Dictionary of [Guid, Boolean];
        ConflictTxt: Label 'Conflict';
        PlanOrRole: Enum Licenses;

    trigger OnOpenPage()
    begin
        CheckPlans();
        EffectivePermissionsMgt.PopulatePermissionConflictsOverviewTable(Rec, PlansExist);
    end;

    trigger OnAfterGetRecord()
    begin
        BasicTxt := '';
        TeamMemberTxt := '';
        EssentialTxt := '';
        PremiumTxt := '';
        DeviceTxt := '';
        ExternalAccountantTxt := '';
        InternalAdminTxt := '';
        DelegatedAdminTxt := '';
        HelpDeskTxt := '';

        if not Basic then
            BasicTxt := ConflictTxt;
        if not "Team Member" then
            TeamMemberTxt := ConflictTxt;
        if not Essential then
            EssentialTxt := ConflictTxt;
        if not Premium then
            PremiumTxt := ConflictTxt;
        if not Device then
            DeviceTxt := ConflictTxt;
        if not "External Accountant" then
            ExternalAccountantTxt := ConflictTxt;
        if not "Internal Admin" then
            InternalAdminTxt := ConflictTxt;
        if not "Delegated Admin" then
            DelegatedAdminTxt := ConflictTxt;
        if not HelpDesk then
            HelpDeskTxt := ConflictTxt;
    end;

    local procedure CheckPlans()
    var
        AzureADPlan: Codeunit "Azure AD Plan";
        PlanIds: Codeunit "Plan Ids";
    begin
        if AzureADPlan.IsPlanAssigned(PlanIds.GetBasicPlanId()) then
            PlansExist.Add(PlanIds.GetBasicPlanId(), true);

        if AzureADPlan.IsPlanAssigned(PlanIds.GetTeamMemberPlanId()) then
            PlansExist.Add(PlanIds.GetTeamMemberPlanId(), true);

        if AzureADPlan.IsPlanAssigned(PlanIds.GetEssentialPlanId()) then
            PlansExist.Add(PlanIds.GetEssentialPlanId(), true);

        if AzureADPlan.IsPlanAssigned(PlanIds.GetPremiumPlanId()) then
            PlansExist.Add(PlanIds.GetPremiumPlanId(), true);

        if AzureADPlan.IsPlanAssigned(PlanIds.GetDevicePlanId()) then
            PlansExist.Add(PlanIds.GetDevicePlanId(), true);

        if AzureADPlan.IsPlanAssigned(PlanIds.GetExternalAccountantPlanId()) then
            PlansExist.Add(PlanIds.GetExternalAccountantPlanId(), true);

        if AzureADPlan.IsPlanAssigned(PlanIds.GetInternalAdminPlanId()) then
            PlansExist.Add(PlanIds.GetInternalAdminPlanId(), true);

        if AzureADPlan.IsPlanAssigned(PlanIds.GetDelegatedAdminPlanId()) then
            PlansExist.Add(PlanIds.GetDelegatedAdminPlanId(), true);

        if AzureADPlan.IsPlanAssigned(PlanIds.GetHelpDeskPlanId()) then
            PlansExist.Add(PlanIds.GetHelpDeskPlanId(), true);

        HasBasic := PlansExist.ContainsKey(PlanIds.GetBasicPlanId());
        HasTeamMember := PlansExist.ContainsKey(PlanIds.GetTeamMemberPlanId());
        HasEssential := PlansExist.ContainsKey(PlanIds.GetEssentialPlanId());
        HasPremium := PlansExist.ContainsKey(PlanIds.GetPremiumPlanId());
        HasDevice := PlansExist.ContainsKey(PlanIds.GetDevicePlanId());
        HasExternalAccountant := PlansExist.ContainsKey(PlanIds.GetExternalAccountantPlanId());
        HasInternalAdmin := PlansExist.ContainsKey(PlanIds.GetInternalAdminPlanId());
        HasDelegatedAdmin := PlansExist.ContainsKey(PlanIds.GetDelegatedAdminPlanId());
        HasHelpDesk := PlansExist.ContainsKey(PlanIds.GetHelpDeskPlanId());
    end;
}

