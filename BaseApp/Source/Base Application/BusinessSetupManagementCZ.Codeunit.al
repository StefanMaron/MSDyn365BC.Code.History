codeunit 31071 "Business Setup Management CZ"
{

    trigger OnRun()
    begin
    end;

    var
        ConstantSymbolsNameTxt: Label 'Constant Symbols';
        ConstantSymbolsDescriptionTxt: Label 'Set up or update Constant Symbols.';
        ConstantSymbolsKeywordsTxt: Label 'Bank';
        CashDeskEventsSetupNameTxt: Label 'Cash Desk Events Setup (Obsolete)';
        CashDeskEventsSetupDescriptionTxt: Label 'Define posting and VAT for cash events.';
        CashDeskEventsSetupKeywordsTxt: Label 'Cash Desk';
        CurrencyNominalValuesNameTxt: Label 'Currency Nominal Values (Obsolete)';
        CurrencyNominalValuesDescriptionTxt: Label 'Define the currency values used in the cash registers.';
        CurrencyNominalValuesKeywordsTxt: Label 'Cash Desk, Currency, Money';
        CashDeskSetupNameTxt: Label 'Cash Desk Setup (Obsolete)';
        CashDeskSetupDescriptionTxt: Label 'Set up individual cash desks. For individual cash desk, you can set up No. Series, Cash desk users, etc.';
        CashDeskSetupKeywordsTxt: Label 'Cash Desk';
        VATPeriodsNameTxt: Label 'VAT Periods (Obsolete)';
        VATPeriodsDescriptionTxt: Label 'Set up the number of VAT periods, such as 12 monthly periods, within the fiscal year. VAT periods can be set separately from accounting periods (eg if you are a quarterly VAT payer).';
        VATPeriodsKeywordsTxt: Label 'VAT, Period';
        CreditsSetupNameTxt: Label 'Credits Setup';
        CreditsSetupDescriptionTxt: Label 'Set up policies for compensation of receivables and payables';
        CreditsSetupKeywordsTxt: Label 'Credits';
        StatisticIndicationsNameTxt: Label 'Statistic Indications';
        StatisticIndicationsDescriptionTxt: Label 'Set up or update Statistic Indications.';
        StatisticIndicationsKeywordsTxt: Label 'Intrastat';
        SpecificMovementsNameTxt: Label 'Specific Movements';
        SpecificMovementsDescriptionTxt: Label 'Set up or update Specific Movements.';
        SpecificMovementsKeywordsTxt: Label 'Intrastat';
        IntrastatDeliveryGroupNameTxt: Label 'Intrastat Delivery Group';
        IntrastatDeliveryGroupDescriptionTxt: Label 'Set up or update Intrastat Delivery Groups.';
        IntrastatDeliveryGroupKeywordsTxt: Label 'Intrastat';
        StatReportingSetupNameTxt: Label 'State/Statistic Reporting Setup (Obsolete)';
        StatReportingSetupDescriptionTxt: Label 'Define important information for export VIES declaration report, Intrastat report, VAT Statement and VAT Control Report.';
        StatReportingSetupKeywordsTxt: Label 'Intrastat, VAT, VIES, VAT Control Report';
        ExcelTemplateNameTxt: Label 'Excel Template (Obsolete)';
        ExcelTemplateDescriptionTxt: Label 'Upload Excel templates into which you can export accounting schemes (such as Profit and Loss Statement and Balance Sheet).';
        ExcelTemplateKeywordsTxt: Label 'Gain and Loss Statement, Account Schedule, Excel';
        VATControlReportSectionsNameTxt: Label 'VAT Control Report Sections (Obsolete)';
        VATControlReportSectionsDescriptionTxt: Label 'Set the codes for each reporting portion of the VAT Control Report.';
        VATControlReportSectionsKeywordsTxt: Label 'VAT, VAT Control Report';
        EETServiceSetupNameTxt: Label 'EET Service Setup (Obsolete)';
        EETServiceSetupDescriptionTxt: Label 'Set up and enable the Electronic registration of sales (EET) service.';
        EETServiceSetupKeywordsTxt: Label 'EET';
        ClassificationCodesNameTxt: Label 'Classification Codes';
        ClassificationCodesDescriptionTxt: Label 'Set up or update Fixed Assets classification codes (Production Classification marked CZ-CPA, Classification building operations marked CZ-CC, DNM).';
        ClassificationCodesKeywordsTxt: Label 'Fixed Assets';
        DepreciationGroupsNameTxt: Label 'Depreciation Groups';
        DepreciationGroupsDescriptionTxt: Label 'Set up Tax Depreciation Groups for Fixes Assets. These groups determine minimal depreciation periods and parameters used for calculating tax depreciation.';
        DepreciationGroupsKeywordsTxt: Label 'Fixed Assets';
        SKPCodesNameTxt: Label 'SKP Codes (Obsolete)';
        SKPCodesDescriptionTxt: Label 'Set up or update Standard Classification Production.';
        SKPCodesKeywordsTxt: Label 'Fixed Assets';
        StockkeepingUnitTemplatesNameTxt: Label 'Stockkeeping Unit Templates (Obsolete)';
        StockkeepingUnitTemplatesDescriptionTxt: Label 'Set up Stockkeeping Unit Templates.';
        StockkeepingUnitTemplatesKeywordsTxt: Label 'Stockkeeping Unit, Stock';
        ElectronicallyGovernSetupNameTxt: Label 'Electronically Communication Setup (Obsolete)';
        ElectronicallyGovernSetupDescriptionTxt: Label 'Set up and enable the Check of Unreliable Payers service. Define the Proxy Server.';
        ElectronicallyGovernSetupKeywordsTxt: Label 'Proxy, Unreliable Payer';
        SalesAdvancedPaymTemplatesNameTxt: Label 'Sales Advanced Payment Templates';
        SalesAdvancedPaymTemplatesDescriptionTxt: Label 'Set up Sales Adv. Paym. Templates (document groups) with predefined accounting and number series of related documents. Define whether or not you are obliged to post VAT.';
        SalesAdvancedPaymTemplatesKeywordsTxt: Label 'Advance, Sales';
        PurchaseAdvPaymTemplatesNameTxt: Label 'Purchase Advance Payment Templates';
        PurchaseAdvPaymTemplatesDescriptionTxt: Label 'Set up Purchase Adv. Paym. Templates (document groups) with predefined accounting and number series of related documents. Define whether or not you are obliged to post VAT.';
        PurchaseAdvPaymTemplatesKeywordsTxt: Label 'Advance, Purchase';

    [EventSubscriber(ObjectType::Codeunit, 1875, 'OnRegisterManualSetup', '', false, false)]
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
        Sender.Insert(CashDeskEventsSetupNameTxt, CashDeskEventsSetupDescriptionTxt,
          CashDeskEventsSetupKeywordsTxt, PAGE::"Cash Desk Events Setup",
          Info.Id(), ManualSetupCategory::Finance);
        Sender.Insert(CurrencyNominalValuesNameTxt, CurrencyNominalValuesDescriptionTxt,
          CurrencyNominalValuesKeywordsTxt, PAGE::"Currency Nominal Values",
          Info.Id(), ManualSetupCategory::Finance);
        Sender.Insert(CashDeskSetupNameTxt, CashDeskSetupDescriptionTxt,
          CashDeskSetupKeywordsTxt, PAGE::"Cash Desk Setup",
          Info.Id(), ManualSetupCategory::Finance);
        Sender.Insert(VATPeriodsNameTxt, VATPeriodsDescriptionTxt,
          VATPeriodsKeywordsTxt, PAGE::"VAT Periods",
          Info.Id(), ManualSetupCategory::Finance);
        Sender.Insert(CreditsSetupNameTxt, CreditsSetupDescriptionTxt,
          CreditsSetupKeywordsTxt, PAGE::"Credits Setup",
          Info.Id(), ManualSetupCategory::Finance);
        Sender.Insert(StatisticIndicationsNameTxt, StatisticIndicationsDescriptionTxt,
          StatisticIndicationsKeywordsTxt, PAGE::"Statistic Indications",
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
        Sender.Insert(ExcelTemplateNameTxt, ExcelTemplateDescriptionTxt,
          ExcelTemplateKeywordsTxt, PAGE::"Excel Template",
          Info.Id(), ManualSetupCategory::Finance);
        Sender.Insert(VATControlReportSectionsNameTxt, VATControlReportSectionsDescriptionTxt,
          VATControlReportSectionsKeywordsTxt, PAGE::"VAT Control Report Sections",
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
        Sender.Insert(SKPCodesNameTxt, SKPCodesDescriptionTxt,
          SKPCodesKeywordsTxt, PAGE::"SKP Codes",
          Info.Id(), ManualSetupCategory::"Fixed Assets");

        // Inventory
        Sender.Insert(StockkeepingUnitTemplatesNameTxt, StockkeepingUnitTemplatesDescriptionTxt,
          StockkeepingUnitTemplatesKeywordsTxt, PAGE::"Stockkeeping Unit Templates",
          Info.Id(), ManualSetupCategory::Inventory);

        // Service
        Sender.Insert(ElectronicallyGovernSetupNameTxt, ElectronicallyGovernSetupDescriptionTxt,
          ElectronicallyGovernSetupKeywordsTxt, PAGE::"Electronically Govern. Setup",
          Info.Id(), ManualSetupCategory::Service);

        // Sales
        Sender.Insert(
          SalesAdvancedPaymTemplatesNameTxt, SalesAdvancedPaymTemplatesDescriptionTxt,
          SalesAdvancedPaymTemplatesKeywordsTxt, PAGE::"Sales Advanced Paym. Templates",
          Info.Id(), ManualSetupCategory::Sales);

        // Purchase
        Sender.Insert(PurchaseAdvPaymTemplatesNameTxt, PurchaseAdvPaymTemplatesDescriptionTxt,
          PurchaseAdvPaymTemplatesKeywordsTxt, PAGE::"Purchase Adv. Paym. Templates",
          Info.Id(), ManualSetupCategory::Purchasing);
    end;
}

