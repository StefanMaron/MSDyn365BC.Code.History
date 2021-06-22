codeunit 1508 "Notification Lifecycle Handler"
{

    trigger OnRun()
    begin
    end;

    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";

    [EventSubscriber(ObjectType::Table, 37, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterSalesLineInsertSetRecId(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterSalesLineRenameUpdateRecId(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.UpdateRecordID(xRec.RecordId, Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterSalesLineDeleteRecall(var Rec: Record "Sales Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecord(Rec.RecordId, false);
    end;

    [EventSubscriber(ObjectType::Table, 83, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterItemJournalInsertSetRecId(var Rec: Record "Item Journal Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 83, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterItemJournalRenameUpdateRecId(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.UpdateRecordID(xRec.RecordId, Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 83, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterItemJournalDeleteRecall(var Rec: Record "Item Journal Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecord(Rec.RecordId, false);
    end;

    [EventSubscriber(ObjectType::Table, 5741, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterTransferLineInsertSetRecId(var Rec: Record "Transfer Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 5741, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterTransferLineRenameUpdateRecId(var Rec: Record "Transfer Line"; var xRec: Record "Transfer Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.UpdateRecordID(xRec.RecordId, Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 5741, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterTransferLineDeleteRecall(var Rec: Record "Transfer Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecord(Rec.RecordId, false);
    end;

    [EventSubscriber(ObjectType::Table, 5902, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterServiceLineInsertSetRecId(var Rec: Record "Service Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 5902, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterServiceLineRenameUpdateRecId(var Rec: Record "Service Line"; var xRec: Record "Service Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.UpdateRecordID(xRec.RecordId, Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 5902, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterServiceLineDeleteRecall(var Rec: Record "Service Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecord(Rec.RecordId, false);
    end;

    [EventSubscriber(ObjectType::Table, 1003, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterJobPlanningLineInsertSetRecId(var Rec: Record "Job Planning Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 1003, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterJobPlanningLineRenameUpdateRecId(var Rec: Record "Job Planning Line"; var xRec: Record "Job Planning Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.UpdateRecordID(xRec.RecordId, Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 1003, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterJobPlanningLineDeleteRecall(var Rec: Record "Job Planning Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecord(Rec.RecordId, false);
    end;

    [EventSubscriber(ObjectType::Table, 901, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterAssemblyLineInsertSetRecId(var Rec: Record "Assembly Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 901, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterAssemblyLineRenameUpdateRecId(var Rec: Record "Assembly Line"; var xRec: Record "Assembly Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.UpdateRecordID(xRec.RecordId, Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 901, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterAssemblyLineDeleteRecall(var Rec: Record "Assembly Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecord(Rec.RecordId, false);
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterSalesHeaderInsertSetRecId(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 38, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterPurchaseHeaderInsertSetRecId(var Rec: Record "Purchase Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 81, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterGenJnlLineInsertSetRecId(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Table, 5965, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterServiceContractHeaderInsertSetRecId(var Rec: Record "Service Contract Header"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.SetRecordID(Rec.RecordId);
    end;

    [EventSubscriber(ObjectType::Codeunit, 312, 'OnNewCheckRemoveCustomerNotifications', '', false, false)]
    local procedure OnCustCheckCrLimitCheckRecallNotifs(RecId: RecordID; RecallCreditOverdueNotif: Boolean)
    var
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        if NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          RecId, CustCheckCrLimit.GetCreditLimitNotificationId, true);
        if RecallCreditOverdueNotif then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              RecId, CustCheckCrLimit.GetOverdueBalanceNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 83, 'OnBeforeValidateEvent', 'Entry Type', false, false)]
    local procedure OnItemJournalLineUpdateEntryTypeRecallItemNotif(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (Rec."Entry Type" <> Rec."Entry Type"::Sale) and
           (xRec."Entry Type" <> Rec."Entry Type") and (CurrFieldNo = Rec.FieldNo("Entry Type"))
        then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 83, 'OnBeforeValidateEvent', 'Quantity', false, false)]
    local procedure OnItemJournalLineUpdateQtyTo0RecallItemNotif(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (Rec.Quantity = 0) and (xRec.Quantity <> Rec.Quantity) and (CurrFieldNo = Rec.FieldNo(Quantity)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnBeforeValidateEvent', 'Type', false, false)]
    local procedure OnSalesLineUpdateTypeRecallItemNotif(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (Rec.Type <> Rec.Type::Item) and (xRec.Type <> Rec.Type) and (CurrFieldNo = Rec.FieldNo(Type)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 37, 'OnBeforeValidateEvent', 'Quantity', false, false)]
    local procedure OnSalesLineUpdateQtyTo0RecallItemNotif(var Rec: Record "Sales Line"; var xRec: Record "Sales Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (Rec.Quantity = 0) and (xRec.Quantity <> Rec.Quantity) and (CurrFieldNo = Rec.FieldNo(Quantity)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 5741, 'OnBeforeValidateEvent', 'Quantity', false, false)]
    local procedure OnTransferLineUpdateQtyTo0RecallItemNotif(var Rec: Record "Transfer Line"; var xRec: Record "Transfer Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (Rec.Quantity = 0) and (xRec.Quantity <> Rec.Quantity) and (CurrFieldNo = Rec.FieldNo(Quantity)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 5902, 'OnBeforeValidateEvent', 'Type', false, false)]
    local procedure OnServiceLineUpdateTypeRecallItemNotif(var Rec: Record "Service Line"; var xRec: Record "Service Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (Rec.Type <> Rec.Type::Item) and (xRec.Type <> Rec.Type) and (CurrFieldNo = Rec.FieldNo(Type)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 5902, 'OnBeforeValidateEvent', 'Quantity', false, false)]
    local procedure OnServiceLineUpdateQtyTo0RecallItemNotif(var Rec: Record "Service Line"; var xRec: Record "Service Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (Rec.Quantity = 0) and (xRec.Quantity <> Rec.Quantity) and (CurrFieldNo = Rec.FieldNo(Quantity)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 1003, 'OnBeforeValidateEvent', 'Type', false, false)]
    local procedure OnJobPlanningLineUpdateTypeRecallItemNotif(var Rec: Record "Job Planning Line"; var xRec: Record "Job Planning Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (Rec.Type <> Rec.Type::Item) and (xRec.Type <> Rec.Type) and (CurrFieldNo = Rec.FieldNo(Type)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 1003, 'OnBeforeValidateEvent', 'Line Type', false, false)]
    local procedure OnJobPlanningLineUpdateLineTypeRecallItemNotif(var Rec: Record "Job Planning Line"; var xRec: Record "Job Planning Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (Rec."Line Type" = Rec."Line Type"::Billable) and
           (xRec."Line Type" <> Rec."Line Type") and (CurrFieldNo = Rec.FieldNo("Line Type"))
        then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 1003, 'OnBeforeValidateEvent', 'Quantity', false, false)]
    local procedure OnJobPlanningLineUpdateQtyTo0RecallItemNotif(var Rec: Record "Job Planning Line"; var xRec: Record "Job Planning Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (Rec.Quantity = 0) and (xRec.Quantity <> Rec.Quantity) and (CurrFieldNo = Rec.FieldNo(Quantity)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 901, 'OnBeforeValidateEvent', 'Unit of Measure Code', false, false)]
    local procedure OnAssemblyLineUpdateUnitOfMeasureCodeRecallItemNotif(var Rec: Record "Assembly Line"; var xRec: Record "Assembly Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (xRec."Unit of Measure Code" <> Rec."Unit of Measure Code") and (CurrFieldNo = Rec.FieldNo("Unit of Measure Code")) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 901, 'OnBeforeValidateEvent', 'Type', false, false)]
    local procedure OnAssemblyLineUpdateTypeRecallItemNotif(var Rec: Record "Assembly Line"; var xRec: Record "Assembly Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (Rec.Type <> Rec.Type::Item) and (xRec.Type <> Rec.Type) and (CurrFieldNo = Rec.FieldNo(Type)) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Table, 901, 'OnBeforeValidateEvent', 'Quantity per', false, false)]
    local procedure OnAssemblyLineUpdateQuantityRecallItemNotif(var Rec: Record "Assembly Line"; var xRec: Record "Assembly Line"; CurrFieldNo: Integer)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        if Rec.IsTemporary or NotificationLifecycleMgt.AreSubscribersDisabled then
            exit;

        if (xRec."Quantity per" <> Rec."Quantity per") and (CurrFieldNo = Rec.FieldNo("Quantity per")) then
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
              Rec.RecordId, ItemCheckAvail.GetItemAvailabilityNotificationId, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnBeforePostSalesDoc', '', false, false)]
    local procedure OnBeforeSalesPost(var Sender: Codeunit "Sales-Post"; var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
        NotificationLifecycleMgt.DisableSubscribers;
    end;

    [EventSubscriber(ObjectType::Codeunit, 80, 'OnAfterPostSalesDoc', '', false, false)]
    local procedure OnAfterSalesPost(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean)
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Codeunit, 90, 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure OnBeforePurchPost(var Sender: Codeunit "Purch.-Post"; var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean)
    begin
        NotificationLifecycleMgt.DisableSubscribers;
    end;

    [EventSubscriber(ObjectType::Codeunit, 90, 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure OnAfterPurchPost(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; CommitIsSupressed: Boolean)
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Codeunit, 900, 'OnBeforePost', '', false, false)]
    local procedure OnBeforeAssemblyPost(var AssemblyHeader: Record "Assembly Header")
    begin
        NotificationLifecycleMgt.DisableSubscribers;
    end;

    [EventSubscriber(ObjectType::Codeunit, 900, 'OnAfterPost', '', false, false)]
    local procedure OnAfterAssemblyPost(var AssemblyHeader: Record "Assembly Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5980, 'OnBeforePostWithLines', '', false, false)]
    local procedure OnBeforeServicePost(var PassedServHeader: Record "Service Header"; var PassedServLine: Record "Service Line"; var PassedShip: Boolean; var PassedConsume: Boolean; var PassedInvoice: Boolean)
    begin
        NotificationLifecycleMgt.DisableSubscribers;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5980, 'OnAfterPostWithLines', '', false, false)]
    local procedure OnAfterServicePost(var PassedServiceHeader: Record "Service Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 41, 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenSalesQuote(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 41, 'OnClosePageEvent', '', false, false)]
    local procedure OnCloseSalesQuote(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 42, 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenSalesOrder(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 42, 'OnClosePageEvent', '', false, false)]
    local procedure OnCloseSalesOrder(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 43, 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenSalesInvoice(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 43, 'OnClosePageEvent', '', false, false)]
    local procedure OnCloseSalesInvoice(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 44, 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenSalesCreditMemo(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 44, 'OnClosePageEvent', '', false, false)]
    local procedure OnCloseSalesCreditMemo(var Rec: Record "Sales Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 49, 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPurchaseQuote(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 49, 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePurchaseQuote(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 50, 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPurchaseOrder(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 50, 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePurchaseOrder(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 51, 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPurchaseInvoice(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 51, 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePurchaseInvoice(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 52, 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPurchaseCreditMemo(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 52, 'OnClosePageEvent', '', false, false)]
    local procedure OnClosePurchaseCreditMemo(var Rec: Record "Purchase Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 900, 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenAssemblyOrder(var Rec: Record "Assembly Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 900, 'OnClosePageEvent', '', false, false)]
    local procedure OnCloseAssemblyOrder(var Rec: Record "Assembly Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 930, 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenAssemplyQuote(var Rec: Record "Assembly Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 930, 'OnClosePageEvent', '', false, false)]
    local procedure OnCloseAssemplyQuote(var Rec: Record "Assembly Header")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;

    [EventSubscriber(ObjectType::Page, 519, 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenItemJournalLine(var Rec: Record "Item Journal Line")
    begin
        NotificationLifecycleMgt.EnableSubscribers;
    end;
}

