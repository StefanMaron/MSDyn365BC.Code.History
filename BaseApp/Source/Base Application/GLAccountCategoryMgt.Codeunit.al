#if not CLEAN19
codeunit 570 "G/L Account Category Mgt."
{

    trigger OnRun()
    begin
        InitializeAccountCategories;
    end;

    var
        BalanceColumnNameTxt: Label 'M-BALANCE', Comment = 'Max 10 char';
        BalanceColumnDescTxt: Label 'Balance', Comment = 'Max 10 char';
        NetChangeColumnNameTxt: Label 'M-NETCHANG', Comment = 'Max 10 char';
        NetChangeColumnDescTxt: Label 'Net Change', Comment = 'Max 10 char';
        BalanceSheetCodeTxt: Label 'M-BALANCE', Comment = 'Max 10 char';
        BalanceSheetDescTxt: Label 'Balance Sheet', Comment = 'Max 80 chars';
        IncomeStmdCodeTxt: Label 'M-INCOME', Comment = 'Max 10 chars';
        IncomeStmdDescTxt: Label 'Income Statement', Comment = 'Max 80 chars';
        CashFlowCodeTxt: Label 'M-CASHFLOW', Comment = 'Max 10 chars';
        CashFlowDescTxt: Label 'Cash Flow Statement', Comment = 'Max 80 chars';
        RetainedEarnCodeTxt: Label 'M-RETAIND', Comment = 'Max 10 char.';
        RetainedEarnDescTxt: Label 'Retained Earnings', Comment = 'Max 80 chars';
        MissingSetupErr: Label 'You must define a %1 in %2 before performing this function.', Comment = '%1 = field name, %2 = table name.';
        CurrentAssetsTxt: Label 'Current Assets';
        ARTxt: Label 'Accounts Receivable';
        CashTxt: Label 'Cash';
        PrepaidExpensesTxt: Label 'Prepaid Expenses';
        InventoryTxt: Label 'Inventory';
        FixedAssetsTxt: Label 'Fixed Assets';
        EquipementTxt: Label 'Equipment';
        AccumDeprecTxt: Label 'Accumulated Depreciation';
        CurrentLiabilitiesTxt: Label 'Current Liabilities';
        PayrollLiabilitiesTxt: Label 'Payroll Liabilities';
        LongTermLiabilitiesTxt: Label 'Long Term Liabilities';
        CommonStockTxt: Label 'Common Stock';
        RetEarningsTxt: Label 'Retained Earnings';
        DistrToShareholdersTxt: Label 'Distributions to Shareholders';
        IncomeServiceTxt: Label 'Income, Services';
        IncomeProdSalesTxt: Label 'Income, Product Sales';
        IncomeSalesDiscountsTxt: Label 'Sales Discounts';
        IncomeSalesReturnsTxt: Label 'Sales Returns & Allowances';
        IncomeInterestTxt: Label 'Income, Interest';
        COGSLaborTxt: Label 'Labor';
        COGSMaterialsTxt: Label 'Materials';
        COGSDiscountsGrantedTxt: Label 'Discounts Granted';
        RentExpenseTxt: Label 'Rent Expense';
        AdvertisingExpenseTxt: Label 'Advertising Expense';
        InterestExpenseTxt: Label 'Interest Expense';
        FeesExpenseTxt: Label 'Fees Expense';
        InsuranceExpenseTxt: Label 'Insurance Expense';
        PayrollExpenseTxt: Label 'Payroll Expense';
        BenefitsExpenseTxt: Label 'Benefits Expense';
        RepairsTxt: Label 'Repairs and Maintenance Expense';
        UtilitiesExpenseTxt: Label 'Utilities Expense';
        OtherIncomeExpenseTxt: Label 'Other Income & Expenses';
        TaxExpenseTxt: Label 'Tax Expense';
        TravelExpenseTxt: Label 'Travel Expense';
        VehicleExpensesTxt: Label 'Vehicle Expenses';
        BadDebtExpenseTxt: Label 'Bad Debt Expense';
        SalariesExpenseTxt: Label 'Salaries Expense';
        JobsCostTxt: Label 'Jobs Cost';
        IncomeJobsTxt: Label 'Income, Jobs';
        JobSalesContraTxt: Label 'Job Sales Contra';
        OverwriteConfirmationQst: Label 'How do you want to generate standard account schedules?';
        GenerateAccountSchedulesOptionsTxt: Label 'Keep existing account schedules and create new ones.,Overwrite existing account schedules.';
        CreateAccountScheduleForBalanceSheet: Boolean;
        CreateAccountScheduleForIncomeStatement: Boolean;
        CreateAccountScheduleForCashFlowStatement: Boolean;
        CreateAccountScheduleForRetainedEarnings: Boolean;
        ForceCreateAccountSchedule: Boolean;
        A_ReceivablesfromSubscribedCapitalTxt: Label 'A. Receivables from Subscribed Capital';
        B_FixedAssestsTxt: Label 'B. Fixed Assets';
        BI_IntangibleFixedAssetsTxt: Label 'B.I. Intangible Fixed Assests';
        BI1_IntangibleResultsofResearchandDevelopmentTxt: Label 'B.I.1. Intangible Results of Research and Development';
        BI2_ValuableRightsTxt: Label 'B.I.2. Valuable Rights';
        BI21_SoftwareTxt: Label 'B.I.2.1. Software';
        BI22_OtherValuableRightsTxt: Label 'B.I.2.2. Other Valuable Rights';
        BI3_GoodwillTxt: Label 'B.I.3. Goodwill';
        BI4_OtherIntangibleFixedAssetsTxt: Label 'B.I.4. Other Intangible Fixed Assets';
        BI5_AdvancePaymentsforIntangFAandIntangFAinProgressTxt: Label 'B.I.5. Advance Payments for Intang. FA and Intang. FA in Progress';
        BI51_AdvancePaymentsforIntangibleFixedAssetsTxt: Label 'B.I.5.1. Advance Payments for Intangible Fixed Assets';
        BI52_IntangibleFixedAssestsinProgressTxt: Label 'B.I.5.2. Intangible Fixed Assests in Progress';
        BII_TangibleFixedAssetsTxt: Label 'B.II. Tangible Fixed Assets';
        BII1_LandsandBuildingsTxt: Label 'B.II.1. Lands and Buildings';
        BII11_LandsTxt: Label 'B.II.1.1. Lands';
        BII12_BuildingsTxt: Label 'B.II.1.2. Buildings';
        BII2_FixedMovablesandtheCollectionsofFixedMovablesTxt: Label 'B.II.2. Fixed Movables and the Collections of Fixed Movables';
        BII3_ValuationAdjustmenttoAcquiredAssetsTxt: Label 'B.II.3. Valuation Adjustment to Acquired Assets';
        BII4_OtherTangibleFixedAssetsTxt: Label 'B.II.4. Other Tangible Fixed Assets';
        BII41_PerennialCropsTxt: Label 'B.II.4.1. Perennial Crops';
        BII42_FullgrownAnimalsandGroupsThereofTxt: Label 'B.II.4.2. Full-grown Animals and Groups Thereof';
        BII43_OtherTangibleFixedAssetsTxt: Label 'B.II.4.3. Other Tangible Fixed Assets';
        BII5_AdvancePaymentsforTangFAandTangFAinProgressTxt: Label 'B.II.5. Advance Payments for Tang. FA and Tang. FA in Progress';
        BII51_AdvancePaymentsforTangibleFixedAssetsTxt: Label 'B.II.5.1. Advance Payments for Tangible Fixed Assets';
        BII52_TangibleFixedAssetsinProgressTxt: Label 'B.II.5.2. Tangible Fixed Assets in Progress';
        BIII_LongtermFinancialAssetsTxt: Label 'B.III. Long-term Financial Assets';
        BIII1_SharesControlledorControllingEntityTxt: Label 'B.III.1. Shares - Controlled or Controlling Entity';
        BIII2_LoansandCreditsControlledorControllingPersonTxt: Label 'B.III.2. Loans and Credits - Controlled or Controlling Person';
        BIII3_SharesSignificantInfluenceTxt: Label 'B.III.3. Shares - Significant Influence';
        BIII4_LoansandCreditsSignificantInfluenceTxt: Label 'B.III.4. Loans and Credits - Significant Influence';
        BIII5_OtherLongtermSercuritiesandSharesTxt: Label 'B.III.5. Other Long-term Securities and Shares';
        BIII6_LoansandCreditsOthersTxt: Label 'B.III.6. Loans and Credits - Others';
        BIII7_OtherLongtermFinancialAssetsTxt: Label 'B.III.7. Other Long-term Financial Assets';
        BIII71_AnotherLongtermFinancialAssetsTxt: Label 'B.III.7.1. Another Long-term Financial Assets';
        BIII72_AdvancePaymentsforLongtermFinancialAssetsTxt: Label 'B.III.7.2. Advance Payments for Long-term Financial Assets';
        C_CurrentAssetsTxt: Label 'C. Current Assets';
        CI_InventoryTxt: Label 'C.I. Inventory';
        CI1_MaterialTxt: Label 'C.I.1. Material';
        CI2_WorkinProgressandSemiFinishedGoodsTxt: Label 'C.I.2. Work in Progress and Semi-finished Goods';
        CI3_FinishedProductsandGoodsTxt: Label 'C.I.3. Finished Products and Goods';
        CI31_FinishedProductsTxt: Label 'C.I.3.1. Finished Products';
        CI32_GoodsTxt: Label 'C.I.3.2. Goods';
        CI4_YoungandOtherAnimalsandGroupsThereofTxt: Label 'C.I.4. Young and Other Animals and Groups Thereof';
        CI5_AdvancedPaymentsforInventoryTxt: Label 'C.I.5. Advanced Payments for Inventory';
        CII_ReceivablesTxt: Label 'C.II. Receivables';
        CII1_LongtermReceivablesTxt: Label 'C.II.1. Long-term Receivables';
        CII11_TradeReceivables: Label 'C.II.1.1. Trade Receivables';
        CII12_ReceivablesControlledorControllingEntityTxt: Label 'C.II.1.2. Receivables - Controlled or Controlling Entity';
        CII13_ReceivablesSignificantInfluenceTxt: Label 'C.II.1.3. Receivables - Significant Influence';
        CII14_DeferredTaxReceivablesTxt: Label 'C.II.1.4. Deferred Tax Receivables';
        CII15_ReceivablesOthersTxt: Label 'C.II.1.5. Receivables - Others';
        CII151_ReceivablesfromEquityHoldersTxt: Label 'C.II.1.5.1. Receivables from Equity Holders';
        CII152_LongtermAdvancedPaymentsTxt: Label 'C.II.1.5.2. Long-term Advanced Payments';
        CII153_EstimatedReceivablesTxt: Label 'C.II.1.5.3. Estimated Receivables';
        CII154_OtherReceivablesTxt: Label 'C.II.1.5.4. Other Receivables';
        CII2_ShorttermReceivablesTxt: Label 'C.II.2. Short-term Receivables';
        CII21_TradeReceivablesTxt: Label 'C.II.2.1. Trade Receivables';
        CII22_ReceivablesControlledorControllingEntityTxt: Label 'C.II.2.2. Receivables - Controlled or Controlling Entity';
        CII23_ReceivablesSignificantInfluenceTxt: Label 'C.II.2.3. Receivables - Significant Influence';
        CII24_ReceivablesOthersTxt: Label 'C.II.2.4. Receivables - Others';
        CII241_ReceivablesfromEquityHoldersTxt: Label 'C.II.2.4.1. Receivables from Equity Holders';
        CII242_SocialSecurityandHealthInsuranceTxt: Label 'C.II.2.4.2. Social Security and Health Insurance';
        CII243_StateTaxReveiablesTxt: Label 'C.II.2.4.3. State - Tax Reveiables';
        CII244_ShorttermAdvancedPaymentsTxt: Label 'C.II.2.4.4. Short-term Advanced Payments';
        CII245_EstimatedReceivablesTxt: Label 'C.II.2.4.5. Estimated Receivables';
        CII246_OtherReceivablesTxt: Label 'C.II.2.4.6. Other Receivables';
        CII3_AccruedAssetsTxt: Label 'C.II.3. Accrued Assets';
        CII31_PrepaidExpensesTxt: Label 'C.II.3.1. Prepaid Expenses';
        CII32_ComplexPrepaidExpensesTxt: Label 'C.II.3.2. Complex Prepaid Expenses';
        CII33_AccruedIncomesTxt: Label 'C.II.3.3. Accrued Incomes';
        CIII_ShorttermFinancialAssetsTxt: Label 'C.III. Short-term Financial Assets';
        CIII1_SharesControlledorControllingEntityTxt: Label 'C.III.1. Shares - Controlled or Controlling Entity';
        CIII2_OtherShorttermFinancialAssetsTxt: Label 'C.III.2. Other Short-term Financial Assets';
        CIV_FundsTxt: Label 'C.IV. Funds';
        CIV1_CashTxt: Label 'C.IV.1. Cash';
        CIV2_BankAccountsTxt: Label 'C.IV.2. Bank Accounts';
        D_AccruedAssetsTxt: Label 'D. Accrued Assets';
        D1_PrepaidExpensesTxt: Label 'D.1. Prepaid Expenses';
        D2_ComplexPrepaidExpensesTxt: Label 'D.2. Complex Prepaid Expenses';
        D3_AccruedIncomesTxt: Label 'D.3. Accrued Incomes';
        A_EquityTxt: Label 'A. Equity';
        AI_RegisteredCapitalTxt: Label 'A.I. Registered Capital';
        AI1_RegisteredCapitalTxt: Label 'A.I.1. Registered Capital';
        AI2_CompanysOwnSharesTxt: Label 'A.I.2. Company''s Own Shares (-)';
        AI3_ChangesofRegisteredCapitalTxt: Label 'A.I.3. Changes of Registered Capital';
        AII_CapitalSurplusandCapitalFundsTxt: Label 'A.II. Capital Surplus and Capital Funds';
        AII1_CapitalSurplusTxt: Label 'A.II.1. Capital Surplus';
        AII2_CapitalFundsTxt: Label 'A.II.2. Capital Funds';
        AII21_OtherCapitalFundsTxt: Label 'A.II.2.1. Other Capital Funds';
        AII22_GainsandLossesfromRevaluationffAssestsandLiabilitiesTxt: Label 'A.II.2.2. Gains and Losses from Revaluation of Assests and Liabilities (+/-)';
        AII23_GainsandLossesfromRevalinCourseofTransofBusCorpTxt: Label 'A.II.2.3. Gains and Losses from Reval. in Course of Trans. of Bus. Corp. (+/-)';
        AII24_DiffResultingfromTransformationsofBusinessCorporationsTxt: Label 'A.II.2.4. Diff. Resulting from Transformations of Business Corporations (+/-)';
        AII25_DifffromtheValuationintheCourseofTransofBusCorpTxt: Label 'A.II.2.5. Diff. from the Valuation in the Course of Trans. of Bus. Corp. (+/-)';
        AIII_FundsfromProfitTxt: Label 'A.III. Funds from Profit';
        AIII1_OtherReserveFundsTxt: Label 'A.III.1. Other Reserve Funds';
        AIII2_StatutoryandOtherFundsTxt: Label 'A.III.2. Statutory and Other Funds';
        AIV_NetProfitorLossfromPreviousYearsTxt: Label 'A.IV. Net Profit or Loss from Previous Years (+/-)';
        AIV1_RetainedEarningsfromPreviousYearsTxt: Label 'A.IV.1. Retained Earnings from Previous Years';
        AIV2_AccumulatedLossesfromPreviousYearsTxt: Label 'A.IV.2. Accumulated Losses from Previous Years (-)';
        AIV3_OtherNetProfitorLossfromPreviousYearsTxt: Label 'A.IV.3. Other Net Profit from Previous Years (+/-)';
        AV_NetProfitorLossfortheCurrentPeriodTxt: Label 'A.V. Net Profit or Loss for the Current Period';
        AVI_DecidedabouttheAdvancePaymentsofProfitShareTxt: Label 'A.VI. Decided about the Advance Payments of Profit Share (-)';
        BC_LiabilitiesExternalResourcesTxt: Label 'B. + C. Liabilities (External Resources)';
        B_ProvisionsTxt: Label 'B. Provisions';
        B1_ProvisionforPensionandSimilarPayablesTxt: Label 'B.1. Provision for Pension and Similar Payables';
        B2_IncomeTaxProvisionTxt: Label 'B.2. Income Tax Provision';
        B3_ProvisionsunderSpecialLegislationTxt: Label 'B.3. Provisions under Special Legislation';
        B4_OtherProvisionsTxt: Label 'B.4. Other Provisions';
        C_PayablesTxt: Label 'C. Payables';
        CI_LongtermPayablesTxt: Label 'C.I. Long-term Payables';
        CI1_BondsIssuedTxt: Label 'C.I.1. Bonds Issued';
        CI11_ExchangeableBondsTxt: Label 'C.I.1.1. Exchangeable Bonds';
        CI12_OtherBondsTxt: Label 'C.I.1.2. Other Bonds';
        CI2_PayablestoCreditInstitutionsTxt: Label 'C.I.2. Payables to Credit Institutions';
        CI3_LongtermAdvancePaymentsReceivedTxt: Label 'C.I.3. Long-term Advance Payments Received';
        CI4_TradePayables: Label 'C.I.4. Trade Payables';
        CI5_LongtermBillsofExchangetobePaidTxt: Label 'C.I.5. Long-term Bills of Exchange to be Paid';
        CI6_PayablesControlledorControllingEntityTxt: Label 'C.I.6. Payables - Controlled or Controlling Entity';
        CI7_PayablesSignificantInfluenceTxt: Label 'C.I.7. Payables - Significant Influence';
        CI8_DeferredTaxLiabilityTxt: Label 'C.I.8. Deferred Tax Liability';
        CI9_PayablesOthersTxt: Label 'C.I.9. Payables - Others';
        CI91_PayablestoEquityHoldersTxt: Label 'C.I.9.1. Payables to Equity Holders';
        CI92_EstimatedPayablesTxt: Label 'C.I.9.2. Estimated Payables';
        CI93_OtherLiabilitiesTxt: Label 'C.I.9.3. Other Liabilities';
        CII_ShorttermPayablesTxt: Label 'C.II. Short-term Payables';
        CII1_BondsIssuedTxt: Label 'C.II.1. Bonds Issued';
        CII11_ExchangeableBondsTxt: Label 'C.II.1.1. Exchangeable Bonds';
        CII12_OtherBondsTxt: Label 'C.II.1.2. Other Bonds';
        CII2_PayablestoCreditInstitutionsTxt: Label 'C.II.2. Payables to Credit Institutions';
        CII3_ShorttermAdvancePaymentsReceivedTxt: Label 'C.II.3. Short-term Advance Payments Received';
        CII4_TradePayablesTxt: Label 'C.II.4. Trade Payables';
        CII5_ShorttermBillsofExchangetobePaidTxt: Label 'C.II.5. Short-term Bills of Exchange to be Paid';
        CII6_PayablesControlledorControllingEntityTxt: Label 'C.II.6. Payables - Controlled or Controlling Entity';
        CII7_PayablesSignificantInfluenceTxt: Label 'C.II.7. Payables - Significant Influence';
        CII8_PayablesOthersTxt: Label 'C.II.8. Payables - Others';
        CII81_PayablestoEquityHoldersTxt: Label 'C.II.8.1. Payables to Equity Holders';
        CII82_ShorttermFinancialAssistanceTxt: Label 'C.II.8.2. Short-term Financial Assistance';
        CII83_PayrollPayablesTxt: Label 'C.II.8.3. Payroll Payables';
        CII84_PayablesSocialSecurityandHealthInsuranceTxt: Label 'C.II.8.4. Payables - Social Security and Health Insurance';
        CII85_StateTaxLiabilitiesandGrantsTxt: Label 'C.II.8.5. State - Tax Liabilities and Grants';
        CII86_EstimatedPayables: Label 'C.II.8.6. Estimated Payables';
        CII87_AnotherPayablesTxt: Label 'C.II.8.7. Another Payables';
        CIII_AccruedLiabilitiesTxt: Label 'C.III. Accrued Liabilities';
        CIII1_AccruedExpensesTxt: Label 'C.III.1. Accrued Expenses';
        CIII2_DeferredRevenuesTxt: Label 'C.III.2. Deferred Revenues';
        D_AccruedLiabilitiesTxt: Label 'D. Accrued Liabilities';
        D1_AccruedExpensesTxt: Label 'D.1. Accrued Expenses';
        D2_DeferredRevenuesTxt: Label 'D.2. Deferred Revenues';
        IncomeStatementTxt: Label 'Income Statement';
        I_RevenuesfromOwnProductsandServicesTxt: Label 'I. Revenues from Own Products and Services';
        II_RevenuesfromMerchandiseTxt: Label 'II. Revenues from Merchandise';
        A_ConsumptionforProductsTxt: Label 'A. Consumption for Products';
        A1_CostsofGoodsSoldTxt: Label 'A.1. Costs of Goods Sold';
        A2_MaterialandEnergyConsumptionTxt: Label 'A.2. Material and Energy Consumption';
        A3_ServicesTxt: Label 'A.3. Services';
        B_ChangesinInventoryofOwnProductsTxt: Label 'B. Changes in Inventory of Own Products (+/-)';
        C_CapitalizationTxt: Label 'C. Capitalization (-)';
        D_PersonalCosts: Label 'D. Personal Costs';
        D1_WagesandSalariesTxt: Label 'D.1. Wages and Salaries';
        D2_SocialSecurityandHealthInsuranceCostsandOtherCostsTxt: Label 'D.2. Social Security and Health Insurance Costs and Other Costs';
        D21_SocialSecurityandHealthInsuranceTxt: Label 'D.2.1. Social Security and Health Insurance';
        D22_OtherCostsTxt: Label 'D.2.2. Other Costs';
        E_OperatingPartAdjustmentsTxt: Label 'E. Operating Part Adjustments';
        E1_IntangibleandTangibleFixedAssestsAdjustmentsTxt: Label 'E.1. Intangible and Tangible Fixed Assets Adjustments';
        E11_IntangibleandTangibleFixedAssetsAdjustmentsPermanentTxt: Label 'E.1.1. Intangible and Tangible Fixed Assets Adjustments - Permanent';
        E12_IntangibleandTangibleFixedAssetsAdjustmentsTemporaryTxt: Label 'E.1.2. Intangible and Tangible Fixed Assets Adjustments - Temporary';
        E2_InventoriesAdjustmentsTxt: Label 'E.2. Inventories Adjustments';
        E3_ReceivablesAdjustmentsTxt: Label 'E.3. Receivables Adjustments';
        III_OtherOperatingRevenuesTxt: Label 'III. Other Operating Revenues';
        III1_RevenuesfromSalesofFixedAssetsTxt: Label 'III.1. Revenues from Sales of Fixed Assets';
        III2_RevenuesfromSalesofMaterialTxt: Label 'III.2. Revenues from Sales of Material';
        III3_AnotherOperatingRevenuesTxt: Label 'III.3. Another Operating Revenues';
        F_OtherOperatingCostsTxt: Label 'F. Other Operating Costs';
        F1_NetBookValueofFixedAssetsSoldTxt: Label 'F.1. Net Book Value of Fixed Assets Sold';
        F2_NetBookValueofMaterialSoldTxt: Label 'F.2. Net Book Value of Material Sold';
        F3_TaxesandFeesinOperatingPartTxt: Label 'F.3. Taxes and Fees in Operating Part';
        F4_ProvisionsinOperatingPartandComplexPrepaidExpensesTxt: Label 'F.4. Provisions in Operating Part and Complex Prepaid Expenses';
        F5_OtherOperatingCostsTxt: Label 'F.5. Other Operating Costs';
        OperatingProfitTxt: Label '* Operating Profit/Loss (+/-)';
        IV_RevenuesfromLongtermFinancialAssestsSharesTxt: Label 'IV. Revenues from Long-term Financial Assests - Shares';
        IV1_RevenuesfromSharesControlledorControllingEntityTxt: Label 'IV.1. Revenues from Shares - Controlled or Controlling Entity';
        IV2_OtherRevenuesfromSharesTxt: Label 'IV.2. Other Revenues from Shares';
        G_CostsofSharesSoldTxt: Label 'G. Costs of Shares Sold';
        V_RevenuesfromOtherLongtermFinancialAssetsTxt: Label 'V. Revenues from Other Long-term Financial Assets';
        V1_RevenuesfromOtherLongtermFinancialAssetsControlledorControllingTxt: Label 'V.1. Revenues from Other Long-term Financial Assets - Controlled or Controlling';
        V2_OtherRevenuesfromOtherLongtermFinancialAssetsTxt: Label 'V.2. Other Revenues from Other Long-term Financial Assets';
        H_CostsRelatedtoOtherLongtermFinancialAssetsTxt: Label 'H. Costs Related to Other Long-term Financial Assets';
        VI_InterestRevenuesandSimilarRevenuesTxt: Label 'VI. Interest Revenues and Similar Revenues';
        VI1_InterestRevenuesandSimilarRevenuesControlledorControllingEntityTxt: Label 'VI.1. Interest Revenues and Similar Revenues - Controlled or Controlling Entity';
        VI2_OtherInterestRevenuesandSimilarRevenuesTxt: Label 'VI.2. Other Interest Revenues and Similar Revenues';
        I_AdjustmentsandProvisionsinFinancialPartTxt: Label 'I. Adjustments and Provisions in Financial Part';
        J_InterestCostsandSimilarCostsTxt: Label 'J. Interest Costs and Similar Costs';
        J1_InterestCostsandSimilarCostsControlledorControllingEntityTxt: Label 'J.1. Interest Costs and Similar Costs - Controlled or Controlling Entity';
        J2_OtherInterestCostsandSimilarCostsTxt: Label 'J.2. Other Interest Costs and Similar Costs';
        VII_OtherFinancialRevenuesTxt: Label 'VII. Other Financial Revenues';
        K_OtherFinancialCostsTxt: Label 'K. Other Financial Costs';
        ProfitLossfromFinancialOperationsTxt: Label '* Profit/Loss from Financial Operations (+/-)';
        ProfitLossbeforeTaxTxt: Label '** Profit/Loss before Tax (+/-)';
        L_IncomeTaxTxt: Label 'L. Income Tax';
        L1_IncomeTaxDueTxt: Label 'L.1. Income Tax - Due';
        L2_IncomeTaxDeferredTxt: Label 'L.2. Income Tax - Deferred (+/-)';
        ProfitLossafterTaxTxt: Label '** Profit/Loss after Tax (+/-)';
        M_TransferofShareinProfittoEquityHoldersTxt: Label 'M. Transfer of Share in Profit to Equity Holders (+/-)';
        ProfitLossofAccountingPeriodTxt: Label '*** Profit/Loss of Accounting Period (+/-)';
        NetTurnoverofAccountingPeriodTxt: Label '* Net Turnover of Accounting Period';

    procedure InitializeAccountCategories()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccount: Record "G/L Account";
        CategoryID: array[3] of Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitializeAccountCategories(IsHandled);
        if IsHandled then
            exit;

        GLAccount.SetFilter("Account Subcategory Entry No.", '<>0');
        if not GLAccount.IsEmpty() then
            if not GLAccountCategory.IsEmpty() then
                exit;

        GLAccount.ModifyAll("Account Subcategory Entry No.", 0);
        with GLAccountCategory do begin
            DeleteAll();
            CategoryID[1] := AddCategory(0, 0, "Account Category"::Assets, '', true, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Assets, CurrentAssetsTxt, false, 0);
            CategoryID[3] :=
              AddCategory(0, CategoryID[2], "Account Category"::Assets, CashTxt, false, "Additional Report Definition"::"Cash Accounts");
            CategoryID[3] :=
              AddCategory(
                0, CategoryID[2], "Account Category"::Assets, ARTxt, false,
                "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
              AddCategory(
                0, CategoryID[2], "Account Category"::Assets, PrepaidExpensesTxt, false,
                "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
              AddCategory(
                0, CategoryID[2], "Account Category"::Assets, InventoryTxt, false,
                "Additional Report Definition"::"Operating Activities");
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Assets, FixedAssetsTxt, false, 0);
            CategoryID[3] :=
              AddCategory(
                0, CategoryID[2], "Account Category"::Assets, EquipementTxt, false,
                "Additional Report Definition"::"Investing Activities");
            CategoryID[3] :=
              AddCategory(
                0, CategoryID[2], "Account Category"::Assets, AccumDeprecTxt, false,
                "Additional Report Definition"::"Investing Activities");
            CategoryID[1] := AddCategory(0, 0, "Account Category"::Liabilities, '', true, 0);
            CategoryID[2] :=
              AddCategory(
                0, CategoryID[1], "Account Category"::Liabilities, CurrentLiabilitiesTxt, false,
                "Additional Report Definition"::"Operating Activities");
            CategoryID[2] :=
              AddCategory(
                0, CategoryID[1], "Account Category"::Liabilities, PayrollLiabilitiesTxt, false,
                "Additional Report Definition"::"Operating Activities");
            CategoryID[2] :=
              AddCategory(
                0, CategoryID[1], "Account Category"::Liabilities, LongTermLiabilitiesTxt, false,
                "Additional Report Definition"::"Financing Activities");
            CategoryID[1] := AddCategory(0, 0, "Account Category"::Equity, '', true, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Equity, CommonStockTxt, false, 0);
            CategoryID[2] :=
              AddCategory(
                0, CategoryID[1], "Account Category"::Equity, RetEarningsTxt, false,
                "Additional Report Definition"::"Retained Earnings");
            CategoryID[2] :=
              AddCategory(
                0, CategoryID[1], "Account Category"::Equity, DistrToShareholdersTxt, false,
                "Additional Report Definition"::"Distribution to Shareholders");
            CategoryID[1] := AddCategory(0, 0, "Account Category"::Income, '', true, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, IncomeServiceTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, IncomeProdSalesTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, IncomeJobsTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, IncomeSalesDiscountsTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, IncomeSalesReturnsTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, IncomeInterestTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Income, JobSalesContraTxt, false, 0);
            CategoryID[1] := AddCategory(0, 0, "Account Category"::"Cost of Goods Sold", '', true, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::"Cost of Goods Sold", COGSLaborTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::"Cost of Goods Sold", COGSMaterialsTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::"Cost of Goods Sold", COGSDiscountsGrantedTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::"Cost of Goods Sold", JobsCostTxt, false, 0);
            CategoryID[1] := AddCategory(0, 0, "Account Category"::Expense, '', true, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, RentExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, AdvertisingExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, InterestExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, FeesExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, InsuranceExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, PayrollExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, BenefitsExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, SalariesExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, RepairsTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, UtilitiesExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, OtherIncomeExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, TaxExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, TravelExpenseTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, VehicleExpensesTxt, false, 0);
            CategoryID[2] := AddCategory(0, CategoryID[1], "Account Category"::Expense, BadDebtExpenseTxt, false, 0);
        end;

        OnAfterInitializeAccountCategories();
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure InitializeLocalizedAccountCategories()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccount: Record "G/L Account";
        CategoryID: array[6] of Integer;
    begin
        GLAccount.SetFilter("Account Subcategory Entry No.", '<>0');
        if not GLAccount.IsEmpty() then
            if not GLAccountCategory.IsEmpty() then
                exit;

        GLAccount.ModifyAll("Account Subcategory Entry No.", 0);
        with GLAccountCategory do begin
            DeleteAll();
            CategoryID[1] := AddCategory(0, 0, "Account Category"::Assets, '', true, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Assets, A_ReceivablesfromSubscribedCapitalTxt, false,
                    "Additional Report Definition"::"Financing Activities");
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Assets, B_FixedAssestsTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Assets, BI_IntangibleFixedAssetsTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BI1_IntangibleResultsofResearchandDevelopmentTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BI2_ValuableRightsTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BI21_SoftwareTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BI22_OtherValuableRightsTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BI3_GoodwillTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BI4_OtherIntangibleFixedAssetsTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BI5_AdvancePaymentsforIntangFAandIntangFAinProgressTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BI51_AdvancePaymentsforIntangibleFixedAssetsTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BI52_IntangibleFixedAssestsinProgressTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Assets, BII_TangibleFixedAssetsTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BII1_LandsAndBuildingsTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BII11_LandsTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BII12_BuildingsTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BII2_FixedMovablesandtheCollectionsofFixedMovablesTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BII3_ValuationAdjustmenttoAcquiredAssetsTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BII4_OtherTangibleFixedAssetsTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BII41_PerennialCropsTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BII42_FullgrownAnimalsandGroupsThereofTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BII43_OtherTangibleFixedAssetsTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BII5_AdvancePaymentsforTangFAandTangFAinProgressTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BII51_AdvancePaymentsForTangibleFixedAssetsTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BII52_TangibleFixedAssetsinProgressTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Assets, BIII_LongtermFinancialAssetsTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BIII1_SharesControlledorControllingEntityTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BIII2_LoansandCreditsControlledorControllingPersonTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BIII3_SharesSignificantInfluenceTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BIII4_LoansandCreditsSignificantInfluenceTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BIII5_OtherLongtermSercuritiesandSharesTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BIII6_LoansandCreditsOthersTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, BIII7_OtherLongtermFinancialAssetsTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BIII71_AnotherLongtermFinancialAssetsTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, BIII72_AdvancePaymentsForLongtermFinancialAssetsTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Assets, C_CurrentAssetsTxt, false,
                    "Additional Report Definition"::"Investing Activities");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Assets, CI_InventoryTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, CI1_MaterialTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, CI2_WorkinProgressandSemiFinishedGoodsTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, CI3_FinishedProductsandGoodsTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CI31_FinishedProductsTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CI32_GoodsTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, CI4_YoungandOtherAnimalsandGroupsThereofTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, CI5_AdvancedPaymentsforInventoryTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Assets, CII_ReceivablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, CII1_LongtermReceivablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CII11_TradeReceivables, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CII12_ReceivablesControlledorControllingEntityTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CII13_ReceivablesSignificantInfluenceTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CII14_DeferredTaxReceivablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CII15_ReceivablesOthersTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Assets, CII151_ReceivablesfromEquityHoldersTxt, false, 0);
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Assets, CII152_LongtermAdvancedPaymentsTxt, false, 0);
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Assets, CII153_EstimatedReceivablesTxt, false, 0);
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Assets, CII154_OtherReceivablesTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, CII2_ShorttermReceivablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CII21_TradeReceivablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CII22_ReceivablesControlledorControllingEntityTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CII23_ReceivablesSignificantInfluenceTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CII24_ReceivablesOthersTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Assets, CII241_ReceivablesfromEquityHoldersTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Assets, CII242_SocialSecurityandHealthInsuranceTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Assets, CII243_StateTaxReveiablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Assets, CII244_ShorttermAdvancedPaymentsTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Assets, CII245_EstimatedReceivablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Assets, CII246_OtherReceivablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, CII3_AccruedAssetsTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CII31_PrepaidExpensesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CII32_ComplexPrepaidExpensesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Assets, CII33_AccruedIncomesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Assets, CIII_ShorttermFinancialAssetsTxt, false,
                    "Additional Report Definition"::"Financing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, CIII1_SharesControlledorControllingEntityTxt, false,
                    "Additional Report Definition"::"Financing Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, CIII2_OtherShorttermFinancialAssetsTxt, false,
                    "Additional Report Definition"::"Financing Activities");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Assets, CIV_FundsTxt, false,
                    "Additional Report Definition"::"Cash Accounts");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, CIV1_CashTxt, false,
                    "Additional Report Definition"::"Cash Accounts");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Assets, CIV2_BankAccountsTxt, false,
                    "Additional Report Definition"::"Cash Accounts");
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Assets, D_AccruedAssetsTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Assets, D1_PrepaidExpensesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Assets, D2_ComplexPrepaidExpensesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Assets, D3_AccruedIncomesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[1] :=
                AddCategory(0, 0, "Account Category"::Liabilities, '', true, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Liabilities, A_EquityTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Liabilities, AI_RegisteredCapitalTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, AI1_RegisteredCapitalTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, AI2_CompanysOwnSharesTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, AI3_ChangesofRegisteredCapitalTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Liabilities, AII_CapitalSurplusandCapitalFundsTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, AII1_CapitalSurplusTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, AII2_CapitalFundsTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, AII21_OtherCapitalFundsTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, AII22_GainsandLossesfromRevaluationffAssestsandLiabilitiesTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, AII23_GainsandLossesfromRevalinCourseofTransofBusCorpTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, AII24_DiffResultingfromTransformationsofBusinessCorporationsTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, AII25_DifffromtheValuationintheCourseofTransofBusCorpTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Liabilities, AIII_FundsfromProfitTxt, false,
                    "Additional Report Definition"::"Retained Earnings");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, AIII1_OtherReserveFundsTxt, false,
                    "Additional Report Definition"::"Retained Earnings");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, AIII2_StatutoryAndOtherFundsTxt, false,
                    "Additional Report Definition"::"Retained Earnings");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Liabilities, AIV_NetProfitorLossfromPreviousYearsTxt, false,
                    "Additional Report Definition"::"Retained Earnings");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, AIV1_RetainedEarningsfromPreviousYearsTxt, false,
                    "Additional Report Definition"::"Retained Earnings");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, AIV2_AccumulatedLossesfromPreviousYearsTxt, false,
                    "Additional Report Definition"::"Retained Earnings");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, AIV3_OtherNetProfitorLossfromPreviousYearsTxt, false,
                    "Additional Report Definition"::"Retained Earnings");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Liabilities, AV_NetProfitorLossfortheCurrentPeriodTxt, false,
                    "Additional Report Definition"::"Retained Earnings");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Liabilities, AVI_DecidedabouttheAdvancePaymentsofProfitShareTxt, false,
                    "Additional Report Definition"::"Distribution to Shareholders");
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Liabilities, BC_LiabilitiesExternalResourcesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Liabilities, B_ProvisionsTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, B1_ProvisionforPensionandSimilarPayablesTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, B2_IncomeTaxProvisionTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, B3_ProvisionsunderSpecialLegislationTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, B4_OtherProvisionsTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Liabilities, C_PayablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, CI_LongtermPayablesTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CI1_BondsIssuedTxt, false, 0);
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CI11_ExchangeableBondsTxt, false, 0);
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CI12_OtherBondsTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CI2_PayablestoCreditInstitutionsTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CI3_LongtermAdvancePaymentsReceivedTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CI4_TradePayables, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CI5_LongtermBillsofExchangetobePaidTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CI6_PayablesControlledorControllingEntityTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CI7_PayablesSignificantInfluenceTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CI8_DeferredTaxLiabilityTxt, false, 0);
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CI9_PayablesOthersTxt, false, 0);
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CI91_PayablestoEquityHoldersTxt, false, 0);
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CI92_EstimatedPayablesTxt, false, 0);
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CI93_OtherLiabilitiesTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, CII_ShorttermPayablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CII1_BondsIssuedTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CII11_ExchangeableBondsTxt, false,
                    "Additional Report Definition"::"Financing Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CII12_OtherBondsTxt, false,
                    "Additional Report Definition"::"Financing Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CII2_PayablestoCreditInstitutionsTxt, false,
                    "Additional Report Definition"::"Financing Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CII3_ShorttermAdvancePaymentsReceivedTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CII4_TradePayablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CII5_ShorttermBillsofExchangetobePaidTxt, false,
                    "Additional Report Definition"::"Financing Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CII6_PayablesControlledorControllingEntityTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CII7_PayablesSignificantInfluenceTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CII8_PayablesOthersTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CII81_PayablestoEquityHoldersTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CII82_ShorttermFinancialAssistanceTxt, false,
                    "Additional Report Definition"::"Financing Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CII83_PayrollPayablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CII84_PayablesSocialSecurityandHealthInsuranceTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CII85_StateTaxLiabilitiesAndGrantsTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CII86_EstimatedPayables, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[6] :=
                AddCategory(0, CategoryID[5], "Account Category"::Liabilities, CII87_AnotherPayablesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Liabilities, CIII_AccruedLiabilitiesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CIII1_AccruedExpensesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[5] :=
                AddCategory(0, CategoryID[4], "Account Category"::Liabilities, CIII2_DeferredRevenuesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Liabilities, D_AccruedLiabilitiesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Liabilities, D1_AccruedExpensesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Liabilities, D2_DeferredRevenuesTxt, false,
                    "Additional Report Definition"::"Operating Activities");
            CategoryID[1] :=
                AddCategory(0, 0, 0, IncomeStatementTxt, true, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Income, I_RevenuesfromOwnProductsandServicesTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Income, II_RevenuesfromMerchandiseTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, A_ConsumptionforProductsTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, A1_CostsofGoodsSoldTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, A2_MaterialAndEnergyConsumptionTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, A3_ServicesTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, B_ChangesinInventoryofOwnProductsTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, C_CapitalizationTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, D_PersonalCosts, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, D1_WagesandSalariesTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, D2_SocialSecurityandHealthInsuranceCostsandOtherCostsTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Expense, D21_SocialSecurityandHealthInsuranceTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Expense, D22_OtherCostsTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, E_OperatingPartAdjustmentsTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, E1_IntangibleandTangibleFixedAssestsAdjustmentsTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Expense, E11_IntangibleandTangibleFixedAssetsAdjustmentsPermanentTxt, false, 0);
            CategoryID[4] :=
                AddCategory(0, CategoryID[3], "Account Category"::Expense, E12_IntangibleandTangibleFixedAssetsAdjustmentsTemporaryTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, E2_InventoriesAdjustmentsTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, E3_ReceivablesAdjustmentsTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Income, III_OtherOperatingRevenuesTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Income, III1_RevenuesfromSalesofFixedAssetsTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Income, III2_RevenuesfromSalesofMaterialTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Income, III3_AnotherOperatingRevenuesTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, F_OtherOperatingCostsTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, F1_NetBookValueOfFixedAssetsSoldTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, F2_NetBookValueofMaterialSoldTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, F3_TaxesandFeesinOperatingPartTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, F4_ProvisionsinOperatingPartandComplexPrepaidExpensesTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, F5_OtherOperatingCostsTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, OperatingProfitTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Income, IV_RevenuesFromLongtermFinancialAssestsSharesTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Income, IV1_RevenuesfromSharesControlledorControllingEntityTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Income, IV2_OtherRevenuesFromSharesTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, G_CostsofSharesSoldTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Income, V_RevenuesFromOtherLongtermFinancialAssetsTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Income, V1_RevenuesfromOtherLongtermFinancialAssetsControlledorControllingTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Income, V2_OtherRevenuesFromOtherLongtermFinancialAssetsTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, H_CostsRelatedToOtherLongtermFinancialAssetsTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Income, VI_InterestRevenuesandSimilarRevenuesTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Income, VI1_InterestRevenuesandSimilarRevenuesControlledorControllingEntityTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Income, VI2_OtherInterestRevenuesandSimilarRevenuesTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, I_AdjustmentsandProvisionsinFinancialPartTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, J_InterestCostsandSimilarCostsTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, J1_InterestCostsandSimilarCostsControlledorControllingEntityTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, J2_OtherInterestCostsandSimilarCostsTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Income, VII_OtherFinancialRevenuesTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, K_OtherFinancialCostsTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, ProfitLossfromFinancialOperationsTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, ProfitLossbeforeTaxTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, L_IncomeTaxTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, L1_IncomeTaxDueTxt, false, 0);
            CategoryID[3] :=
                AddCategory(0, CategoryID[2], "Account Category"::Expense, L2_IncomeTaxDeferredTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, ProfitLossafterTaxTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, M_TransferofShareinProfittoEquityHoldersTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, ProfitLossofAccountingPeriodTxt, false, 0);
            CategoryID[2] :=
                AddCategory(0, CategoryID[1], "Account Category"::Expense, NetTurnoverofAccountingPeriodTxt, false, 0);
        end;
    end;

    procedure AddCategory(InsertAfterEntryNo: Integer; ParentEntryNo: Integer; AccountCategory: Option; NewDescription: Text[80]; SystemGenerated: Boolean; CashFlowActivity: Option): Integer
    var
        GLAccountCategory: Record "G/L Account Category";
        InsertAfterSequenceNo: Integer;
        InsertBeforeSequenceNo: Integer;
    begin
        if InsertAfterEntryNo <> 0 then begin
            GLAccountCategory.SetCurrentKey("Presentation Order", "Sibling Sequence No.");
            if GLAccountCategory.Get(InsertAfterEntryNo) then begin
                InsertAfterSequenceNo := GLAccountCategory."Sibling Sequence No.";
                if GLAccountCategory.Next <> 0 then
                    InsertBeforeSequenceNo := GLAccountCategory."Sibling Sequence No.";
            end;
        end;
        GLAccountCategory.Init();
        GLAccountCategory."Entry No." := 0;
        GLAccountCategory."System Generated" := SystemGenerated;
        GLAccountCategory."Parent Entry No." := ParentEntryNo;
        GLAccountCategory.Validate("Account Category", AccountCategory);
        GLAccountCategory.Validate("Additional Report Definition", CashFlowActivity);
        if NewDescription <> '' then
            GLAccountCategory.Description := NewDescription;
        if InsertAfterSequenceNo <> 0 then begin
            if InsertBeforeSequenceNo <> 0 then
                GLAccountCategory."Sibling Sequence No." := (InsertBeforeSequenceNo + InsertAfterSequenceNo) div 2
            else
                GLAccountCategory."Sibling Sequence No." := InsertAfterSequenceNo + 10000;
        end;
        GLAccountCategory.Insert(true);
        GLAccountCategory.UpdatePresentationOrder;
        exit(GLAccountCategory."Entry No.");
    end;

    procedure ForceInitializeStandardAccountSchedules()
    begin
        ForceCreateAccountSchedule := true;
        InitializeStandardAccountSchedules();
    end;

    procedure InitializeStandardAccountSchedules()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not GeneralLedgerSetup.Get then
            exit;

        AddColumnLayout(BalanceColumnNameTxt, BalanceColumnDescTxt, true);
        AddColumnLayout(NetChangeColumnNameTxt, NetChangeColumnDescTxt, false);

        if (GeneralLedgerSetup."Acc. Sched. for Balance Sheet" = '') or ForceCreateAccountSchedule then begin
            GeneralLedgerSetup."Acc. Sched. for Balance Sheet" := CreateUniqueAccSchedName(BalanceSheetCodeTxt);
            CreateAccountScheduleForBalanceSheet := true;
        end;

        if (GeneralLedgerSetup."Acc. Sched. for Income Stmt." = '') or ForceCreateAccountSchedule then begin
            GeneralLedgerSetup."Acc. Sched. for Income Stmt." := CreateUniqueAccSchedName(IncomeStmdCodeTxt);
            CreateAccountScheduleForIncomeStatement := true;
        end;

        if (GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt" = '') or ForceCreateAccountSchedule then begin
            GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt" := CreateUniqueAccSchedName(CashFlowCodeTxt);
            CreateAccountScheduleForCashFlowStatement := true;
        end;

        if (GeneralLedgerSetup."Acc. Sched. for Retained Earn." = '') or ForceCreateAccountSchedule then begin
            GeneralLedgerSetup."Acc. Sched. for Retained Earn." := CreateUniqueAccSchedName(RetainedEarnCodeTxt);
            CreateAccountScheduleForRetainedEarnings := true;
        end;

        GeneralLedgerSetup.Modify();

        AddAccountSchedule(GeneralLedgerSetup."Acc. Sched. for Balance Sheet", BalanceSheetDescTxt, BalanceColumnNameTxt);
        AddAccountSchedule(GeneralLedgerSetup."Acc. Sched. for Income Stmt.", IncomeStmdDescTxt, NetChangeColumnNameTxt);
        AddAccountSchedule(GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt", CashFlowDescTxt, NetChangeColumnNameTxt);
        AddAccountSchedule(GeneralLedgerSetup."Acc. Sched. for Retained Earn.", RetainedEarnDescTxt, NetChangeColumnNameTxt);
    end;

    local procedure AddAccountSchedule(NewName: Code[10]; NewDescription: Text[80]; DefaultColumnName: Code[10])
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        if AccScheduleName.Get(NewName) then
            exit;
        AccScheduleName.Init();
        AccScheduleName.Name := NewName;
        AccScheduleName.Description := NewDescription;
        AccScheduleName."Default Column Layout" := DefaultColumnName;
        AccScheduleName.Insert();
    end;

    local procedure AddColumnLayout(NewName: Code[10]; NewDescription: Text[80]; IsBalance: Boolean)
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
    begin
        if ColumnLayoutName.Get(NewName) then
            exit;
        ColumnLayoutName.Init();
        ColumnLayoutName.Name := NewName;
        ColumnLayoutName.Description := NewDescription;
        ColumnLayoutName.Insert();

        ColumnLayout.Init();
        ColumnLayout."Column Layout Name" := NewName;
        ColumnLayout."Line No." := 10000;
        ColumnLayout."Column Header" := CopyStr(NewDescription, 1, MaxStrLen(ColumnLayout."Column Header"));
        if IsBalance then
            ColumnLayout."Column Type" := ColumnLayout."Column Type"::"Balance at Date"
        else
            ColumnLayout."Column Type" := ColumnLayout."Column Type"::"Net Change";
        ColumnLayout.Insert();
    end;

    procedure GetGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    var
        CategGenerateAccSchedules: Codeunit "Categ. Generate Acc. Schedules";
    begin
        GeneralLedgerSetup.Get();
        if AnyAccSchedSetupMissing(GeneralLedgerSetup) then begin
            InitializeStandardAccountSchedules;
            GeneralLedgerSetup.Get();
            if AnyAccSchedSetupMissing(GeneralLedgerSetup) then
                Error(MissingSetupErr, GeneralLedgerSetup.FieldCaption("Acc. Sched. for Balance Sheet"), GeneralLedgerSetup.TableCaption);
            Commit();

            if CreateAccountScheduleForBalanceSheet then begin
                CategGenerateAccSchedules.CreateBalanceSheet;
                CreateAccountScheduleForBalanceSheet := false;
            end;

            if CreateAccountScheduleForCashFlowStatement then begin
                CategGenerateAccSchedules.CreateCashFlowStatement;
                CreateAccountScheduleForCashFlowStatement := false;
            end;

            if CreateAccountScheduleForIncomeStatement then begin
                CategGenerateAccSchedules.CreateIncomeStatement;
                CreateAccountScheduleForIncomeStatement := false;
            end;

            if CreateAccountScheduleForRetainedEarnings then begin
                CategGenerateAccSchedules.CreateRetainedEarningsStatement;
                CreateAccountScheduleForRetainedEarnings := false;
            end;
            Commit();
        end;
    end;

    local procedure CreateUniqueAccSchedName(SuggestedName: Code[10]): Code[10]
    var
        AccScheduleName: Record "Acc. Schedule Name";
        i: Integer;
    begin
        while AccScheduleName.Get(SuggestedName) and (i < 1000) do
            SuggestedName := GenerateNextName(SuggestedName, i);
        exit(SuggestedName);
    end;

    local procedure GenerateNextName(SuggestedName: Code[10]; var i: Integer): Code[10]
    var
        NumPart: Code[3];
    begin
        i += 1;
        NumPart := CopyStr(Format(i), 1, MaxStrLen(NumPart));
        exit(CopyStr(SuggestedName, 1, MaxStrLen(SuggestedName) - StrLen(NumPart)) + NumPart);
    end;

    procedure RunAccountScheduleReport(AccSchedName: Code[10])
    var
        AccountSchedule: Report "Account Schedule";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRunAccountScheduleReport(AccSchedName, IsHandled);
        if IsHandled then
            exit;

        AccountSchedule.InitAccSched;
        AccountSchedule.SetAccSchedNameNonEditable(AccSchedName);
        AccountSchedule.Run();
    end;

    procedure ConfirmAndRunGenerateAccountSchedules()
    begin
        if GLSetupAllAccScheduleNamesNotDefined() then begin
            Codeunit.Run(Codeunit::"Categ. Generate Acc. Schedules");
            exit;
        end;

        case StrMenu(GenerateAccountSchedulesOptionsTxt, 1, OverwriteConfirmationQst) of
            1:
                begin
                    ForceInitializeStandardAccountSchedules();
                    Codeunit.Run(Codeunit::"Categ. Generate Acc. Schedules");
                end;
            2:
                Codeunit.Run(Codeunit::"Categ. Generate Acc. Schedules");
        end;
    end;

    local procedure AnyAccSchedSetupMissing(var GeneralLedgerSetup: Record "General Ledger Setup"): Boolean
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        if (GeneralLedgerSetup."Acc. Sched. for Balance Sheet" = '') or
           (GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt" = '') or
           (GeneralLedgerSetup."Acc. Sched. for Income Stmt." = '') or
           (GeneralLedgerSetup."Acc. Sched. for Retained Earn." = '')
        then
            exit(true);
        if not AccScheduleName.Get(GeneralLedgerSetup."Acc. Sched. for Balance Sheet") then
            exit(true);
        if not AccScheduleName.Get(GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt") then
            exit(true);
        if not AccScheduleName.Get(GeneralLedgerSetup."Acc. Sched. for Income Stmt.") then
            exit(true);
        if not AccScheduleName.Get(GeneralLedgerSetup."Acc. Sched. for Retained Earn.") then
            exit(true);
        exit(false);
    end;

    procedure GLSetupAllAccScheduleNamesNotDefined(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(
            (GeneralLedgerSetup."Acc. Sched. for Balance Sheet" = '') and
           (GeneralLedgerSetup."Acc. Sched. for Cash Flow Stmt" = '') and
           (GeneralLedgerSetup."Acc. Sched. for Income Stmt." = '') and
           (GeneralLedgerSetup."Acc. Sched. for Retained Earn." = ''));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnInitializeCompany()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if not GLAccountCategory.IsEmpty() then
            exit;

        OnBeforeInitializeCompany;

        InitializeAccountCategories;
        CODEUNIT.Run(CODEUNIT::"Categ. Generate Acc. Schedules");

        OnAfterInitializeCompany;
    end;

    procedure GetCurrentAssets(): Text
    begin
        exit(CurrentAssetsTxt);
    end;

    procedure GetAR(): Text
    begin
        exit(ARTxt);
    end;

    procedure GetCash(): Text
    begin
        exit(CashTxt);
    end;

    procedure GetPrepaidExpenses(): Text
    begin
        exit(PrepaidExpensesTxt);
    end;

    procedure GetInventory(): Text
    begin
        exit(InventoryTxt);
    end;

    procedure GetFixedAssets(): Text
    begin
        exit(FixedAssetsTxt);
    end;

    procedure GetEquipment(): Text
    begin
        exit(EquipementTxt);
    end;

    procedure GetAccumDeprec(): Text
    begin
        exit(AccumDeprecTxt);
    end;

    procedure GetCurrentLiabilities(): Text
    begin
        exit(CurrentLiabilitiesTxt);
    end;

    procedure GetPayrollLiabilities(): Text
    begin
        exit(PayrollLiabilitiesTxt);
    end;

    procedure GetLongTermLiabilities(): Text
    begin
        exit(LongTermLiabilitiesTxt);
    end;

    procedure GetCommonStock(): Text
    begin
        exit(CommonStockTxt);
    end;

    procedure GetRetEarnings(): Text
    begin
        exit(RetEarningsTxt);
    end;

    procedure GetDistrToShareholders(): Text
    begin
        exit(DistrToShareholdersTxt);
    end;

    procedure GetIncomeService(): Text
    begin
        exit(IncomeServiceTxt);
    end;

    procedure GetIncomeProdSales(): Text
    begin
        exit(IncomeProdSalesTxt);
    end;

    procedure GetIncomeSalesDiscounts(): Text
    begin
        exit(IncomeSalesDiscountsTxt);
    end;

    procedure GetIncomeSalesReturns(): Text
    begin
        exit(IncomeSalesReturnsTxt);
    end;

    procedure GetIncomeInterest(): Text
    begin
        exit(IncomeInterestTxt);
    end;

    procedure GetCOGSLabor(): Text
    begin
        exit(COGSLaborTxt);
    end;

    procedure GetCOGSMaterials(): Text
    begin
        exit(COGSMaterialsTxt);
    end;

    procedure GetCOGSDiscountsGranted(): Text
    begin
        exit(COGSDiscountsGrantedTxt);
    end;

    procedure GetRentExpense(): Text
    begin
        exit(RentExpenseTxt);
    end;

    procedure GetAdvertisingExpense(): Text
    begin
        exit(AdvertisingExpenseTxt);
    end;

    procedure GetInterestExpense(): Text
    begin
        exit(InterestExpenseTxt);
    end;

    procedure GetFeesExpense(): Text
    begin
        exit(FeesExpenseTxt);
    end;

    procedure GetInsuranceExpense(): Text
    begin
        exit(InsuranceExpenseTxt);
    end;

    procedure GetPayrollExpense(): Text
    begin
        exit(PayrollExpenseTxt);
    end;

    procedure GetBenefitsExpense(): Text
    begin
        exit(BenefitsExpenseTxt);
    end;

    procedure GetRepairsExpense(): Text
    begin
        exit(RepairsTxt);
    end;

    procedure GetUtilitiesExpense(): Text
    begin
        exit(UtilitiesExpenseTxt);
    end;

    procedure GetOtherIncomeExpense(): Text
    begin
        exit(OtherIncomeExpenseTxt);
    end;

    procedure GetTaxExpense(): Text
    begin
        exit(TaxExpenseTxt);
    end;

    procedure GetTravelExpense(): Text
    begin
        exit(TravelExpenseTxt);
    end;

    procedure GetVehicleExpenses(): Text
    begin
        exit(VehicleExpensesTxt);
    end;

    procedure GetBadDebtExpense(): Text
    begin
        exit(BadDebtExpenseTxt);
    end;

    procedure GetSalariesExpense(): Text
    begin
        exit(SalariesExpenseTxt);
    end;

    procedure GetJobsCost(): Text
    begin
        exit(JobsCostTxt);
    end;

    procedure GetIncomeJobs(): Text
    begin
        exit(IncomeJobsTxt);
    end;

    procedure GetJobSalesContra(): Text
    begin
        exit(JobSalesContraTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetBI21Software(): Text
    begin
        // NAVCZ
        exit(BI21_SoftwareTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetBII12Buildings(): Text
    begin
        // NAVCZ
        exit(BII12_BuildingsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetBII2FixedMovablesAndtheCollectionsOfFixedMovables(): Text
    begin
        // NAVCZ
        exit(BII2_FixedMovablesandtheCollectionsofFixedMovablesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetBI52IntangibleFixedAssestsInProgress(): Text
    begin
        // NAVCZ
        exit(BI52_IntangibleFixedAssestsinProgressTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetBII52TangibleFixedAssetsInProgress(): Text
    begin
        // NAVCZ
        exit(BII52_TangibleFixedAssetsinProgressTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCI1Material(): Text
    begin
        // NAVCZ
        exit(CI1_MaterialTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCI2WorkinProgressAndSemiFinishedGoods(): Text
    begin
        // NAVCZ
        exit(CI2_WorkinProgressandSemiFinishedGoodsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCI31FinishedProducts(): Text
    begin
        // NAVCZ
        exit(CI31_FinishedProductsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCI32Goods(): Text
    begin
        // NAVCZ
        exit(CI32_GoodsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCIV1Cash(): Text
    begin
        // NAVCZ
        exit(CIV1_CashTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCIV2BankAccounts(): Text
    begin
        // NAVCZ
        exit(CIV2_BankAccountsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCII2PayablesToCreditInstitutions(): Text
    begin
        // NAVCZ
        exit(CII2_PayablestoCreditInstitutionsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCIII2OtherShorttermFinancialAssets(): Text
    begin
        // NAVCZ
        exit(CIII2_OtherShorttermFinancialAssetsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCII21TradeReceivables(): Text
    begin
        // NAVCZ
        exit(CII21_TradeReceivablesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCII244ShorttermAdvancedPayments(): Text
    begin
        // NAVCZ
        exit(CII244_ShorttermAdvancedPaymentsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCII4TradePayables(): Text
    begin
        // NAVCZ
        exit(CII4_TradePayablesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCII3ShorttermAdvancePaymentsReceived(): Text
    begin
        // NAVCZ
        exit(CII3_ShorttermAdvancePaymentsReceivedTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCII83PayrollPayables(): Text
    begin
        // NAVCZ
        exit(CII83_PayrollPayablesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCII84PayablesSocialSecurityAndHealthInsurance(): Text
    begin
        // NAVCZ
        exit(CII84_PayablesSocialSecurityandHealthInsuranceTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCII85StateTaxLiabilitiesAndGrants(): Text
    begin
        // NAVCZ
        exit(CII85_StateTaxLiabilitiesAndGrantsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCII245EstimatedReceivables(): Text
    begin
        // NAVCZ
        exit(CII245_EstimatedReceivablesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCII86EstimatedPayables(): Text
    begin
        // NAVCZ
        exit(CII86_EstimatedPayables);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCII246OtherReceivables(): Text
    begin
        // NAVCZ
        exit(CII246_OtherReceivablesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetAI1RegisteredCapital(): Text
    begin
        // NAVCZ
        exit(AI1_RegisteredCapitalTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetAIII1OtherReserveFunds(): Text
    begin
        // NAVCZ
        exit(AIII1_OtherReserveFundsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetAIV1RetainedEarningsFromPreviousYears(): Text
    begin
        // NAVCZ
        exit(AIV1_RetainedEarningsfromPreviousYearsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCI2PayablesToCreditInstitutions(): Text
    begin
        // NAVCZ
        exit(CI2_PayablestoCreditInstitutionsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetA2MaterialAndEnergyConsumption(): Text
    begin
        // NAVCZ
        exit(A2_MaterialAndEnergyConsumptionTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetA1CostsOfGoodsSold(): Text
    begin
        // NAVCZ
        exit(A1_CostsofGoodsSoldTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetA3Services(): Text
    begin
        // NAVCZ
        exit(A3_ServicesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetD1WagesAndSalaries(): Text
    begin
        // NAVCZ
        exit(D1_WagesandSalariesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetD21SocialSecurityandHealthInsurance(): Text
    begin
        // NAVCZ
        exit(D21_SocialSecurityandHealthInsuranceTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetD22OtherCosts(): Text
    begin
        // NAVCZ
        exit(D22_OtherCostsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetF3TaxesAndFeesInOperatingPart(): Text
    begin
        // NAVCZ
        exit(F3_TaxesandFeesinOperatingPartTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetF1NetBookValueOfFixedAssetsSold(): Text
    begin
        // NAVCZ
        exit(F1_NetBookValueOfFixedAssetsSoldTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetF2NetBookValueofMaterialSold(): Text
    begin
        // NAVCZ
        exit(F2_NetBookValueofMaterialSoldTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetF5OtherOperatingCosts(): Text
    begin
        // NAVCZ
        exit(F5_OtherOperatingCostsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetE11IntangibleandTangibleFixedAssetsAdjustmentsPermanent(): Text
    begin
        // NAVCZ
        exit(E11_IntangibleandTangibleFixedAssetsAdjustmentsPermanentTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetF4ProvisionsinOperatingPartandComplexPrepaidExpenses(): Text
    begin
        // NAVCZ
        exit(F4_ProvisionsinOperatingPartandComplexPrepaidExpensesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetE3ReceivablesAdjustments(): Text
    begin
        // NAVCZ
        exit(E3_ReceivablesAdjustmentsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetE12IntangibleAndTangibleFixedAssetsAdjustmentsTemporary(): Text
    begin
        // NAVCZ
        exit(E12_IntangibleandTangibleFixedAssetsAdjustmentsTemporaryTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetJ2OtherInterestCostsAndSimilarCosts(): Text
    begin
        // NAVCZ
        exit(J2_OtherInterestCostsandSimilarCostsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetKOtherFinancialCosts(): Text
    begin
        // NAVCZ
        exit(K_OtherFinancialCostsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetIAdjustmentsandProvisionsInFinancialPart(): Text
    begin
        // NAVCZ
        exit(I_AdjustmentsandProvisionsinFinancialPartTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetBChangesInInventoryOfOwnProducts(): Text
    begin
        // NAVCZ
        exit(B_ChangesinInventoryofOwnProductsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCCapitalization(): Text
    begin
        // NAVCZ
        exit(C_CapitalizationTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetL1IncomeTaxDue(): Text
    begin
        // NAVCZ
        exit(L1_IncomeTaxDueTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetL2IncomeTaxDeferred(): Text
    begin
        // NAVCZ
        exit(L2_IncomeTaxDeferredTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetIRevenuesFromOwnProductsAndServices(): Text
    begin
        // NAVCZ
        exit(I_RevenuesfromOwnProductsandServicesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetIIRevenuesFromMerchandise(): Text
    begin
        // NAVCZ
        exit(II_RevenuesfromMerchandiseTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetIII1RevenuesFromSalesOfFixedAssets(): Text
    begin
        // NAVCZ
        exit(III1_RevenuesfromSalesofFixedAssetsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetIII2RevenuesOfMaterialSold(): Text
    begin
        // NAVCZ
        exit(III2_RevenuesfromSalesofMaterialTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetIII3AnotherOperatingRevenues(): Text
    begin
        // NAVCZ
        exit(III3_AnotherOperatingRevenuesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetVI2OtherInterestRevenuesAndSimilarRevenues(): Text
    begin
        // NAVCZ
        exit(VI2_OtherInterestRevenuesandSimilarRevenuesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetVIIOtherFinancialRevenues(): Text
    begin
        // NAVCZ
        exit(VII_OtherFinancialRevenuesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetV1RevenuesFromOtherLongtermFinancialAssetsControlledOrControlling(): Text
    begin
        // NAVCZ
        exit(V1_RevenuesfromOtherLongtermFinancialAssetsControlledorControllingTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetD1PrepaidExpenses(): Text
    begin
        // NAVCZ
        exit(D1_PrepaidExpensesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetD2ComplexPrepaidExpenses(): Text
    begin
        // NAVCZ
        exit(D2_ComplexPrepaidExpensesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetD3AccruedIncomes(): Text
    begin
        // NAVCZ
        exit(D3_AccruedIncomesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetD1AccruedExpenses(): Text
    begin
        // NAVCZ
        exit(D1_AccruedExpensesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetD2DeferredRevenues(): Text
    begin
        // NAVCZ
        exit(D2_DeferredRevenuesTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetBI1IntangibleResultsofResearchandDevelopment(): Text
    begin
        // NAVCZ
        exit(BI1_IntangibleResultsofResearchandDevelopmentTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetBI22OtherValuableRights(): Text
    begin
        // NAVCZ
        exit(BI22_OtherValuableRightsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetBI3Goodwill(): Text
    begin
        // NAVCZ
        exit(BI3_GoodwillTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetBI4OtherIntangibleFixedAssets(): Text
    begin
        // NAVCZ
        exit(BI4_OtherIntangibleFixedAssetsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetBII11Lands(): Text
    begin
        // NAVCZ
        exit(BII11_LandsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetB2IncomeTaxProvision(): Text
    begin
        // NAVCZ
        exit(B2_IncomeTaxProvisionTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetB4OtherProvisions(): Text
    begin
        // NAVCZ
        exit(B4_OtherProvisionsTxt);
    end;

    [Obsolete('The function is moved to Core Localization Pack.', '19.0')]
    procedure GetCI3LongtermAdvancePaymentsReceived(): Text
    begin
        // NAVCZ
        exit(CI3_LongtermAdvancePaymentsReceivedTxt);
    end;

    procedure GetAccountCategory(var GLAccountCategory: Record "G/L Account Category"; Category: Option): Boolean
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetRange("Parent Entry No.", 0);
        exit(GLAccountCategory.FindFirst());
    end;

    procedure GetAccountSubcategory(var GLAccountCategory: Record "G/L Account Category"; Category: Option; Description: Text): Boolean
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetFilter("Parent Entry No.", '<>%1', 0);
        GLAccountCategory.SetRange(Description, Description);
        exit(GLAccountCategory.FindFirst());
    end;

    procedure GetSubcategoryEntryNo(Category: Option; SubcategoryDescription: Text): Integer
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetRange(Description, SubcategoryDescription);
        if GLAccountCategory.FindFirst() then
            exit(GLAccountCategory."Entry No.");
    end;

    procedure CheckGLAccount(AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean; AccountCategory: Option; AccountSubcategory: Text)
    begin
        CheckGLAccount(0, 0, AccNo, CheckProdPostingGroup, CheckDirectPosting, AccountCategory, AccountSubcategory);
    end;

    procedure CheckGLAccount(TableNo: Integer; FieldNo: Integer; AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean; AccountCategory: Option; AccountSubcategory: Text)
    var
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAccount(TableNo, FieldNo, AccNo, CheckProdPostingGroup, CheckDirectPosting, AccountCategory, AccountSubcategory, IsHandled);
        if IsHandled then
            exit;

        if AccNo = '' then
            exit;

        GLAcc.Get(AccNo);
        GLAcc.CheckGLAcc;
        if CheckProdPostingGroup then
            GLAcc.TestField("Gen. Prod. Posting Group");
        if CheckDirectPosting then
            GLAcc.TestField("Direct Posting", true);
        if GLAcc."Account Category" = GLAcc."Account Category"::" " then begin
            GLAcc.Validate("Account Category", AccountCategory);
            if AccountSubcategory <> '' then
                GLAcc.Validate("Account Subcategory Entry No.", GetSubcategoryEntryNo(AccountCategory, AccountSubcategory));
            GLAcc.Modify();
        end;
    end;

    procedure CheckGLAccountWithoutCategory(AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean)
    var
        OptionValueOutOfRange: Integer;
    begin
        OptionValueOutOfRange := -1;
        CheckGLAccount(AccNo, CheckProdPostingGroup, CheckDirectPosting, OptionValueOutOfRange, '');
    end;

    procedure LookupGLAccount(var AccountNo: Code[20]; AccountCategory: Option; AccountSubcategoryFilter: Text)
    begin
        LookupGLAccount(0, 0, AccountNo, AccountCategory, AccountSubcategoryFilter);
    end;

    procedure LookupGLAccount(TableNo: Integer; FieldNo: Integer; var AccountNo: Code[20]; AccountCategory: Option; AccountSubcategoryFilter: Text)
    var
        GLAccount: Record "G/L Account";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountList: Page "G/L Account List";
        EntryNoFilter: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupGLAccount(TableNo, FieldNo, AccountNo, AccountCategory, AccountSubcategoryFilter, IsHandled);
        if IsHandled then
            exit;

        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccountCategory.SetRange("Account Category", AccountCategory);
        GLAccountCategory.SetFilter(Description, AccountSubcategoryFilter);
        if not GLAccountCategory.IsEmpty() then begin
            EntryNoFilter := '';
            GLAccountCategory.FindSet();
            repeat
                EntryNoFilter := EntryNoFilter + Format(GLAccountCategory."Entry No.") + '|';
            until GLAccountCategory.Next() = 0;
            EntryNoFilter := CopyStr(EntryNoFilter, 1, StrLen(EntryNoFilter) - 1);
            GLAccount.SetRange("Account Category", GLAccountCategory."Account Category");
            GLAccount.SetFilter("Account Subcategory Entry No.", EntryNoFilter);
            if not GLAccount.FindFirst() then begin
                GLAccount.SetRange("Account Category", 0);
                GLAccount.SetRange("Account Subcategory Entry No.", 0);
            end;
        end;
        GLAccountList.SetTableView(GLAccount);
        GLAccountList.LookupMode(true);
        if AccountNo <> '' then
            if GLAccount.Get(AccountNo) then
                GLAccountList.SetRecord(GLAccount);
        if GLAccountList.RunModal = ACTION::LookupOK then begin
            GLAccountList.GetRecord(GLAccount);
            AccountNo := GLAccount."No.";
        end;
    end;

    procedure LookupGLAccountWithoutCategory(var AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        GLAccountList: Page "G/L Account List";
    begin
        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccountList.SetTableView(GLAccount);
        GLAccountList.LookupMode(true);
        if AccountNo <> '' then
            if GLAccount.Get(AccountNo) then
                GLAccountList.SetRecord(GLAccount);
        if GLAccountList.RunModal = ACTION::LookupOK then begin
            GLAccountList.GetRecord(GLAccount);
            AccountNo := GLAccount."No.";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeCompany()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeCompany()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRunAccountScheduleReport(AccSchedName: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeAccountCategories(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccount(TableNo: Integer; FieldNo: Integer; AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean; var AccountCategory: Option; var AccountSubcategory: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupGLAccount(TableNo: Integer; FieldNo: Integer; var AccountNo: Code[20]; var AccountCategory: Option; var AccountSubcategoryFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeAccountCategories()
    begin
    end;
}

#endif