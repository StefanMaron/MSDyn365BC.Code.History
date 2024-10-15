namespace System.Environment.Configuration;

#if not CLEAN23
using Microsoft.Finance.Currency;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Posting;
using Microsoft.Service.Posting;
using System.Apps;
using System.Environment;
using System.Telemetry;
using System.Reflection;
using Microsoft.Pricing.Calculation;
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
#if not CLEAN23
        EU3PartyTradePurchaseTxt: Label 'EU3PartyTradePurchase', Locked = true;
#endif
#if not CLEAN24
        PhysInvtOrderPackageTrackingTxt: Label 'PhysInvtOrderPackageTracking', Locked = true;
#endif
#if not CLEAN24
        GLCurrencyRevaluationTxt: Label 'GLCurrencyRevaluation', Locked = true;
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

    procedure IsExtensibleExchangeRateAdjustmentEnabled(AllowInsert: Boolean): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetExtensibleExchangeRateAdjustmentFeatureKey(), AllowInsert));
    end;
#endif

#if not CLEAN23
    procedure IsExtensibleInvoicePostingEngineEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetExtensibleInvoicePostingEngineFeatureKey()));
    end;
#endif

#if not CLEAN24
    procedure IsPhysInvtOrderPackageTrackingEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetPhysInvtOrderPackageTrackingFeatureKey()));
    end;
#endif

#if not CLEAN24
    procedure IsGLCurrencyRevaluationEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetGLCurrencyRevaluationFeatureKey()));
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
    internal procedure GetExtensibleExchangeRateAdjustmentFeatureKey(): Text[50]
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

#if not CLEAN24
    local procedure GetPhysInvtOrderPackageTrackingFeatureKey(): Text[50]
    begin
        exit(PhysInvtOrderPackageTrackingTxt);
    end;
#endif

#if not CLEAN24
    local procedure GetGLCurrencyRevaluationFeatureKey(): Text[50]
    begin
        exit(GLCurrencyRevaluationTxt);
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
                CheckAdjustExchangeRatesEventSubscribers();
            ExtensibleInvoicePostingEngineLbl:
                CheckInvoicePostingEventSubscribers();
        end;
        // Log feature uptake
        case FeatureKey.ID of
            ExtensibleExchangeRateAdjustmentLbl:
                FeatureTelemetry.LogUptake('0000JR9', ExtensibleExchangeRateAdjustmentLbl, Enum::"Feature Uptake Status"::Discovered);
            ExtensibleInvoicePostingEngineLbl:
                FeatureTelemetry.LogUptake('0000JRA', ExtensibleInvoicePostingEngineLbl, Enum::"Feature Uptake Status"::Discovered);
            EU3PartyTradePurchaseTxt:
                FeatureTelemetry.LogUptake('0000JRC', EU3PartyTradePurchaseTxt, Enum::"Feature Uptake Status"::Discovered);
        end;
#endif
#if not CLEAN24
        // Log feature uptake
        case FeatureKey.ID of
            GLCurrencyRevaluationTxt:
                FeatureTelemetry.LogUptake('0000JRR', GLCurrencyRevaluationTxt, Enum::"Feature Uptake Status"::Discovered);
        end;
#endif
    end;

#if not CLEAN23
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterUpdateData', '', false, false)]
    local procedure HandleOnAfterUpdateData(var FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        // Log feature uptake
        if FeatureDataUpdateStatus."Feature Status" <> FeatureDataUpdateStatus."Feature Status"::Complete then
            exit;
        case FeatureDataUpdateStatus."Feature Key" of
            PriceCalculationMgt.GetFeatureKey():
                FeatureTelemetry.LogUptake('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered);
        end;
    end;
#endif

#if not CLEAN23
    local procedure CheckAdjustExchangeRatesEventSubscribers()
    var
        EventSubscription: Record "Event Subscription";
        TempOldEventSubscription: Record "Event Subscription" temporary;
        TempNewEventSubscription: Record "Event Subscription" temporary;
        TempPublishedApplication: Record "Published Application" temporary;
    begin
        // add all subscribers to events from report 595 Adjust Exchange Rates
        EventSubscription.Reset();
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Report);
        EventSubscription.SetRange("Publisher Object ID", Report::"Adjust Exchange Rates");
        EventSubscription.SetFilter("Subscriber Codeunit ID", '150000..'); // filter out MS objects
        if EventSubscription.FindSet() then
            repeat
                TempOldEventSubscription := EventSubscription;
                TempOldEventSubscription.Insert();
            until EventSubscription.Next() = 0;

        // add all subscribers to events from codeunit Exch. Rate Adjmt. Process
        EventSubscription.Reset();
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Codeunit);
        EventSubscription.SetRange("Publisher Object ID", Codeunit::"Exch. Rate Adjmt. Process");
        EventSubscription.SetFilter("Subscriber Codeunit ID", '150000..'); // filter out MS objects
        if EventSubscription.FindSet() then
            repeat
                TempNewEventSubscription := EventSubscription;
                TempNewEventSubscription.Insert();
            until EventSubscription.Next() = 0;

        // Analyse each published application for presence of subscribers for old and new implementation
        // Raise error if there is application with subscribers to old implementation but without subscribers to new impementation
        BuildPublishedApplicationList(TempPublishedApplication, TempOldEventSubscription, TempNewEventSubscription);

        if not TempPublishedApplication.IsEmpty() then begin
            Message(FeatureEventConflictErr, GetExtensibleExchangeRateAdjustmentFeatureKey());
            ShowEventSubscriptionBuffers(TempOldEventSubscription, TempNewEventSubscription);
            error('');
        end;
    end;
#endif

#if not CLEAN23
    local procedure CheckInvoicePostingEventSubscribers()
    var
        EventSubscription: Record "Event Subscription";
        TempPublisherForEventSubscription: Record "Event Subscription" temporary;
        TempOldEventSubscription: Record "Event Subscription" temporary;
        TempNewEventSubscription: Record "Event Subscription" temporary;
        TempPublishedApplication: Record "Published Application" temporary;
    begin
        // add all subscribers to events from table 49 "Invoice Post. Buffer"
        EventSubscription.Reset();
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Table);
        EventSubscription.SetRange("Publisher Object ID", Database::"Invoice Post. Buffer");
        EventSubscription.SetRange("Subscriber Instance", 'Static-Automatic');
        EventSubscription.SetFilter("Subscriber Codeunit ID", '150000..'); // filter out MS objects
        if EventSubscription.FindSet() then
            repeat
                TempOldEventSubscription.Init();
                TempOldEventSubscription := EventSubscription;
                TempOldEventSubscription.Insert();
            until EventSubscription.Next() = 0;

        // Build list of events for old implementation
        BuildInvoicePostingCheckList(TempPublisherForEventSubscription);

        // add all old Invoice Posting related subscribers from old Purchase/Sales/Services posting codeunits
        EventSubscription.Reset();
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Codeunit);
        EventSubscription.SetFilter("Publisher Object ID", '80|90|5986|5987|5988');
        EventSubscription.SetRange("Subscriber Instance", 'Static-Automatic');
        EventSubscription.SetFilter("Subscriber Codeunit ID", '150000..'); // filter out MS objects
        if EventSubscription.FindSet() then
            repeat
                TempPublisherForEventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type");
                TempPublisherForEventSubscription.SetRange("Publisher Object ID", EventSubscription."Publisher Object ID");
                TempPublisherForEventSubscription.SetRange("Published Function", EventSubscription."Published Function");
                if not TempPublisherForEventSubscription.IsEmpty() then begin
                    TempOldEventSubscription.Init();
                    TempOldEventSubscription := EventSubscription;
                    TempOldEventSubscription.Insert();
                end;
            until EventSubscription.Next() = 0;

        // add all subscribers to events from table 55 "Invoice Posting Buffer"
        EventSubscription.Reset();
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Table);
        EventSubscription.SetRange("Publisher Object ID", Database::"Invoice Posting Buffer");
        EventSubscription.SetRange("Subscriber Instance", 'Static-Automatic');
        // EventSubscription.SetFilter("Subscriber Codeunit ID", '150000..'); // filter out MS objects
        if EventSubscription.FindSet() then
            repeat
                TempNewEventSubscription.Init();
                TempNewEventSubscription := EventSubscription;
                TempNewEventSubscription.Insert();
            until EventSubscription.Next() = 0;

        // add all old Invoice Posting related subscribers from new Purchase/Sales/Services posting codeunits
        EventSubscription.Reset();
        EventSubscription.SetRange("Publisher Object Type", EventSubscription."Publisher Object Type"::Codeunit);
        EventSubscription.SetFilter("Publisher Object ID", '825|826|827');
        EventSubscription.SetRange("Subscriber Instance", 'Static-Automatic');
        EventSubscription.SetFilter("Subscriber Codeunit ID", '150000..'); // filter out MS objects
        if EventSubscription.FindSet() then
            repeat
                TempNewEventSubscription.Init();
                TempNewEventSubscription := EventSubscription;
                TempNewEventSubscription.Insert();
            until EventSubscription.Next() = 0;

        // Analyse each published application for presence of subscribers for old and new implementation
        // Raise error if there is application with subscribers to old implementation but without subscribers to new impementation
        BuildPublishedApplicationList(TempPublishedApplication, TempOldEventSubscription, TempNewEventSubscription);

        if not TempPublishedApplication.IsEmpty() then begin
            Message(FeatureEventConflictErr, GetExtensibleInvoicePostingEngineFeatureKey());
            ShowEventSubscriptionBuffers(TempOldEventSubscription, TempNewEventSubscription);
            error('');
        end;
    end;

    local procedure BuildPublishedApplicationList(var TempPublishedApplication: Record "Published Application"; var TempOldEventSubscription: Record "Event Subscription" temporary; var TempNewEventSubscription: Record "Event Subscription" temporary)
    var
        PublishedApplication: Record "Published Application";
        OldEventExists: Boolean;
        NewEventExists: Boolean;
    begin
        TempPublishedApplication.DeleteAll();
        if PublishedApplication.FindSet() then
            repeat
                TempOldEventSubscription.SetRange("Originating Package ID", PublishedApplication."Package ID");
                OldEventExists := not TempOldEventSubscription.IsEmpty();
                TempNewEventSubscription.SetRange("Originating Package ID", PublishedApplication."Package ID");
                NewEventExists := not TempNewEventSubscription.IsEmpty();
                if OldEventExists and not NewEventExists then begin
                    TempPublishedApplication.Init();
                    TempPublishedApplication := PublishedApplication;
                    TempPublishedApplication.Insert();
                end;
            until PublishedApplication.Next() = 0;
    end;

    local procedure ShowEventSubscriptionBuffers(var TempEventSubscription: Record "Event Subscription" temporary; var TempNewEventSubscription: Record "Event Subscription" temporary)
    var
        EventSubscriptions: Page "Event Subscriptions";
    begin
        if TempNewEventSubscription.FindFirst() then
            repeat
                TempEventSubscription.Init();
                TempEventSubscription := TempNewEventSubscription;
                TempEventSubscription.Insert();
            until TempNewEventSubscription.Next() = 0;

        EventSubscriptions.SetTableView(TempEventSubscription);
        EventSubscriptions.RunModal();
        Clear(EventSubscriptions);
    end;

    local procedure BuildInvoicePostingCheckList(var TempPublisherForEventSubscription: Record "Event Subscription" temporary)
    begin
        // Sales
        AddEvent(Codeunit::"Sales-Post", 'OnAfterCreatePostedDeferralScheduleFromSalesDoc', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterGetSalesAccount', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeGetSalesAccount', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterFillInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterFillDeferralPostingBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterInvoicePostingBufferAssignAmounts', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterInvoicePostingBufferSetAmounts', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterPostCustomerEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterPostBalancingEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterPostInvPostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforePostCustomerEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeRunPostCustomerEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeRunGenJnlPostLine', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforePostBalancingEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforePostInvPostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforePostInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnAfterSetApplyToDocNo', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeCalcInvoiceDiscountPosting', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeCalcInvoiceDiscountPostingProcedure', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnCalcLineDiscountPostingProcedure', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeCalcLineDiscountPosting', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeSetAmountsForBalancingEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeTempDeferralLineInsert', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnBeforeDeferrals', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeFillDeferralPostingBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnBeforeFillInvoicePostingBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnBeforeSetAccount', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnAfterSetLineDiscAccount', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnAfterSetInvDiscAccount', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnAfterUpdateInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnAfterCalcInvoiceDiscountPosting', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnAfterCalcLineDiscountPosting', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnBeforeSetInvDiscAccount', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnFillInvoicePostingBufferOnBeforeSetLineDiscAccount', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnPostBalancingEntryOnAfterInitNewLine', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnPostBalancingEntryOnAfterFindCustLedgEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnPostBalancingEntryOnBeforeFindCustLedgEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnPostInvoicePostBufferOnAfterPostSalesGLAccounts', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnPostInvoicePostBufferOnBeforeTempInvoicePostBufferDeleteAll', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Sales-Post", 'OnPostInvoicePostBufferLineOnAfterCopyFromInvoicePostBuffer', TempPublisherForEventSubscription);

        // Purchase
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterCalcInvoiceDiscountPosting', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterCreatePostedDeferralScheduleFromPurchDoc', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterFillInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterInitVATBase', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterPostVendorEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterPostBalancingEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterPostInvPostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnAfterSetApplyToDocNo', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeCalcLineDiscountPosting', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeCalculateVATAmountInBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeFillInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeInitNewGenJnlLineFromPostInvoicePostBufferLine', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeInitGenJnlLineAmountFieldsFromTotalPurchLine', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeInvoicePostingBufferSetAmounts', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforePostInvoicePostBufferLine', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforePostVendorEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforePostBalancingEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforePostInvPostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforePostInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeTempDeferralLineInsert', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeFillDeferralPostingBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeFillInvoicePostBufferFADiscount', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnCalcDeferralAmountsOnAfterTempDeferralHeaderInsert', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostBufferOnAfterInitAmounts', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostingBufferOnAfterSetLineDiscAccount', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostingBufferOnAfterUpdateInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostBufferOnAfterSetShouldCalcDiscounts', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostingBufferOnBeforeSetAccount', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnPostBalancingEntryOnAfterInitNewLine', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnPostInvoicePostingBufferOnAfterVATPostingSetupGet', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnPostVendorEntryOnAfterInitNewLine', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnPostVendorEntryOnBeforeInitNewLine', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeRunGenJnlPostLine', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostBufferOnBeforePreparePurchase', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillDeferralPostingBufferOnAfterInitFromDeferralLine', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnFillInvoicePostBufferOnBeforeProcessInvoiceDiscounts', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnPostInvoicePostBufferLineOnAfterCopyFromInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnPostGLAndVendorOnBeforePostBalancingEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Purch.-Post", 'OnBeforeCheckItemQuantityPurchCredit', TempPublisherForEventSubscription);

        // Service
        AddEvent(Codeunit::"Serv-Documents Mgt.", 'OnPostDocumentLinesOnBeforePostInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnAfterPostCustomerEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnAfterPostBalancingEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnAfterPostInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnBeforePostCustomerEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnBeforePostBalancingEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnBeforePostInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Posting Journals Mgt.", 'OnPostBalancingEntryOnBeforeFindCustLedgerEntry', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnAfterFillInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnAfterFillInvoicePostBufferProcedure', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnAfterUpdateInvPostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnBeforeFillInvPostingBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnBeforeFillInvoicePostBuffer', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnBeforeInvPostingBufferCalcInvoiceDiscountAmount', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnBeforeInvPostingBufferCalcLineDiscountAmount', TempPublisherForEventSubscription);
        AddEvent(Codeunit::"Serv-Amounts Mgt.", 'OnBeforeUpdateInvPostBuffer', TempPublisherForEventSubscription);
    end;

    local procedure AddEvent(ObjectID: Integer; EventName: Text[250]; var TempPublisherForEventSubscription: Record "Event Subscription" temporary)
    begin
        TempPublisherForEventSubscription.Init();
        TempPublisherForEventSubscription."Publisher Object Type" := TempPublisherForEventSubscription."Publisher Object Type"::Codeunit;
        TempPublisherForEventSubscription."Publisher Object ID" := ObjectID;
        TempPublisherForEventSubscription."Published Function" := EventName;
        TempPublisherForEventSubscription."Subscriber Codeunit ID" := ObjectID;
        TempPublisherForEventSubscription."Subscriber Function" := EventName;
        TempPublisherForEventSubscription.Insert();
    end;
#endif
}