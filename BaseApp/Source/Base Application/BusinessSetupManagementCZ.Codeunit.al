#if not CLEAN20
codeunit 31071 "Business Setup Management CZ"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to CZ apps.';
    ObsoleteTag = '20.0';

    trigger OnRun()
    begin
    end;

#if not CLEAN19
    var
        SalesAdvancedPaymTemplatesNameTxt: Label 'Sales Advanced Payment Templates';
        SalesAdvancedPaymTemplatesDescriptionTxt: Label 'Set up Sales Adv. Paym. Templates (document groups) with predefined accounting and number series of related documents. Define whether or not you are obliged to post VAT.';
        SalesAdvancedPaymTemplatesKeywordsTxt: Label 'Advance, Sales';
        PurchaseAdvPaymTemplatesNameTxt: Label 'Purchase Advance Payment Templates';
        PurchaseAdvPaymTemplatesDescriptionTxt: Label 'Set up Purchase Adv. Paym. Templates (document groups) with predefined accounting and number series of related documents. Define whether or not you are obliged to post VAT.';
        PurchaseAdvPaymTemplatesKeywordsTxt: Label 'Advance, Purchase';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterManualSetup', '', false, false)]
    local procedure InsertManualSetupOnRegisterManualSetup(var sender: Codeunit "Guided Experience")
    var
        Info: ModuleInfo;
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        NavApp.GetCurrentModuleInfo(Info);

        // Sales
        Sender.InsertManualSetup(
          SalesAdvancedPaymTemplatesNameTxt, '', SalesAdvancedPaymTemplatesDescriptionTxt, 1,
          ObjectType::Page, PAGE::"Sales Advanced Paym. Templates", ManualSetupCategory::Sales, SalesAdvancedPaymTemplatesKeywordsTxt);

        // Purchase
        Sender.InsertManualSetup(
          PurchaseAdvPaymTemplatesNameTxt, '', PurchaseAdvPaymTemplatesDescriptionTxt, 1,
          ObjectType::Page, PAGE::"Purchase Adv. Paym. Templates", ManualSetupCategory::Purchasing, PurchaseAdvPaymTemplatesKeywordsTxt);
    end;
#endif
}
#endif