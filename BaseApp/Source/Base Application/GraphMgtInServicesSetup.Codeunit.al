codeunit 5466 "Graph Mgt - In. Services Setup"
{

    trigger OnRun()
    begin
    end;

    var
        BusinessSetupNameTxt: Label 'Integration Services Setup';
        BusinessSetupDescriptionTxt: Label 'Define the data that you want to expose in integration services';
        BusinessSetupKeywordsTxt: Label 'Integration,Service,Expose,Setup';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterManualSetup', '', false, false)]
    local procedure HandleAPISetup(var Sender: Codeunit "Guided Experience")
    var
        Info: ModuleInfo;
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Sender.InsertManualSetup(
          BusinessSetupNameTxt, BusinessSetupNameTxt, BusinessSetupDescriptionTxt, 0, ObjectType::Page,
          PAGE::"Integration Services Setup", ManualSetupCategory::Service, BusinessSetupKeywordsTxt);
    end;
}

