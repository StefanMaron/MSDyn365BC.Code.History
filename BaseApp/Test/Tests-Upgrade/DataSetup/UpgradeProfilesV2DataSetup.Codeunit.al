codeunit 132805 "Upgrade Profiles V2 Data Setup"
{
    Subtype = Upgrade;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerDatabase', '', false, false)]
    local procedure SetupProfilesV2TestData()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        RoleCenterId: Integer;
        PartnerSystemProfileCount: Integer;
        NewSystemProfileIdList: List of [Code[30]];
        NewSystemProfileId: Code[30];
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
        AllObjWithCaption.SetRange("Object Subtype", 'RoleCenter');
        AllObjWithCaption.FindFirst();
        RoleCenterId := AllObjWithCaption."Object ID";

        // Case 1: system profiles that DO NOT map to any of our old demotool system profiles

        for PartnerSystemProfileCount := 0 to 10 do begin
            if AllObjWithCaption.Next() <> 0 then
                RoleCenterId := AllObjWithCaption."Object ID";
            CreateUpgradeSetupDataForSystemProfileID(CopyStr(CreateGuid(), 1, 30), RoleCenterId);
        end;

        // Case 2: system profiles that DO map to one of our system profiles

        NewSystemProfileIdList.AddRange(
            'Accountant', 'Order Processor', 'Security Administrator', 'Business Manager', 'Sales and Relationship Manager',
            'O365 Sales', 'PROJECT MANAGER', 'TEAM MEMBER', 'Invoicing', 'Accountant Portal',
            'Accounting Manager', 'Accounting Services', 'AP Coordinator', 'AR Administrator', 'Bookkeeper',
            'Dispatcher', 'IT Manager', 'Machine Operator', 'Outbound Technician', 'President',
            'President - Small Business', 'Production Planner', 'Purchasing Agent', 'RapidStart Services', 'Resource Manager',
            'Sales Manager', 'Shipping and Receiving', 'Shipping and Receiving - WMS', 'Shop Supervisor', 'Shop Supervisor - Foundation',
            'Warehouse Worker - WMS'
        );

        foreach NewSystemProfileId in NewSystemProfileIdList do begin
            if AllObjWithCaption.Next() <> 0 then
                RoleCenterId := AllObjWithCaption."Object ID";
            CreateUpgradeSetupDataForSystemProfileID(NewSystemProfileId, RoleCenterId);
        end;

        CreateOtherTablesSetupDataForSystemProfileID(''); // accept empty profile for any of those.
    end;

    local procedure CreateUpgradeSetupDataForSystemProfileID(SystemProfileId: Code[30]; RoleCenterId: Integer)
    var
        SystemProfile: Record Profile;
    begin
        // Create a new system profile
        SystemProfile."Profile ID" := SystemProfileId;
        SystemProfile.Description := LowerCase(SystemProfile."Profile ID");
        SystemProfile."Role Center ID" := RoleCenterId;
        if SystemProfile.Insert() then; // If we are using a real 14.x database, some of those profiles are already there

        CreateOtherTablesSetupDataForSystemProfileID(SystemProfileId);
    end;

    local procedure CreateOtherTablesSetupDataForSystemProfileID(SystemProfileId: Code[30])
    var
        UserGroup: Record "User Group";
        ConfigSetup: Record "Config. Setup";
        UserPersonalization: Record "User Personalization";
        ApplicationAreaSetup: Record "Application Area Setup";
        Company: Record Company;
    begin
        // Create a new user group referencing the system profile
        UserGroup.Code := CopyStr(CreateGuid(), 1, MaxStrLen(UserGroup.Code));
        UserGroup.Name := LowerCase(UserGroup.Code);
        UserGroup."Default Profile Scope" := UserGroup."Default Profile Scope"::System;
        UserGroup."Default Profile ID" := SystemProfileId;
        UserGroup.Insert();

        Company.FindSet();
        repeat
            // Create a new config setup referencing the system profile
            ConfigSetup.ChangeCompany(Company.Name);
            ConfigSetup.Init();
            ConfigSetup."Primary Key" := CopyStr(CreateGuid(), 1, MaxStrLen(ConfigSetup."Primary Key"));
            ConfigSetup."Your Profile Code" := SystemProfileId;
            ConfigSetup."Your Profile Scope" := ConfigSetup."Your Profile Scope"::System;
            ConfigSetup.Insert();
        until Company.Next() = 0;

        // Create a new application area setup referencing the system profile
        ApplicationAreaSetup."Profile ID" := SystemProfileId;
        if SystemProfileId = '' then
            ApplicationAreaSetup."Company Name" := CopyStr(CreateGuid(), 1, MaxStrLen(ApplicationAreaSetup."Company Name"));
        ApplicationAreaSetup.Suite := true;
        ApplicationAreaSetup.Basic := true;
        if not ApplicationAreaSetup.Insert() then;

        // Create a new user personalization referencing the system profile
        UserPersonalization."User SID" := CreateGuid();
        UserPersonalization."Profile ID" := SystemProfileId;
        UserPersonalization.Scope := UserPersonalization.Scope::System;
        UserPersonalization.Insert();
    end;

}
