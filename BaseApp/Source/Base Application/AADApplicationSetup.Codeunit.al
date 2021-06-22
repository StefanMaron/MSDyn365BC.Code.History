codeunit 8821 "AAD Application Setup"
{
    trigger OnRun()
    begin
    end;

    var
        Dynamics365BusinessCentralforVirtualEntitiesDesTok: Label '%1 for Virtual Entities', Comment = '%1 product name';
        Dynamics365BusinessCentralforVirtualEntitiesGuidTok: Label 'af30e371-ad4a-4097-88c1-5555e7ada96f', Locked = true;

    procedure CreateDynamics365BusinessCentralforVirtualEntitiesAAdApplication()
    var
        AADApplicationInterface: Codeunit "AAD Application Interface";
        ClientID: Text;
        ClientDescription: Text[50];
        ContactInformation: Text[50];
    begin
        ClientDescription :=
            CopyStr(StrSubstno(Dynamics365BusinessCentralforVirtualEntitiesDesTok, ProductName.Full()), 1, MaxStrLen(ClientDescription));
        ClientID := GetD365BCForVEAppId();
        ContactInformation := CopyStr(ProductName.Full(), 1, MaxStrLen(ContactInformation));
        AADApplicationInterface.CreateAADApplication(ClientID, ClientDescription, ContactInformation);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2, 'OnCompanyInitialize', '', false, false)]
    local procedure InitSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultAADApplicationTag()) then
            exit;
        CreateDynamics365BusinessCentralforVirtualEntitiesAAdApplication();
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultAADApplicationTag());
    end;

    [Scope('OnPrem')]
    internal procedure GetD365BCForVEAppId(): Guid
    begin
        exit(Dynamics365BusinessCentralforVirtualEntitiesGuidTok);
    end;
}
