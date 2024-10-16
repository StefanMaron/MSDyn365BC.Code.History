namespace System.Security.User;

using Microsoft.Assembly.History;
using Microsoft.Bank.Check;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Payment;
using Microsoft.CashFlow.Forecast;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Allocation;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Payables;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.TimeSheet;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Utilities;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using System.Automation;
using System.Device;
using System.Diagnostics;
using System.Environment;
using System.Environment.Configuration;
using System.IO;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.Encryption;
using System.Threading;
using System.Utilities;
using System.Visualization;

codeunit 418 "User Management"
{
    Permissions = TableData "G/L Entry" = rm,
                  TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "G/L Register" = rm,
                  TableData "Item Register" = rm,
                  TableData "G/L Budget Entry" = rm,
                  TableData "Sales Shipment Header" = rm,
                  TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm,
                  TableData "Purch. Rcpt. Header" = rm,
                  TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm,
                  TableData "Job Ledger Entry" = rm,
                  TableData "Res. Ledger Entry" = rm,
                  TableData "Resource Register" = rm,
                  TableData "Job Register" = rm,
                  TableData "VAT Entry" = rm,
                  TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm,
                  TableData "Phys. Inventory Ledger Entry" = rm,
                  TableData "Issued Reminder Header" = rm,
                  TableData "Reminder/Fin. Charge Entry" = rm,
                  TableData "Issued Fin. Charge Memo Header" = rm,
                  TableData "Reservation Entry" = rm,
                  TableData "Item Application Entry" = rm,
                  TableData "Detailed Cust. Ledg. Entry" = rm,
                  TableData "Detailed Vendor Ledg. Entry" = rm,
                  TableData "Change Log Entry" = rm,
                  TableData "Approval Entry" = rm,
                  TableData "Approval Comment Line" = rm,
                  TableData "Posted Approval Entry" = rm,
                  TableData "Posted Approval Comment Line" = rm,
                  TableData "Posted Assembly Header" = rm,
                  TableData "Cost Entry" = rm,
                  TableData "Cost Register" = rm,
                  TableData "Cost Budget Entry" = rm,
                  TableData "Cost Budget Register" = rm,
                  TableData "Interaction Log Entry" = rm,
                  TableData "Campaign Entry" = rm,
                  TableData "FA Ledger Entry" = rm,
                  TableData "FA Register" = rm,
                  TableData "Maintenance Ledger Entry" = rm,
                  TableData "Ins. Coverage Ledger Entry" = rm,
                  TableData "Insurance Register" = rm,
                  TableData "Value Entry" = rm,
#if not CLEAN25
                  TableData Microsoft.Service.Ledger."Service Ledger Entry" = rm,
                  TableData Microsoft.Service.Ledger."Service Register" = rm,
                  TableData Microsoft.Service.Contract."Contract Gain/Loss Entry" = rm,
                  TableData Microsoft.Service.Contract."Filed Service Contract Header" = rm,
                  TableData Microsoft.Service.History."Service Shipment Header" = rm,
                  TableData Microsoft.Service.History."Service Invoice Header" = rm,
                  TableData Microsoft.Service.History."Service Cr.Memo Header" = rm,
#endif
                  TableData "Return Shipment Header" = rm,
                  TableData "Return Receipt Header" = rm,
                  TableData "Item Budget Entry" = rm,
                  TableData "Warehouse Entry" = rm,
                  TableData "Warehouse Register" = rm,
                  Tabledata "Workflow Step Instance Archive" = rm,
                  Tabledata "Date Compr. Register" = rm,
                  Tabledata "Requisition Line" = rm,
                  Tabledata "Overdue Approval Entry" = rm,
                  Tabledata "Job Queue Entry" = rm,
                  Tabledata "Job Queue Log Entry" = rm,
                  Tabledata "Error Message Register" = rm,
                  Tabledata "Activity Log" = rm,
                  Tabledata "Workflow Step Instance" = rm,
                  Tabledata "Notification Entry" = rm,
                  Tabledata "Sent Notification Entry" = rm,
                  Tabledata "User Setup" = rm,
                  Tabledata "VAT Registration Log" = rm,
                  Tabledata "Item Application Entry History" = rm,
                  Tabledata "CV Ledger Entry Buffer" = rm,
                  Tabledata "Detailed CV Ledg. Entry Buffer" = rm,
                  Tabledata "VAT Report Archive" = rm,
                  Tabledata "Cash Flow Forecast Entry" = rm,
                  Tabledata "Job Planning Line" = rm,
                  Tabledata "Cost Type" = rm,
                  Tabledata "Cost Allocation Source" = rm,
                  Tabledata "Cost Allocation Target" = rm,
                  Tabledata "Cost Center" = rm,
                  Tabledata "Credit Transfer Register" = rm,
                  Tabledata "Direct Debit Collection" = rm,
                  Tabledata "Isolated Certificate" = rm,
                  Tabledata "Logged Segment" = rm,
                  Tabledata "Saved Segment Criteria" = rm,
                  Tabledata "Sales Header Archive" = rm,
                  Tabledata "Purchase Header Archive" = rm,
                  Tabledata "Employee Ledger Entry" = rm,
                  Tabledata "Detailed Employee Ledger Entry" = rm,
                  Tabledata "Manufacturing User Template" = rm,
                  Tabledata "Field Monitoring Setup" = rm;

    trigger OnRun()
    begin
    end;

    var
        Text001Qst: Label 'You are renaming an existing user. This will also update all related records. Are you sure that you want to rename the user?';
        Text002Err: Label 'The account %1 already exists.', Comment = '%1 username';
        Text003Err: Label 'You do not have permissions for this action on the table %1.', Comment = '%1 table name';
#if not CLEAN23
        BasicAuthDescriptionNameTok: Label 'Web Service Access Key';
        BasicAuthUsedNameTok: Label 'Web Service Access Key Warning';
        BasicAuthDepricationTok: Label 'Web Service Access Key is no longer supported in Business Central online. Integrations using this technology will stop working. Please use OAuth instead.';
        BasicAuthUsedTok: Label 'One or more users have still enabled a Web Service Access Key. This is deprecated in Business Central online and integrations using this technology will stop working soon. Please use OAuth instead';
        DontShowAgainTok: Label 'Don''t show me again';
        ShowMoreLinkTok: Label 'Show more';
#endif
#pragma warning disable AA0470
        CurrentUserQst: Label 'You are signed in with the %1 account. Changing the account will refresh your session. Do you want to continue?', Comment = 'USERID';
#pragma warning restore AA0470
        UnsupportedLicenseTypeOnSaasErr: Label 'Only users of type %1, %2, %3, %4 and %5 are supported in the online environment.', Comment = '%1,%2,%3,%4,%5 = license type';
        DisableUserMsg: Label 'To permanently disable a user, go to your Microsoft 365 admin center. Disabling the user in Business Central will only be effective until the next user synchonization with Microsoft 365.';
        WindowsSecurityIdNotEditableOnSaaSErr: Label 'Windows security identifier is not supported in online environments.';

    procedure DisplayUserInformation(Username: Text)
    var
        User: Record User;
    begin
        User.FilterGroup(2);
        User.SetRange("User Name", Username);
        User.FilterGroup(0);
        if not User.FindLast() then
            exit;
        OpenUserPageForSelectedUser(User);
    end;

    procedure DisplayUserInformationBySID(SID: Guid)
    var
        User: Record User;
    begin
        User.FilterGroup(2);
        User.SetRange("User Security ID", SID);
        User.FilterGroup(0);
        if not User.FindLast() then
            exit;
        OpenUserPageForSelectedUser(User);
    end;

    local procedure OpenUserPageForSelectedUser(var User: Record User)
    var
        UserLookup: Page "User Lookup";
    begin
        UserLookup.Editable := false;
        UserLookup.SetTableView(User);
        UserLookup.RunModal();
    end;

    procedure ValidateUserName(NewUser: Record User; OldUser: Record User; WindowsUserName: Text)
    var
        User: Record User;
        ConfirmManagement: Codeunit "Confirm Management";
        CheckForWindowsUserName: Boolean;
    begin
        if NewUser."User Name" <> OldUser."User Name" then begin
            User.SetRange("User Name", NewUser."User Name");
            User.SetFilter("User Security ID", '<>%1', OldUser."User Security ID");
            if User.FindFirst() then
                Error(Text002Err, NewUser."User Name");

            CheckForWindowsUserName := NewUser."Windows Security ID" <> '';
            OnValidateUserNameOnAfterCalcCheckForWindowsUserName(NewUser, WindowsUserName, CheckForWindowsUserName);
            if CheckForWindowsUserName then
                NewUser.TestField("User Name", WindowsUserName);

            if OldUser."User Name" <> '' then
                if ConfirmManagement.GetResponseOrDefault(Text001Qst, false) then
                    RenameUser(OldUser."User Name", NewUser."User Name")
                else
                    Error('');
        end;
    end;

    procedure ValidateState(var Rec: Record User; var xRec: Record User);
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit;

        if (xRec.State <> Rec.State) and (Rec.State = Rec.State::Disabled) then
            Message(DisableUserMsg);
    end;

    local procedure IsPrimaryKeyField(TableID: Integer; FieldID: Integer; var NumberOfPrimaryKeyFields: Integer): Boolean
    var
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        RecRef: RecordRef;
        KeyRef: KeyRef;
    begin
        RecRef.Open(TableID);
        KeyRef := RecRef.KeyIndex(1);
        NumberOfPrimaryKeyFields := KeyRef.FieldCount;
        exit(ConfigValidateMgt.IsKeyField(TableID, FieldID));
    end;

    local procedure RenameRecord(var RecRef: RecordRef; TableNo: Integer; NumberOfPrimaryKeyFields: Integer; UserName: Code[50]; Company: Text[30])
    var
        UserTimeRegister: Record "User Time Register";
        PrinterSelection: Record "Printer Selection";
        SelectedDimension: Record "Selected Dimension";
        FAJournalSetup: Record "FA Journal Setup";
        AnalysisSelectedDimension: Record "Analysis Selected Dimension";
        WarehouseEmployee: Record "Warehouse Employee";
        MyCustomer: Record "My Customer";
        MyVendor: Record "My Vendor";
        MyItem: Record "My Item";
        MyAccount: Record "My Account";
        ApplicationAreaSetup: Record "Application Area Setup";
        MyJob: Record "My Job";
        MyTimeSheets: Record "My Time Sheets";
        CuesAndKpis: Codeunit "Cues and KPIs";
        Checklist: Codeunit Checklist;
    begin
        if NumberOfPrimaryKeyFields = 1 then
            RecRef.Rename(UserName)
        else
            case TableNo of
                DATABASE::"User Time Register":
                    begin
                        UserTimeRegister.ChangeCompany(Company);
                        RecRef.SetTable(UserTimeRegister);
                        UserTimeRegister.Rename(UserName, UserTimeRegister.Date);
                    end;
                DATABASE::"Printer Selection":
                    begin
                        RecRef.SetTable(PrinterSelection);
                        PrinterSelection.Rename(UserName, PrinterSelection."Report ID");
                    end;
                DATABASE::"Selected Dimension":
                    begin
                        SelectedDimension.ChangeCompany(Company);
                        RecRef.SetTable(SelectedDimension);
                        SelectedDimension.Rename(UserName, SelectedDimension."Object Type", SelectedDimension."Object ID",
                          SelectedDimension."Analysis View Code", SelectedDimension."Dimension Code");
                    end;
                DATABASE::"FA Journal Setup":
                    begin
                        FAJournalSetup.ChangeCompany(Company);
                        RecRef.SetTable(FAJournalSetup);
                        FAJournalSetup.Rename(FAJournalSetup."Depreciation Book Code", UserName);
                    end;
                DATABASE::"Analysis Selected Dimension":
                    begin
                        AnalysisSelectedDimension.ChangeCompany(Company);
                        RecRef.SetTable(AnalysisSelectedDimension);
                        AnalysisSelectedDimension.Rename(UserName, AnalysisSelectedDimension."Object Type", AnalysisSelectedDimension."Object ID",
                          AnalysisSelectedDimension."Analysis Area", AnalysisSelectedDimension."Analysis View Code",
                          AnalysisSelectedDimension."Dimension Code");
                    end;
                9701: // Cue Setup
                    CuesAndKpis.ChangeUserForSetupEntry(RecRef, Company, UserName);
                DATABASE::"Warehouse Employee":
                    begin
                        WarehouseEmployee.ChangeCompany(Company);
                        RecRef.SetTable(WarehouseEmployee);
                        WarehouseEmployee.Rename(UserName, WarehouseEmployee."Location Code");
                    end;
                DATABASE::"My Customer":
                    begin
                        MyCustomer.ChangeCompany(Company);
                        RecRef.SetTable(MyCustomer);
                        MyCustomer.Rename(UserName, MyCustomer."Customer No.");
                    end;
                DATABASE::"My Vendor":
                    begin
                        MyVendor.ChangeCompany(Company);
                        RecRef.SetTable(MyVendor);
                        MyVendor.Rename(UserName, MyVendor."Vendor No.");
                    end;
                DATABASE::"My Item":
                    begin
                        MyItem.ChangeCompany(Company);
                        RecRef.SetTable(MyItem);
                        MyItem.Rename(UserName, MyItem."Item No.");
                    end;
                DATABASE::"My Account":
                    begin
                        MyAccount.ChangeCompany(Company);
                        RecRef.SetTable(MyAccount);
                        MyAccount.Rename(UserName, MyAccount."Account No.");
                    end;
                DATABASE::"Application Area Setup":
                    begin
                        ApplicationAreaSetup.ChangeCompany(Company);
                        RecRef.SetTable(ApplicationAreaSetup);
                        ApplicationAreaSetup.Rename('', '', UserName);
                    end;
                DATABASE::"My Job":
                    begin
                        MyJob.ChangeCompany(Company);
                        RecRef.SetTable(MyJob);
                        MyJob.Rename(UserName, MyJob."Job No.");
                    end;
                DATABASE::"My Time Sheets":
                    begin
                        MyTimeSheets.ChangeCompany(Company);
                        RecRef.SetTable(MyTimeSheets);
                        MyTimeSheets.Rename(UserName, MyTimeSheets."Time Sheet No.");
                    end;
                1993: //Checklist Item User
                    Checklist.UpdateUserName(RecRef, Company, UserName, 1993);
                1994: //User Checklist Status
                    Checklist.UpdateUserName(RecRef, Company, UserName, 1994);
            end;
        OnAfterRenameRecord(RecRef, TableNo, NumberOfPrimaryKeyFields, UserName, Company);
    end;

#if not CLEAN23
    [Obsolete('Basic Authentication deprecation warning should no longer be shown with from 23.0', '23.0')]
    [Scope('OnPrem')]
    procedure BasicAuthDepricationNotificationId(): Guid
    begin
        exit('8f5a1371-94e3-42b6-84df-6ed215bc374a');
    end;
#endif

#if not CLEAN23
    [Obsolete('Basic Authentication deprecation warning should no longer be shown with from 23.0', '23.0')]
    [Scope('OnPrem')]
    procedure BasicAuthUsedNotificationId(): Guid
    begin
        exit('b21a58f5-23fe-4954-bd74-6f0202c2c019');
    end;
#endif
#if not CLEAN23
    [Obsolete('Basic Authentication deprecation warning should no longer be shown with from 23.0', '23.0')]
    [Scope('OnPrem')]
    procedure BasicAuthDepricationNotificationDefault(Enabled: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(
          BasicAuthDepricationNotificationId(), BasicAuthDescriptionNameTok, BasicAuthDepricationTok, Enabled);
    end;
#endif
#if not CLEAN23
    [Obsolete('Basic Authentication deprecation warning should no longer be shown with from 23.0', '23.0')]
    [Scope('OnPrem')]
    procedure BasicAuthUsedNotificationDefault(Enabled: Boolean)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(
          BasicAuthDepricationNotificationId(), BasicAuthUsedNameTok, BasicAuthUsedTok, Enabled);
    end;
#endif
#if not CLEAN23
    [Obsolete('Basic Authentication deprecation warning should no longer be shown with from 23.0', '23.0')]
    [Scope('OnPrem')]
    procedure BasicAuthDepricationNotificationShow(BasicAuthDepricationNotification: Notification)
    begin
        BasicAuthDepricationNotification.Id := BasicAuthDepricationNotificationId();
        BasicAuthDepricationNotification.Recall();
        BasicAuthDepricationNotification.Message(BasicAuthDepricationTok);
        BasicAuthDepricationNotification.AddAction(DontShowAgainTok, CODEUNIT::"User Management", 'DisableNotifications');
        BasicAuthDepricationNotification.AddAction(ShowMoreLinkTok, CODEUNIT::"User Management", 'BasicAuthDepricationNotificationShowMore');
        BasicAuthDepricationNotification.Scope(NotificationScope::LocalScope);
        BasicAuthDepricationNotification.Send();
    end;
#endif
#if not CLEAN23
    [Obsolete('Basic Authentication deprecation warning should no longer be shown with from 23.0', '23.0')]
    [Scope('OnPrem')]
    procedure BasicAuthUsedNotificationShow(BasicAuthUsedNotification: Notification)
    begin
        BasicAuthUsedNotification.Id := BasicAuthUsedNotificationId();
        BasicAuthUsedNotification.Recall();
        BasicAuthUsedNotification.Message(BasicAuthUsedTok);
        BasicAuthUsedNotification.AddAction(DontShowAgainTok, CODEUNIT::"User Management", 'DisableNotifications');
        BasicAuthUsedNotification.AddAction(ShowMoreLinkTok, CODEUNIT::"User Management", 'BasicAuthDepricationNotificationShowMore');
        BasicAuthUsedNotification.Scope(NotificationScope::LocalScope);
        BasicAuthUsedNotification.Send();
    end;
#endif
#if not CLEAN23
    [Scope('OnPrem')]
    procedure DisableNotifications(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.Disable(Notification.Id);
    end;
#endif
#if not CLEAN23
    [Obsolete('Basic Authentication deprecation warning should no longer be shown with from 23.0', '23.0')]
    [Scope('OnPrem')]
    procedure BasicAuthDepricationNotificationShowMore(Notification: Notification)
    begin
        Hyperlink('https://go.microsoft.com/fwlink/?linkid=2207805');
    end;
#endif

    procedure RenameUser(OldUserName: Code[50]; NewUserName: Code[50])
    var
        User: Record User;
        "Field": Record "Field";
        TableInformation: Record "Table Information";
        Company: Record Company;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldRef2: FieldRef;
        SessionSetting: SessionSettings;
        NumberOfPrimaryKeyFields: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeRenameUser(OldUserName, NewUserName);

        if OldUserName = UserID then
            if not confirm(CurrentUserQst, true, UserID) then
                error('');

        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetRange(RelationTableNo, DATABASE::User);
        Field.SetRange(RelationFieldNo, User.FieldNo("User Name"));
        Field.SetFilter(Type, '%1|%2', Field.Type::Code, Field.Type::Text);
        if Field.FindSet() then
            repeat
                Company.FindSet();
                repeat
                    IsHandled := false;
                    OnRenameUserOnBeforeProcessField(Field.TableNo, Field."No.", OldUserName, NewUserName, IsHandled);
                    if not IsHandled then begin
                        RecRef.Open(Field.TableNo, false, Company.Name);
                        if RecRef.ReadPermission then begin
                            FieldRef := RecRef.Field(Field."No.");
                            FieldRef.SetRange(CopyStr(OldUserName, 1, Field.Len));
                            if RecRef.FindSet(true) then
                                repeat
                                    if IsPrimaryKeyField(Field.TableNo, Field."No.", NumberOfPrimaryKeyFields) then
                                        RenameRecord(RecRef, Field.TableNo, NumberOfPrimaryKeyFields, NewUserName, Company.Name)
                                    else begin
                                        FieldRef2 := RecRef.Field(Field."No.");
                                        FieldRef2.Value := CopyStr(NewUserName, 1, Field.Len);
                                        RecRef.Modify();
                                    end;
                                until RecRef.Next() = 0;
                        end else begin
                            TableInformation.SetFilter("Company Name", '%1|%2', '', Company.Name);
                            TableInformation.SetRange("Table No.", Field.TableNo);
                            if TableInformation.FindFirst() then
                                if TableInformation."No. of Records" > 0 then
                                    Error(Text003Err, Field.TableName);
                        end;
                        RecRef.Close();
                    end;
                until Company.Next() = 0;
            until Field.Next() = 0;

        if OldUserName = UserId then begin
            SessionSetting.Init();
            SessionSetting.RequestSessionUpdate(false);
        end;

        OnAfterRenameUser(OldUserName, NewUserName);
    end;

    [EventSubscriber(ObjectType::Table, Database::User, 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyUserValidateWindowsSecurityIdOnSaaS(RunTrigger: Boolean; var Rec: Record User; var xRec: Record User)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaSInfrastructure() then
            if Rec."Windows Security ID" <> '' then
                Error(WindowsSecurityIdNotEditableOnSaaSErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::User, 'OnAfterValidateEvent', 'Application ID', false, false)]
    local procedure SetLicenseTypeOnValidateApplicationID(var Rec: Record User; var xRec: Record User; CurrFieldNo: Integer)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaS() then
            if IsNullGuid(Rec."Application ID") then
                Rec."License Type" := Rec."License Type"::"Full User"
            else
                Rec."License Type" := Rec."License Type"::"External User";
    end;

    [EventSubscriber(ObjectType::Table, Database::User, 'OnAfterModifyEvent', '', false, true)]
    local procedure ValidateLicenseTypeOnAfterModifyUser(var Rec: Record User; var xRec: Record User; RunTrigger: Boolean)
    begin
        ValidateLicenseTypeOnSaaS(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::User, 'OnAfterInsertEvent', '', false, true)]
    local procedure ValidateLicenseTypeOnAfterInsertUser(var Rec: Record User; RunTrigger: Boolean)
    begin
        ValidateLicenseTypeOnSaaS(Rec);
    end;

    local procedure ValidateLicenseTypeOnSaaS(User: Record User)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if User.IsTemporary() then
            exit;

        if EnvironmentInfo.IsSaaS() then
            if not (User."License Type" in [User."License Type"::"Full User", User."License Type"::"External User", User."License Type"::Application, User."License Type"::"AAD Group", User."License Type"::Agent]) then
                Error(UnsupportedLicenseTypeOnSaasErr, User."License Type"::"Full User", User."License Type"::"External User", User."License Type"::Application, User."License Type"::"AAD Group", User."License Type"::Agent);
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterRenameRecord(var RecRef: RecordRef; TableNo: Integer; NumberOfPrimaryKeyFields: Integer; UserName: Code[50]; Company: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRenameUser(OldUserName: Code[50]; NewUserName: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRenameUser(OldUserName: Code[50]; NewUserName: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRenameUserOnBeforeProcessField(TableID: Integer; FieldID: Integer; OldUserName: Code[50]; NewUserName: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUserNameOnAfterCalcCheckForWindowsUserName(NewUser: Record User; WindowsUserName: Text; var CheckForWindowsUserName: Boolean)
    begin
    end;
}

