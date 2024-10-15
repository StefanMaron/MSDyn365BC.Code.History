#if not CLEAN20
codeunit 31071 "Business Setup Management CZ"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to CZ apps.';
    ObsoleteTag = '20.0';

    trigger OnRun()
    begin
    end;

    var
#if not CLEAN18
        ConstantSymbolsNameTxt: Label 'Constant Symbols (Obsolete)';
        ConstantSymbolsDescriptionTxt: Label 'Set up or update Constant Symbols.';
        ConstantSymbolsKeywordsTxt: Label 'Bank';
        CreditsSetupNameTxt: Label 'Credits Setup (Obsolete)';
        CreditsSetupDescriptionTxt: Label 'Set up policies for compensation of receivables and payables';
        CreditsSetupKeywordsTxt: Label 'Credits';
        SpecificMovementsNameTxt: Label 'Specific Movements (Obsolete)';
        SpecificMovementsDescriptionTxt: Label 'Set up or update Specific Movements.';
        SpecificMovementsKeywordsTxt: Label 'Intrastat';
        IntrastatDeliveryGroupNameTxt: Label 'Intrastat Delivery Group (Obsolete)';
        IntrastatDeliveryGroupDescriptionTxt: Label 'Set up or update Intrastat Delivery Groups.';
        IntrastatDeliveryGroupKeywordsTxt: Label 'Intrastat';
        StatReportingSetupNameTxt: Label 'State/Statistic Reporting Setup (Obsolete)';
        StatReportingSetupDescriptionTxt: Label 'Define important information for export VIES declaration report, Intrastat report, VAT Statement and VAT Control Report.';
        StatReportingSetupKeywordsTxt: Label 'Intrastat, VAT, VIES, VAT Control Report';
        EETServiceSetupNameTxt: Label 'EET Service Setup (Obsolete)';
        EETServiceSetupDescriptionTxt: Label 'Set up and enable the Electronic registration of sales (EET) service.';
        EETServiceSetupKeywordsTxt: Label 'EET';
        ClassificationCodesNameTxt: Label 'Classification Codes';
        ClassificationCodesDescriptionTxt: Label 'Set up or update Fixed Assets classification codes (Production Classification marked CZ-CPA, Classification building operations marked CZ-CC, DNM).';
        ClassificationCodesKeywordsTxt: Label 'Fixed Assets';
        DepreciationGroupsNameTxt: Label 'Depreciation Groups (Obsolete)';
        DepreciationGroupsDescriptionTxt: Label 'Set up Tax Depreciation Groups for Fixes Assets. These groups determine minimal depreciation periods and parameters used for calculating tax depreciation.';
        DepreciationGroupsKeywordsTxt: Label 'Fixed Assets';
        SalesAdvancedPaymTemplatesNameTxt: Label 'Sales Advanced Payment Templates';
        SalesAdvancedPaymTemplatesDescriptionTxt: Label 'Set up Sales Adv. Paym. Templates (document groups) with predefined accounting and number series of related documents. Define whether or not you are obliged to post VAT.';
        SalesAdvancedPaymTemplatesKeywordsTxt: Label 'Advance, Sales';
        PurchaseAdvPaymTemplatesNameTxt: Label 'Purchase Advance Payment Templates';
        PurchaseAdvPaymTemplatesDescriptionTxt: Label 'Set up Purchase Adv. Paym. Templates (document groups) with predefined accounting and number series of related documents. Define whether or not you are obliged to post VAT.';
        PurchaseAdvPaymTemplatesKeywordsTxt: Label 'Advance, Purchase';
#endif

#if not CLEAN19
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

#if not CLEAN18
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Manual Setup", 'OnRegisterManualSetup', '', false, false)]
    local procedure InsertSetupOnRegisterManualSetup(var Sender: Codeunit "Manual Setup")
    var
        Info: ModuleInfo;
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        NavApp.GetCurrentModuleInfo(Info);

        // Finance
        Sender.Insert(ConstantSymbolsNameTxt, ConstantSymbolsDescriptionTxt,
          ConstantSymbolsKeywordsTxt, PAGE::"Constant Symbols",
          Info.Id(), ManualSetupCategory::Finance);

        Sender.Insert(CreditsSetupNameTxt, CreditsSetupDescriptionTxt,
          CreditsSetupKeywordsTxt, PAGE::"Credits Setup",
          Info.Id(), ManualSetupCategory::Finance);

        Sender.Insert(SpecificMovementsNameTxt, SpecificMovementsDescriptionTxt,
          SpecificMovementsKeywordsTxt, PAGE::"Specific Movements",
          Info.Id(), ManualSetupCategory::Finance);
        Sender.Insert(IntrastatDeliveryGroupNameTxt, IntrastatDeliveryGroupDescriptionTxt,
          IntrastatDeliveryGroupKeywordsTxt, PAGE::"Intrastat Delivery Group",
          Info.Id(), ManualSetupCategory::Finance);
        Sender.Insert(StatReportingSetupNameTxt, StatReportingSetupDescriptionTxt,
          StatReportingSetupKeywordsTxt, PAGE::"Stat. Reporting Setup",
          Info.Id(), ManualSetupCategory::Finance);

        Sender.Insert(EETServiceSetupNameTxt, EETServiceSetupDescriptionTxt,
          EETServiceSetupKeywordsTxt, PAGE::"EET Service Setup",
          Info.Id(), ManualSetupCategory::Finance);

        // Fixed Assests
        Sender.Insert(ClassificationCodesNameTxt, ClassificationCodesDescriptionTxt,
          ClassificationCodesKeywordsTxt, PAGE::"Classification Codes",
          Info.Id(), ManualSetupCategory::"Fixed Assets");
        Sender.Insert(DepreciationGroupsNameTxt, DepreciationGroupsDescriptionTxt,
          DepreciationGroupsKeywordsTxt, PAGE::"Depreciation Groups",
          Info.Id(), ManualSetupCategory::"Fixed Assets");
    end;
#endif
}
#endif