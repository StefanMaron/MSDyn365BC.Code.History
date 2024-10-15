codeunit 4786 "Company Creation Wizard"
{
    [EventSubscriber(ObjectType::Page, Page::"Company Creation Wizard", 'OnOpenPageCheckAdditionalDemoData', '', false, false)]
    local procedure SetAdditionalDemoDataVisible(var AdditionalDemoDataVisible: Boolean)
    begin
        AdditionalDemoDataVisible := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Company Setup", 'OnAfterAssistedCompanySetupStatusEnabled', '', false, false)]
    local procedure ConfigureAdditionalDemoDataInstallation(NewCompanyName: Text[30]; InstallAdditionalDemoData: Boolean)
    begin
        if AssistedCompanySetupStatus.Get(NewCompanyName) then begin
            AssistedCompanySetupStatus.InstallAdditionalDemoData := InstallAdditionalDemoData;
            AssistedCompanySetupStatus.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Import Config. Package Files", 'OnAfterImportConfigurationPackage', '', false, false)]
    local procedure InstallContosoDemoData()
    var
        CreateManufacturingDemoData: Codeunit "Create Manufacturing DemoData";
    begin
        if not AssistedCompanySetupStatus.Get(CompanyName()) then
            exit;

        if AssistedCompanySetupStatus.InstallAdditionalDemoData then
            CreateManufacturingDemoData.Create();
    end;

    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
}