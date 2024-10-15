namespace System.Environment.Configuration;

using Microsoft.Foundation.Company;
using Microsoft.Upgrade;
using System.Upgrade;

codeunit 8821 "AAD Application Setup"
{
    trigger OnRun()
    begin
    end;

    var
        Dynamics365BusinessCentralforVirtualEntitiesDesTok: Label '%1 for Virtual Tables', Comment = '%1 product name';
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

    procedure ModifyDescriptionOfDynamics365BusinessCentralforVirtualEntitiesAAdApplication()
    var
        AADApplicationInterface: Codeunit "AAD Application Interface";
        ClientID: Text;
        ClientDescription: Text[50];
    begin
        ClientDescription :=
            CopyStr(StrSubstno(Dynamics365BusinessCentralforVirtualEntitiesDesTok, ProductName.Full()), 1, MaxStrLen(ClientDescription));
        ClientID := GetD365BCForVEAppId();
        AADApplicationInterface.ModifyAADApplicationDescription(ClientID, ClientDescription);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure InitSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
#if not CLEAN23
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultAADApplicationTag()) then begin
            if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetDefaultAADApplicationDescriptionTag()) then
                exit;
            ModifyDescriptionOfDynamics365BusinessCentralforVirtualEntitiesAAdApplication();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDefaultAADApplicationDescriptionTag());
        end else begin
            CreateDynamics365BusinessCentralforVirtualEntitiesAAdApplication();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultAADApplicationTag());
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetDefaultAADApplicationDescriptionTag());
        end;
#else
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultAADApplicationTag()) then begin
            CreateDynamics365BusinessCentralforVirtualEntitiesAAdApplication();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultAADApplicationTag());
        end;
#endif
    end;

    [Scope('OnPrem')]
    internal procedure GetD365BCForVEAppId(): Guid
    begin
        exit(Dynamics365BusinessCentralforVirtualEntitiesGuidTok);
    end;
}
