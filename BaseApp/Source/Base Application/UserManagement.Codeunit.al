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
                  TableData "Service Ledger Entry" = rm,
                  TableData "Service Register" = rm,
                  TableData "Contract Gain/Loss Entry" = rm,
                  TableData "Filed Service Contract Header" = rm,
                  TableData "Service Shipment Header" = rm,
                  TableData "Service Invoice Header" = rm,
                  TableData "Service Cr.Memo Header" = rm,
                  TableData "Return Shipment Header" = rm,
                  TableData "Return Receipt Header" = rm,
                  TableData "Item Budget Entry" = rm,
                  TableData "Warehouse Entry" = rm,
                  TableData "Warehouse Register" = rm,
                  Tabledata "Workflow Step Instance Archive" = m,
                  Tabledata "Date Compr. Register" = m,
                  Tabledata "Requisition Line" = m,
                  Tabledata "Overdue Approval Entry" = m,
                  Tabledata "Job Queue Entry" = m,
                  Tabledata "Job Queue Log Entry" = m,
                  Tabledata "Error Message Register" = m,
                  Tabledata "Activity Log" = m,
                  Tabledata "Workflow Step Instance" = m,
                  Tabledata "Notification Entry" = m,
                  Tabledata "Sent Notification Entry" = m,
                  Tabledata "User Setup" = m,
                  Tabledata "VAT Registration Log" = m,
                  Tabledata "Item Application Entry History" = m,
                  Tabledata "CV Ledger Entry Buffer" = m,
                  Tabledata "Detailed CV Ledg. Entry Buffer" = m,
                  Tabledata "VAT Report Archive" = m,
                  Tabledata "Cash Flow Forecast Entry" = m,
                  Tabledata "Job Planning Line" = m,
                  Tabledata "Cost Type" = m,
                  Tabledata "Cost Allocation Source" = m,
                  Tabledata "Cost Allocation Target" = m,
                  Tabledata "Cost Center" = m,
                  Tabledata "Credit Transfer Register" = m,
                  Tabledata "Direct Debit Collection" = m,
                  Tabledata "Isolated Certificate" = m,
                  Tabledata "Logged Segment" = m,
                  Tabledata "Saved Segment Criteria" = m,
                  Tabledata "Sales Header Archive" = m,
                  Tabledata "Purchase Header Archive" = m,
                  Tabledata "Employee Ledger Entry" = m,
                  Tabledata "Detailed Employee Ledger Entry" = m,
                  Tabledata "Manufacturing User Template" = m;

    trigger OnRun()
    begin
    end;

    var
        Text001Qst: Label 'You are renaming an existing user. This will also update all related records. Are you sure that you want to rename the user?';
        Text002Err: Label 'The account %1 already exists.', Comment = '%1 username';
        Text003Err: Label 'You do not have permissions for this action on the table %1.', Comment = '%1 table name';
        CurrentUserQst: Label 'You are signed in with the %1 account. Changing the account will refresh your session. Do you want to continue?', Comment = 'USERID';
        UnsupportedLicenseTypeOnSaasErr: Label 'Only users of type %1 and %2 are supported in the online environment.', Comment = '%1= license type, %2= license type';
        DisableUserMsg: Label 'To permanently disable a user, go to your Office 365 admin center. Disabling the user in Business Central will only be effective until the next user synchonization with Office 365.';

    procedure DisplayUserInformation(Username: Text)
    var
        User: Record User;
    begin
        User.FilterGroup(2);
        User.SetRange("User Name", Username);
        User.FilterGroup(0);
        if not User.FindLast then
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
        if not User.FindLast then
            exit;
        OpenUserPageForSelectedUser(User);
    end;

    local procedure OpenUserPageForSelectedUser(var User: Record User)
    var
        UserLookup: Page "User Lookup";
    begin
        UserLookup.Editable := false;
        UserLookup.SetTableView(User);
        UserLookup.RunModal;
    end;

    procedure ValidateUserName(NewUser: Record User; OldUser: Record User; WindowsUserName: Text)
    var
        User: Record User;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if NewUser."User Name" <> OldUser."User Name" then begin
            User.SetRange("User Name", NewUser."User Name");
            User.SetFilter("User Security ID", '<>%1', OldUser."User Security ID");
            if User.FindFirst then
                Error(Text002Err, NewUser."User Name");

            if NewUser."Windows Security ID" <> '' then
                NewUser.TestField("User Name", WindowsUserName);

            if OldUser."User Name" <> '' then
                if ConfirmManagement.GetResponseOrDefault(Text001Qst, false) then
                    RenameUser(OldUser."User Name", NewUser."User Name")
                else
                    Error('');
        end;
    end;

    procedure ValidateState(var Rec: Record 2000000120; var xRec: Record 2000000120);
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaS then
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
        OutlookSynchUserSetup: Record "Outlook Synch. User Setup";
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
                DATABASE::"Outlook Synch. User Setup":
                    begin
                        OutlookSynchUserSetup.ChangeCompany(Company);
                        RecRef.SetTable(OutlookSynchUserSetup);
                        OutlookSynchUserSetup.Rename(UserName, OutlookSynchUserSetup."Synch. Entity Code");
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
                    begin
                        CuesAndKpis.ChangeUserForSetupEntry(RecRef, Company, UserName);
                    end;
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
            end;
        OnAfterRenameRecord(RecRef, TableNo, NumberOfPrimaryKeyFields, UserName, Company);
    end;

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
        if Field.FindSet then
            repeat
                Company.FindSet;
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
                                until RecRef.Next = 0;
                        end else begin
                            TableInformation.SetFilter("Company Name", '%1|%2', '', Company.Name);
                            TableInformation.SetRange("Table No.", Field.TableNo);
                            if TableInformation.FindFirst then
                                if TableInformation."No. of Records" > 0 then
                                    Error(Text003Err, Field.TableName);
                        end;
                        RecRef.Close;
                    end;
                until Company.Next = 0;
            until Field.Next = 0;

        if OldUserName = UserId then begin
            SessionSetting.Init();
            SessionSetting.RequestSessionUpdate(false);
        end;

        OnAfterRenameUser(OldUserName, NewUserName);
    end;

    [EventSubscriber(ObjectType::Table, 2000000120, 'OnAfterValidateEvent', 'Application ID', false, false)]
    local procedure SetLicenseTypeOnValidateApplicationID(var Rec: Record User; var xRec: Record User; CurrFieldNo: Integer)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaS then
            if IsNullGuid(Rec."Application ID") then
                Rec."License Type" := Rec."License Type"::"Full User"
            else
                Rec."License Type" := Rec."License Type"::"External User";
    end;

    [EventSubscriber(ObjectType::Table, 2000000120, 'OnAfterModifyEvent', '', false, true)]
    local procedure ValidateLicenseTypeOnAfterModifyUser(var Rec: Record User; var xRec: Record User; RunTrigger: Boolean)
    begin
        ValidateLicenseTypeOnSaaS(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 2000000120, 'OnAfterInsertEvent', '', false, true)]
    local procedure ValidateLicenseTypeOnAfterInsertUser(var Rec: Record User; RunTrigger: Boolean)
    begin
        ValidateLicenseTypeOnSaaS(Rec);
    end;

    local procedure ValidateLicenseTypeOnSaaS(User: Record User)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaS then begin
            if not (User."License Type" in [User."License Type"::"Full User", User."License Type"::"External User"]) then
                Error(UnsupportedLicenseTypeOnSaasErr, User."License Type"::"Full User", User."License Type"::"External User");
        end;
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
}

