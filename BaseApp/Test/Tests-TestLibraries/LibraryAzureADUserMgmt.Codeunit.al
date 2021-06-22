codeunit 131020 "Library - Azure AD User Mgmt."
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        MockGraphQuery: DotNet MockGraphQuery;

    procedure SetupMockGraphQuery()
    begin
        MockGraphQuery := MockGraphQuery.MockGraphQuery;

        AzureADMgtSetup.Get;
        AzureADMgtSetup."Azure AD User Mgt. Codeunit ID" := CODEUNIT::"Library - Azure AD User Mgmt.";
        AzureADMgtSetup.Modify;
    end;

    local procedure CanHandle(): Boolean
    begin
        if AzureADMgtSetup.Get then
            exit(AzureADMgtSetup."Azure AD User Mgt. Codeunit ID" = CODEUNIT::"Library - Azure AD User Mgmt.");
    end;

    [EventSubscriber(ObjectType::Codeunit, 9012, 'OnInitialize', '', false, false)]
    local procedure OnInitialize(var GraphQuery: DotNet GraphQuery)
    begin
        if not CanHandle then
            exit;

        GraphQuery := GraphQuery.GraphQuery(MockGraphQuery);
    end;

    procedure AddSubscribedSkuWithServicePlan(SkuId: Guid; PlanId: Guid; PlanName: Text)
    var
        SubscribedSku: DotNet SkuInfo;
        ServicePlanInfo: DotNet ServicePlanInfo;
        GuidVar: Variant;
    begin
        ServicePlanInfo := ServicePlanInfo.ServicePlanInfo;
        GuidVar := PlanId;
        ServicePlanInfo.ServicePlanId := GuidVar;
        ServicePlanInfo.ServicePlanName := PlanName;

        SubscribedSku := SubscribedSku.SkuInfo;
        GuidVar := SkuId;
        SubscribedSku.SkuId := GuidVar;
        SubscribedSku.ServicePlans.Add(ServicePlanInfo);

        MockGraphQuery.AddDirectorySubscribedSku(SubscribedSku);
    end;

    procedure AddGraphUser(UserId: Text; UserGivenName: Text; UserSurname: Text; UserEmail: Text; AssignedPlanId: Guid; AssignedPlanService: Text; CapabilityStatus: Text)
    var
        GraphUser: DotNet UserInfo;
    begin
        AddGraphUser(GraphUser, UserId, UserGivenName, UserSurname, UserEmail, AssignedPlanId, AssignedPlanService, CapabilityStatus);
    end;

    procedure AddGraphUser(var GraphUser: DotNet UserInfo; UserId: Text; UserGivenName: Text; UserSurname: Text; UserEmail: Text; AssignedPlanId: Guid; AssignedPlanService: Text; CapabilityStatus: Text)
    begin
        CreateGraphUser(GraphUser, UserId, UserGivenName, UserSurname, UserEmail);
        MockGraphQuery.AddUser(GraphUser);
        AddUserPlan(UserId, AssignedPlanId, AssignedPlanService, CapabilityStatus);
    end;

    local procedure CreateGraphUser(var GraphUser: DotNet UserInfo; UserId: Text; UserGivenName: Text; UserSurname: Text; UserEmail: Text)
    begin
        GraphUser := GraphUser.UserInfo;
        GraphUser.ObjectId := UserId;
        GraphUser.UserPrincipalName := UserEmail;
        GraphUser.Mail := UserEmail;
        GraphUser.GivenName := UserGivenName;
        GraphUser.Surname := UserSurname;
        GraphUser.AccountEnabled := true;
        GraphUser.DisplayName := StrSubstNo('%1 %2', UserGivenName, UserSurname);
    end;

    procedure AddGraphUserWithoutPlan(UserId: Text; UserGivenName: Text; UserSurname: Text; UserEmail: Text)
    var
        GraphUser: DotNet UserInfo;
    begin
        CreateGraphUser(GraphUser, UserId, UserGivenName, UserSurname, UserEmail);
        MockGraphQuery.AddUser(GraphUser);
    end;

    procedure AddGraphUserWithInDevicesGroup(UserId: Text; UserGivenName: Text; UserSurname: Text; UserEmail: Text)
    var
        GraphUser: DotNet UserInfo;
        DevicesGroupInfo: DotNet GroupInfo;
    begin
        CreateGraphUser(GraphUser, UserId, UserGivenName, UserSurname, UserEmail);
        DevicesGroupInfo := DevicesGroupInfo.GroupInfo();
        DevicesGroupInfo.DisplayName := GetDevicesGroupName;
        MockGraphQuery.AddUser(GraphUser);
        MockGraphQuery.AddUserGroup(GraphUser, DevicesGroupInfo);
    end;

    procedure AddGraphUserToDevicesGroup(GraphUser: DotNet UserInfo)
    var
        DevicesGroupInfo: DotNet GroupInfo;
    begin
        DevicesGroupInfo := DevicesGroupInfo.GroupInfo();
        DevicesGroupInfo.DisplayName := GetDevicesGroupName;
        MockGraphQuery.AddUserGroup(GraphUser, DevicesGroupInfo);
    end;

    procedure AddUserPlan(UserId: Text; AssignedPlanId: Guid; AssignedPlanService: Text; CapabilityStatus: Text)
    var
        GraphUser: DotNet UserInfo;
        AssignedPlan: DotNet ServicePlanInfo;
        GuidVar: Variant;
    begin
        AssignedPlan := AssignedPlan.ServicePlanInfo;
        GuidVar := AssignedPlanId;
        AssignedPlan.ServicePlanId := GuidVar;
        AssignedPlan.ServicePlanName := AssignedPlanService;
        AssignedPlan.CapabilityStatus := CapabilityStatus;

        GraphUser := MockGraphQuery.GetUserByObjectId(UserId);
        MockGraphQuery.AddAssignedPlanToUser(GraphUser, AssignedPlan);
    end;

    local procedure CreateDirectoryRole(var DirectoryRole: DotNet RoleInfo; RoleTemplateId: Text; RoleDescription: Text; RoleDisplayName: Text; RoleIsSystem: Boolean)
    var
        BoolVar: Variant;
    begin
        DirectoryRole := DirectoryRole.RoleInfo;
        DirectoryRole.RoleTemplateId := RoleTemplateId;
        DirectoryRole.DisplayName := RoleDisplayName;
        DirectoryRole.Description := RoleDescription;
        BoolVar := RoleIsSystem;
        DirectoryRole.IsSystem := BoolVar;
    end;

    procedure AddUserRole(UserId: Text; RoleTemplateId: Text; RoleDescription: Text; RoleDisplayName: Text; RoleIsSystem: Boolean)
    var
        GraphUser: DotNet UserInfo;
        DirectoryRole: DotNet RoleInfo;
    begin
        CreateDirectoryRole(DirectoryRole, RoleTemplateId, RoleDescription, RoleDisplayName, RoleIsSystem);

        GraphUser := MockGraphQuery.GetUserByObjectId(UserId);
        MockGraphQuery.AddUserRole(GraphUser, DirectoryRole);
    end;

    procedure GetDevicesGroupName(): Text
    begin
        exit('Dynamics 365 Business Central Device Users');
    end;
}

