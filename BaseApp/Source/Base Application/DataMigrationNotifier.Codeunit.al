codeunit 1802 "Data Migration Notifier"
{

    trigger OnRun()
    begin
    end;

    var
        ListEmptyMsg: Label 'Want to import entries?';
        OpenDataMigrationTxt: Label 'Open Data Migration';
        DataTypeManagement: Codeunit "Data Type Management";
        ListSuggestCreateContactsCustomersMsg: Label 'You can create contacts automatically from newly created customers.';
        ListSuggestCreateContactsVendorsMsg: Label 'You can create contacts automatically from newly created vendors.';
        OpenCreateContactsFromCustomersTxt: Label 'Create contacts from customers';
        OpenCreateContactsFromVendorsTxt: Label 'Create contacts from vendors';
        DataMigrationMgt: Codeunit "Data Migration Mgt.";
        DisableNotificationTxt: Label 'Disable notification';

    [EventSubscriber(ObjectType::Page, 22, 'OnOpenPageEvent', '', false, false)]
    local procedure OnCustomerListOpen(var Rec: Record Customer)
    begin
        ShowListEmptyNotification(Rec);
    end;

    [EventSubscriber(ObjectType::Page, 27, 'OnOpenPageEvent', '', false, false)]
    local procedure OnVendorListOpen(var Rec: Record Vendor)
    begin
        ShowListEmptyNotification(Rec);
    end;

    [EventSubscriber(ObjectType::Page, 31, 'OnOpenPageEvent', '', false, false)]
    local procedure OnItemListOpen(var Rec: Record Item)
    begin
        ShowListEmptyNotification(Rec);
    end;

    local procedure ShowListEmptyNotification(RecordVariant: Variant)
    var
        RecRef: RecordRef;
        NullGUID: Guid;
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, RecRef);

        RecRef.Reset();

        if not RecRef.IsEmpty then
            exit;
        CreateNotification(NullGUID, ListEmptyMsg, NOTIFICATIONSCOPE::LocalScope, OpenDataMigrationTxt, 'OpenDataMigrationWizard', '');
    end;

    procedure OpenDataMigrationWizard(ListEmptyNotification: Notification)
    begin
        PAGE.Run(PAGE::"Data Migration Wizard");
    end;

    [EventSubscriber(ObjectType::Table, 1800, 'OnGetInstructions', '', true, true)]
    local procedure OnGetInstructionsSubscriber(var Sender: Record "Data Migrator Registration"; var Instructions: Text; var Handled: Boolean)
    begin
        SendTraceTag('00001DB', 'AL ' + Sender.TableName, VERBOSITY::Normal, Sender.Description, DATACLASSIFICATION::SystemMetadata);
    end;

    procedure RunCreateContactsFromCustomersReport(ListEmptyNotification: Notification)
    begin
        REPORT.Run(REPORT::"Create Conts. from Customers");
    end;

    procedure RunCreateContactsFromVendorsReport(ListEmptyNotification: Notification)
    begin
        REPORT.Run(REPORT::"Create Conts. from Vendors");
    end;

    procedure RemoveCustomerContactNotification(ListEmptyNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(DataMigrationMgt.GetCustomerContactNotificationId) then
            DataMigrationMgt.InsertDefaultCustomerContactNotification(false);
    end;

    procedure RemoveVendorContactNotification(ListEmptyNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(DataMigrationMgt.GetVendorContactNotificationId) then
            DataMigrationMgt.InsertDefaultVendorContactNotification(false);
    end;

    local procedure CreateNotification(NotificationGUID: Guid; MessageText: Text; NotificaitonScope: NotificationScope; ActionText: Text; ActionFunction: Text; RemoveNotificationFunction: Text)
    var
        Notification: Notification;
    begin
        Notification.Id := NotificationGUID;
        Notification.Message := MessageText;
        Notification.Scope := NotificaitonScope;
        Notification.AddAction(ActionText, CODEUNIT::"Data Migration Notifier", ActionFunction);
        if RemoveNotificationFunction <> '' then
            Notification.AddAction(DisableNotificationTxt, CODEUNIT::"Data Migration Notifier", RemoveNotificationFunction);
        Notification.Send;
    end;

    local procedure ShowCustomerContactCreationNotification(SourceNo: Code[20]; SourceTableID: Integer)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        NotificationID: Guid;
        SkipNotification: Boolean;
    begin
        SkipShowingCustomerContactCreationNotification(SkipNotification);
        if SkipNotification then
            exit;

        NotificationID := CheckCustVendNotificationIdEnabled(SourceTableID);
        if IsNullGuid(NotificationID) then
            exit;
        case SourceTableID of
            DATABASE::Customer:
                if not ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, SourceNo) then
                    CreateNotification(
                      NotificationID,
                      ListSuggestCreateContactsCustomersMsg, NOTIFICATIONSCOPE::LocalScope,
                      OpenCreateContactsFromCustomersTxt, 'RunCreateContactsFromCustomersReport',
                      'RemoveCustomerContactNotification')
                else
                    RecallNotification(NotificationID);
            DATABASE::Vendor:
                if not ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Vendor, SourceNo) then
                    CreateNotification(
                      NotificationID,
                      ListSuggestCreateContactsVendorsMsg, NOTIFICATIONSCOPE::LocalScope,
                      OpenCreateContactsFromVendorsTxt, 'RunCreateContactsFromVendorsReport',
                      'RemoveVendorContactNotification')
                else
                    RecallNotification(NotificationID);
        end;
    end;

    procedure CheckCustVendNotificationIdEnabled(SourceTableID: Integer) NotificationID: Guid
    var
        MyNotifications: Record "My Notifications";
    begin
        case SourceTableID of
            DATABASE::Customer:
                NotificationID := DataMigrationMgt.GetCustomerContactNotificationId;
            DATABASE::Vendor:
                NotificationID := DataMigrationMgt.GetVendorContactNotificationId;
            else
                exit;
        end;
        if not MyNotifications.IsEnabled(NotificationID) then
            Clear(NotificationID);
    end;

    local procedure RecallNotification(NotificationID: Guid)
    var
        Notification: Notification;
    begin
        Notification.Id := NotificationID;
        if Notification.Recall then;
    end;

    procedure ShowContactNotificationIfCustWithoutContExist()
    var
        Customer: Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if not IsNullGuid(CheckCustVendNotificationIdEnabled(DATABASE::Customer)) then
            if Customer.FindSet then
                repeat
                    if not ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, Customer."No.") then begin
                        OnCustomerListGetCurrRec(Customer);
                        exit;
                    end;
                until Customer.Next = 0;
    end;

    procedure ShowContactNotificationIfVendWithoutContExist()
    var
        Vendor: Record Vendor;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if not IsNullGuid(CheckCustVendNotificationIdEnabled(DATABASE::Vendor)) then
            if Vendor.FindSet then
                repeat
                    if not ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.") then begin
                        OnVendorListGetCurrRec(Vendor);
                        exit;
                    end;
                until Vendor.Next = 0;
    end;

    [EventSubscriber(ObjectType::Page, 9076, 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenSalesRelationshipMgrActPage(var Rec: Record "Relationship Mgmt. Cue")
    begin
        ShowContactNotificationIfCustWithoutContExist;
        ShowContactNotificationIfVendWithoutContExist;
    end;

    [EventSubscriber(ObjectType::Page, 22, 'OnAfterGetCurrRecordEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure OnCustomerListGetCurrRec(var Rec: Record Customer)
    begin
        ShowCustomerContactCreationNotification(Rec."No.", DATABASE::Customer);
    end;

    [EventSubscriber(ObjectType::Page, 21, 'OnAfterGetCurrRecordEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure OnCustomerCardGetCurrRec(var Rec: Record Customer)
    begin
        if Rec.Find then
            ShowCustomerContactCreationNotification(Rec."No.", DATABASE::Customer);
    end;

    [EventSubscriber(ObjectType::Page, 27, 'OnAfterGetCurrRecordEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure OnVendorListGetCurrRec(var Rec: Record Vendor)
    begin
        ShowCustomerContactCreationNotification(Rec."No.", DATABASE::Vendor);
    end;

    [EventSubscriber(ObjectType::Page, 26, 'OnAfterGetCurrRecordEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure OnVendorCardGetCurrRec(var Rec: Record Vendor)
    begin
        if Rec.Find then
            ShowCustomerContactCreationNotification(Rec."No.", DATABASE::Vendor);
    end;

    [IntegrationEvent(false, false)]
    local procedure SkipShowingCustomerContactCreationNotification(var SkipNotification: Boolean)
    begin
    end;
}

