namespace System.Environment.Configuration;

#if not CLEAN23
using Microsoft.Finance.Currency;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Posting;
using Microsoft.Service.Posting;
using System.Environment;
using System.Telemetry;
using System.Reflection;
#endif
#if not CLEAN21
using System.Feedback;
#endif

codeunit 265 "Feature Key Management"
{
    Access = Internal;

    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#if not CLEAN23
        FeatureEventConflictErr: Label 'Feature ''%1'' cannot be enabled because there are extensions with subscriptions to old Invoice Posting implementation. If you enable now, these extensions will stop working properly.', Comment = '%1 - feature description';

        AllowMultipleCustVendPostingGroupsLbl: Label 'AllowMultipleCustVendPostingGroups', Locked = true;
        ExtensibleExchangeRateAdjustmentLbl: Label 'ExtensibleExchangeRateAdjustment', Locked = true;
        ExtensibleInvoicePostingEngineLbl: Label 'ExtensibleInvoicePostingEngine', Locked = true;
#endif
        AutomaticAccountCodesTxt: Label 'AutomaticAccountCodes', Locked = true;
        SIEAuditFileExportTxt: label 'SIEAuditFileExport', Locked = true;
#if not CLEAN21
        ModernActionBarLbl: Label 'ModernActionBar', Locked = true;
#endif
#if not CLEAN23
        EU3PartyTradePurchaseTxt: Label 'EU3PartyTradePurchase', Locked = true;
#endif
#if not CLEAN23
    [Obsolete('Feature Multiple Posting Groups enabled by default.', '23.0')]
    procedure IsAllowMultipleCustVendPostingGroupsEnabled(): Boolean
    begin
        exit(true);
    end;
#endif

#if not CLEAN23
    procedure IsExtensibleExchangeRateAdjustmentEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetExtensibleExchangeRateAdjustmentFeatureKey()));
    end;
#endif

#if not CLEAN23
    procedure IsExtensibleInvoicePostingEngineEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetExtensibleInvoicePostingEngineFeatureKey()));
    end;
#endif

#if not CLEAN21
    internal procedure IsModernActionBarEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetModernActionBarFeatureKey()));
    end;
#endif

    procedure IsAutomaticAccountCodesEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetAutomaticAccountCodesFeatureKey()));
    end;

    procedure IsSIEAuditFileExportEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetSIEAuditFileExportFeatureKeyId()));
    end;

#if not CLEAN23
    procedure IsEU3PartyTradePurchaseEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetEU3PartyTradePurchaseFeatureKeyId()));
    end;
#endif

#if not CLEAN23
    internal procedure GetAllowMultipleCustVendPostingGroupsFeatureKey(): Text[50]
    begin
        exit(AllowMultipleCustVendPostingGroupsLbl);
    end;
#endif

#if not CLEAN23
    local procedure GetExtensibleExchangeRateAdjustmentFeatureKey(): Text[50]
    begin
        exit(ExtensibleExchangeRateAdjustmentLbl);
    end;
#endif

#if not CLEAN23
    local procedure GetExtensibleInvoicePostingEngineFeatureKey(): Text[50]
    begin
        exit(ExtensibleInvoicePostingEngineLbl);
    end;
#endif
    local procedure GetAutomaticAccountCodesFeatureKey(): Text[50]
    begin
        exit(AutomaticAccountCodesTxt);
    end;

    local procedure GetSIEAuditFileExportFeatureKeyId(): Text[50]
    begin
        exit(SIEAuditFileExportTxt);
    end;
#if not CLEAN23
    local procedure GetEU3PartyTradePurchaseFeatureKeyId(): Text[50]
    begin
        exit(EU3PartyTradePurchaseTxt);
    end;
#endif

#if not CLEAN21
    local procedure GetModernActionBarFeatureKey(): Text[50]
    begin
        exit(ModernActionBarLbl);
    end;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterFeatureEnableConfirmed', '', false, false)]
    local procedure HandleOnAfterFeatureEnableConfirmed(var FeatureKey: Record "Feature Key")
#if not CLEAN23
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
#endif
    begin
#if not CLEAN23
        // Check feature dependencies and if feature can be enabled for Production environment
        case FeatureKey.ID of
            ExtensibleExchangeRateAdjustmentLbl:
                if not CheckOldAdjustExchangeRatesEvents() then
                    error(FeatureEventConflictErr, FeatureKey.Description);
            ExtensibleInvoicePostingEngineLbl:
                if not CheckOldInvoicePostingEvents() then
                    error(FeatureEventConflictErr, FeatureKey.Description);
        end;
        // Log feature uptake
        case FeatureKey.ID of
#if not CLEAN21
            ModernActionBarLbl:
                FeatureTelemetry.LogUptake('0000I8D', ModernActionBarLbl, Enum::"Feature Uptake Status"::Discovered);
#endif
            ExtensibleExchangeRateAdjustmentLbl:
                FeatureTelemetry.LogUptake('0000JR9', ExtensibleExchangeRateAdjustmentLbl, Enum::"Feature Uptake Status"::Discovered);
            ExtensibleInvoicePostingEngineLbl:
                FeatureTelemetry.LogUptake('0000JRA', ExtensibleInvoicePostingEngineLbl, Enum::"Feature Uptake Status"::Discovered);
            EU3PartyTradePurchaseTxt:
                FeatureTelemetry.LogUptake('0000JRC', EU3PartyTradePurchaseTxt, Enum::"Feature Uptake Status"::Discovered);
        end;
#endif
    end;

#if not CLEAN21
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterFeatureDisableConfirmed', '', false, false)]
    local procedure HandleOnAfterFeatureDisableConfirmed(FeatureKey: Record "Feature Key")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CustomerExperienceSurvey: Codeunit "Customer Experience Survey";
        FormsProId: Text;
        FormsProEligibilityId: Text;
        IsEligible: Boolean;
    begin
        if FeatureKey.ID = ModernActionBarLbl then begin
            FeatureTelemetry.LogUptake('0000I8E', ModernActionBarLbl, Enum::"Feature Uptake Status"::Undiscovered);
            if CustomerExperienceSurvey.RegisterEventAndGetEligibility('modernactionbar_event', 'modernactionbar', FormsProId, FormsProEligibilityId, IsEligible) then
                if IsEligible then
                    CustomerExperienceSurvey.RenderSurvey('modernactionbar', FormsProId, FormsProEligibilityId);
        end;
    end;
#endif

#if not CLEAN23
    local procedure CheckOldAdjustExchangeRatesEvents(): Boolean;
    var
        EventSubscription: Record "Event Subscription";
        TempEventSubscription: Record "Event Subscription" temporary;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckOldAdjustExchangeRatesEvents(Result, IsHandled);
        if IsHandled then
            exit(Result);

        // add all subsctibers to events from table 49 "Invoice Post. Buffer"
        EventSubscription.Reset();
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Report);
        EventSubscription.SetRange("Publisher Object ID", Report::"Adjust Exchange Rates");
        EventSubscription.SetFilter("Subscriber Codeunit ID", '150000..'); // filter out MS objects
        if EventSubscription.FindSet() then
            repeat
                TempEventSubscription := EventSubscription;
                TempEventSubscription.Insert();
            until EventSubscription.Next() = 0;

        if not TempEventSubscription.IsEmpty() then
            Page.RunModal(Page::"Event Subscriptions", TempEventSubscription);

        exit(TempEventSubscription.IsEmpty());
    end;
#endif

#if not CLEAN23
    local procedure CheckOldInvoicePostingEvents(): Boolean;
    var
        EventSubscription: Record "Event Subscription";
        TempPublisherBuffer: Record "Event Subscription" temporary;
        TempEventSubscription: Record "Event Subscription" temporary;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckOldInvoicePostingEvents(Result, IsHandled);
        if IsHandled then
            exit(Result);

        // add all subsctibers to events from table 49 "Invoice Post. Buffer"
        EventSubscription.Reset();
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Table);
        EventSubscription.SetRange("Publisher Object ID", Database::"Invoice Post. Buffer");
        EventSubscription.SetRange("Subscriber Instance", 'Static-Automatic');
        EventSubscription.SetFilter("Subscriber Codeunit ID", '150000..'); // filter out MS objects
        if EventSubscription.FindSet() then
            repeat
                TempEventSubscription := EventSubscription;
                TempEventSubscription.Insert();
            until EventSubscription.Next() = 0;

        // all all Invoice Posting related subscribers from Purchase/Sales/Services posting codeunits
        BuildInvoicePostingCheckList(TempPublisherBuffer);
        EventSubscription.Reset();
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Codeunit);
        EventSubscription.SetFilter("Publisher Object ID", '80|90|5986|5987|5988');
        EventSubscription.SetRange("Subscriber Instance", 'Static-Automatic');
        EventSubscription.SetFilter("Subscriber Codeunit ID", '150000..'); // filter out MS objects
        if EventSubscription.FindSet() then
            repeat
                TempPublisherBuffer.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type");
                TempPublisherBuffer.SetRange("Publisher Object ID", EventSubscription."Publisher Object ID");
                TempPublisherBuffer.SetRange("Published Function", EventSubscription."Published Function");
                if not TempPublisherBuffer.IsEmpty() then begin
                    TempEventSubscription := EventSubscription;
                    TempEventSubscription.Insert();
                end;
            until EventSubscription.Next() = 0;

        if not TempEventSubscription.IsEmpty() then
            Page.RunModal(Page::"Event Subscriptions", TempEventSubscription);

        exit(TempEventSubscription.IsEmpty());
    end;

    local procedure BuildInvoicePostingCheckList(var TempPublisherBuffer: Record "Event Subscription" temporary)
    begin
        // Sales
        AddEvent(Codeunit::"Sales-Post", 'OnAfterCreatePostedDeferralScheduleFromSalesDoc', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterGetSalesAccount', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeGetSalesAccount', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterFillInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterFillDeferralPostingBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterInvoicePostingBufferAssignAmounts', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterInvoicePostingBufferSetAmounts', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterPostCustomerEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterPostBalancingEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterPostInvPostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforePostCustomerEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeRunPostCustomerEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeRunGenJnlPostLine', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforePostBalancingEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforePostInvPostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforePostInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterSetApplyToDocNo', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeCalcInvoiceDiscountPosting', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeCalcInvoiceDiscountPostingProcedure', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnCalcLineDiscountPostingProcedure', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeCalcLineDiscountPosting', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeSetAmountsForBalancingEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeTempDeferralLineInsert', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnBeforeDeferrals', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeFillDeferralPostingBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeFillInvoicePostingBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnBeforeSetAccount', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnAfterSetLineDiscAccount', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnAfterSetInvDiscAccount', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnAfterUpdateInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnAfterCalcInvoiceDiscountPosting', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnAfterCalcLineDiscountPosting', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnBeforeSetInvDiscAccount', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnBeforeSetLineDiscAccount', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnPostBalancingEntryOnAfterInitNewLine', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnPostBalancingEntryOnAfterFindCustLedgEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnPostBalancingEntryOnBeforeFindCustLedgEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnPostInvoicePostBufferOnAfterPostSalesGLAccounts', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnPostInvoicePostBufferOnBeforeTempInvoicePostBufferDeleteAll', TempPublisherBuffer);
        AddEvent(Codeunit::"Sales-Post", 'OnPostInvoicePostBufferLineOnAfterCopyFromInvoicePostBuffer', TempPublisherBuffer);

        // Purchase
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterCalcInvoiceDiscountPosting', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterCreatePostedDeferralScheduleFromPurchDoc', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterFillInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterInitVATBase', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterPostVendorEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterPostBalancingEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterPostInvPostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterSetApplyToDocNo', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeCalcLineDiscountPosting', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeCalculateVATAmountInBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeFillInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeInitNewGenJnlLineFromPostInvoicePostBufferLine', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeInitGenJnlLineAmountFieldsFromTotalPurchLine', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeInvoicePostingBufferSetAmounts', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforePostInvoicePostBufferLine', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforePostVendorEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforePostBalancingEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforePostInvPostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforePostInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeTempDeferralLineInsert', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeFillDeferralPostingBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeFillInvoicePostBufferFADiscount', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnCalcDeferralAmountsOnAfterTempDeferralHeaderInsert', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostBufferOnAfterInitAmounts', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostingBufferOnAfterSetLineDiscAccount', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostingBufferOnAfterUpdateInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostBufferOnAfterSetShouldCalcDiscounts', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostingBufferOnBeforeSetAccount', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnPostBalancingEntryOnAfterInitNewLine', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnPostInvoicePostingBufferOnAfterVATPostingSetupGet', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnPostVendorEntryOnAfterInitNewLine', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnPostVendorEntryOnBeforeInitNewLine', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeRunGenJnlPostLine', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostBufferOnBeforePreparePurchase', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillDeferralPostingBufferOnAfterInitFromDeferralLine', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostBufferOnBeforeProcessInvoiceDiscounts', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnPostInvoicePostBufferLineOnAfterCopyFromInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnPostGLAndVendorOnBeforePostBalancingEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeCheckItemQuantityPurchCredit', TempPublisherBuffer);

        // Service
        AddEvent(Codeunit::"Serv-Documents Mgt.", 'OnPostDocumentLinesOnBeforePostInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnAfterPostCustomerEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnAfterPostBalancingEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnAfterPostInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnBeforePostCustomerEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnBeforePostBalancingEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnBeforePostInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnPostBalancingEntryOnBeforeFindCustLedgerEntry', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnAfterFillInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnAfterFillInvoicePostBufferProcedure', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnAfterUpdateInvPostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnBeforeFillInvPostingBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnBeforeFillInvoicePostBuffer', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnBeforeInvPostingBufferCalcInvoiceDiscountAmount', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnBeforeInvPostingBufferCalcLineDiscountAmount', TempPublisherBuffer);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnBeforeUpdateInvPostBuffer', TempPublisherBuffer);
    end;

    local procedure AddEvent(ObjectID: Integer; EventName: Text[250]; var TempPublisherBuffer: Record "Event Subscription" temporary)
    begin
        TempPublisherBuffer.Init();
        TempPublisherBuffer."Publisher Object Type" := TempPublisherBuffer."Publisher Object Type"::Codeunit;
        TempPublisherBuffer."Publisher Object ID" := ObjectID;
        TempPublisherBuffer."Published Function" := EventName;
        TempPublisherBuffer."Subscriber Codeunit ID" := ObjectID;
        TempPublisherBuffer."Subscriber Function" := EventName;
        TempPublisherBuffer.Insert();
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Will be removed together with old Adjust Exchange rate implementation.', '23.0')]
    local procedure OnBeforeCheckOldAdjustExchangeRatesEvents(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Will be removed together with old Invoice Posting implementation.', '23.0')]
    local procedure OnBeforeCheckOldInvoicePostingEvents(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif
}