codeunit 20366 "Tax Engine Assisted Setup"
{
    var
        Info: ModuleInfo;
        SetupWizardTxt: Label 'Set up Tax Engine';

    procedure SetupTaxEngine()
    var
        TaxType: Record "Tax Type";
    begin
        if not TaxType.IsEmpty() then
            exit;

        OnSetupTaxPeriod();
        OnSetupTaxTypes();
        OnSetupUseCases();
        OnSetupUseCaseTree();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnRegister', '', false, false)]
    local procedure Initialize()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Language: Codeunit Language;
        CurrentGlobalLanguage: Integer;
    begin
        CurrentGlobalLanguage := GlobalLanguage;

        AssistedSetup.Add(
            GetAppId(),
            Page::"Tax Engine Setup Wizard",
            SetupWizardTxt,
            "Assisted Setup Group"::GettingStarted,
            '',
            "Video Category"::GettingStarted,
            '');

        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        AssistedSetup.AddTranslation(Page::"Tax Engine Setup Wizard", Language.GetDefaultApplicationLanguageId(), SetupWizardTxt);
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assisted Setup", 'OnReRunOfCompletedSetup', '', false, false)]
    local procedure OnReRunOfCompletedSetup(ExtensionId: Guid; PageID: Integer; var Handled: Boolean)
    begin
        if ExtensionId <> GetAppId() then
            exit;

        case PageID of
            Page::"Tax Engine Setup Wizard":
                Handled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Import Config. Package Files", 'OnBeforeImportConfigurationFile', '', false, false)]
    local procedure OnBeforeImportConfigurationFile()
    begin
        SetupTaxEngine();
    end;

    local procedure GetAppId(): Guid
    var
        EmptyGuid: Guid;
    begin
        if Info.Id() = EmptyGuid then
            NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Id());
    end;

    [BusinessEvent(false)]
    local procedure OnSetupTaxPeriod()
    begin
    end;

    [BusinessEvent(false)]
    local procedure OnSetupTaxTypes()
    begin
    end;

    [BusinessEvent(false)]
    local procedure OnSetupUseCases()
    begin
    end;

    [BusinessEvent(false)]
    local procedure OnSetupUseCaseTree()
    begin
    end;
}