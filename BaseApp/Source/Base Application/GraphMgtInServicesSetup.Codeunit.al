codeunit 5466 "Graph Mgt - In. Services Setup"
{

    trigger OnRun()
    begin
    end;

    var
        BusinessSetupNameTxt: Label 'Integration Services Setup';
        BusinessSetupDescriptionTxt: Label 'Define the data that you want to expose in integration services';
        BusinessSetupKeywordsTxt: Label 'Integration,Service,Expose,Setup';

    [EventSubscriber(ObjectType::Codeunit, 1875, 'OnRegisterManualSetup', '', false, false)]
    local procedure HandleAPISetup(var Sender: Codeunit "Manual Setup")
    var
        Info: ModuleInfo;
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Sender.Insert(
          BusinessSetupNameTxt, BusinessSetupDescriptionTxt, BusinessSetupKeywordsTxt,
          PAGE::"Integration Services Setup", Info.Id(), ManualSetupCategory::Service);
    end;
}

