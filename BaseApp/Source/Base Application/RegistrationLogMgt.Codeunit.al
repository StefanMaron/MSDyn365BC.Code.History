#if not CLEAN17
codeunit 11798 "Registration Log Mgt."
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    var
        ServiceConditionsURLTxt: Label 'http://wwwinfo.mfcr.cz/ares/ares_podminky.html.cz', Locked = true;
        ValidRegNoQst: Label 'The  registration number is valid. Do you want to update information on the card?';
        InvalidRegNoMsg: Label 'We didn''t find a match for this VAT registration number. Please verify that you specified the right number.';
        NotVerifiedRegNoMsg: Label 'We couldn''t verify the registration number. Try again later.';
        DescriptionLbl: Label 'Reg. No. Validation Service Setup (Obsolete)';

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure LogCustomer(Cust: Record Customer)
    var
        RegnLog: Record "Registration Log";
    begin
        InsertLogRegistration(Cust."Registration No.", RegnLog."Account Type"::Customer, Cust."No.");
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure LogVendor(Vend: Record Vendor)
    var
        RegnLog: Record "Registration Log";
    begin
        InsertLogRegistration(Vend."Registration No.", RegnLog."Account Type"::Vendor, Vend."No.");
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure LogContact(Cont: Record Contact)
    var
        RegnLog: Record "Registration Log";
    begin
        InsertLogRegistration(Cont."Registration No.", RegnLog."Account Type"::Contact, Cont."No.");
    end;

    local procedure InsertLogRegistration(RegNo: Text[20]; AccType: Option; AccNo: Code[20])
    var
        RegnLog: Record "Registration Log";
    begin
        with RegnLog do begin
            Init;
            "Registration No." := RegNo;
            "Account Type" := AccType;
            "Account No." := AccNo;
            "User ID" := UserId;
            Insert(true);
        end;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure LogVerification(var RegnLog: Record "Registration Log"; XmlDoc: DotNet XmlDocument; Namespace: Text)
    var
        Address: array[10] of Text;
        AddressText: Text;
        Error: Text;
    begin
        if ExtractValue('//D:VBAS', XmlDoc, Namespace) <> '' then begin
            RegnLog."Entry No." := 0;
            RegnLog.Status := RegnLog.Status::Valid;
            RegnLog."Verified Date" := CurrentDateTime;
            RegnLog."User ID" := UserId;

            // VAT Registration No.
            RegnLog."Verified VAT Registration No." :=
              CopyStr(ExtractValue('//D:DIC', XmlDoc, Namespace), 1, MaxStrLen(RegnLog."Verified VAT Registration No."));

            // Name
            RegnLog."Verified Name" :=
              CopyStr(ExtractValue('//D:OF', XmlDoc, Namespace), 1, MaxStrLen(RegnLog."Verified Name"));

            // Address information
            if ExtractValue('//D:AA', XmlDoc, Namespace) <> '' then begin
                // City
                RegnLog."Verified City" :=
                  CopyStr(ExtractValue('//D:N', XmlDoc, Namespace), 1, MaxStrLen(RegnLog."Verified City"));

                // Post Code
                RegnLog."Verified Post Code" :=
                  CopyStr(ExtractValue('//D:PSC', XmlDoc, Namespace), 1, MaxStrLen(RegnLog."Verified Post Code"));

                Address[1] := ExtractValue('//D:NU', XmlDoc, Namespace);  // Street
                Address[2] := ExtractValue('//D:NCO', XmlDoc, Namespace); // Quarter
                Address[3] := ExtractValue('//D:CD', XmlDoc, Namespace);  // Descriptive No.
                Address[4] := ExtractValue('//D:CO', XmlDoc, Namespace);  // House No.
                AddressText := ExtractValue('//D:AT', XmlDoc, Namespace); // Address Text
            end;

            RegnLog."Verified Address" := CopyStr(FormatAddress(Address), 1, MaxStrLen(RegnLog."Verified Address"));
            if RegnLog."Verified Address" = '' then
                RegnLog."Verified Address" := CopyStr(AddressText, 1, MaxStrLen(RegnLog."Verified Address"));
            RegnLog.Insert(true);
        end else begin
            if ExtractValue('//D:E', XmlDoc, Namespace) <> '' then
                Error := ExtractValue('//D:ET', XmlDoc, Namespace);

            RegnLog."Entry No." := 0;
            RegnLog."Verified Date" := CurrentDateTime;
            RegnLog.Status := RegnLog.Status::Invalid;
            RegnLog."User ID" := UserId;
            RegnLog."Verified Result" := CopyStr(Error, 1, MaxStrLen(RegnLog."Verified Result"));
            RegnLog."Verified Name" := '';
            RegnLog."Verified Address" := '';
            RegnLog."Verified City" := '';
            RegnLog."Verified Post Code" := '';
            RegnLog."Verified VAT Registration No." := '';
            RegnLog.Insert(true);
        end;
    end;

    local procedure FormatAddress(Address: array[10] of Text): Text
    var
        RegnLog: Record "Registration Log";
        Ret: Text;
    begin
        RegnLog.Init();

        Ret := Address[1];
        if Ret = '' then
            Ret := Address[2];

        if (Address[3] <> '') and (Address[4] <> '') then
            Ret := CopyStr(StrSubstNo('%1 %2/%3', Ret, Address[3], Address[4]), 1, MaxStrLen(RegnLog."Verified Address"));

        if (Address[3] <> '') xor (Address[4] <> '') then begin
            if Address[3] = '' then
                Address[3] := Address[4];
            Ret := CopyStr(StrSubstNo('%1 %2', Ret, Address[3]), 1, MaxStrLen(RegnLog."Verified Address"));
        end;

        exit(DelChr(Ret, '<>', ' '));
    end;

    local procedure LogUnloggedRegistrationNumbers(AccType: Option; AccNo: Code[20])
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        Cont: Record Contact;
        RegnLog: Record "Registration Log";
    begin
        case AccType of
            RegnLog."Account Type"::Customer:
                if Cust.Get(AccNo) then begin
                    RegnLog.SetRange("Registration No.", Cust."Registration No.");
                    if RegnLog.IsEmpty() then
                        LogCustomer(Cust);
                end;
            RegnLog."Account Type"::Vendor:
                if Vend.Get(AccNo) then begin
                    RegnLog.SetRange("Registration No.", Vend."Registration No.");
                    if RegnLog.IsEmpty() then
                        LogVendor(Vend);
                end;
            RegnLog."Account Type"::Contact:
                if Cont.Get(AccNo) then begin
                    RegnLog.SetRange("Registration No.", Cont."Registration No.");
                    if RegnLog.IsEmpty() then
                        LogContact(Cont);
                end;
        end;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure DeleteCustomerLog(Cust: Record Customer)
    var
        RegnLog: Record "Registration Log";
    begin
        DeleteLogRegistration(RegnLog."Account Type"::Customer, Cust."No.");
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure DeleteVendorLog(Vend: Record Vendor)
    var
        RegnLog: Record "Registration Log";
    begin
        DeleteLogRegistration(RegnLog."Account Type"::Vendor, Vend."No.");
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure DeleteContactLog(Cont: Record Contact)
    var
        RegnLog: Record "Registration Log";
    begin
        DeleteLogRegistration(RegnLog."Account Type"::Contact, Cont."No.");
    end;

    local procedure DeleteLogRegistration(AccType: Option; AccNo: Code[20])
    var
        RegnLog: Record "Registration Log";
    begin
        with RegnLog do begin
            SetRange("Account Type", AccType);
            SetRange("Account No.", AccNo);
            DeleteAll();
        end;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure AssistEditCustomerRegNo(Cust: Record Customer)
    var
        RegnLog: Record "Registration Log";
    begin
        AssistEditRegNo(RegnLog."Account Type"::Customer, Cust."No.");
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure AssistEditVendorRegNo(Vend: Record Vendor)
    var
        RegnLog: Record "Registration Log";
    begin
        AssistEditRegNo(RegnLog."Account Type"::Vendor, Vend."No.");
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure AssistEditContactRegNo(Cont: Record Contact)
    var
        RegnLog: Record "Registration Log";
    begin
        AssistEditRegNo(RegnLog."Account Type"::Contact, Cont."No.");
    end;

    local procedure AssistEditRegNo(AccType: Option; AccNo: Code[20])
    var
        RegnLog: Record "Registration Log";
    begin
        with RegnLog do begin
            LogUnloggedRegistrationNumbers(AccType, AccNo);
            Commit();
            SetRange("Account Type", AccType);
            SetRange("Account No.", AccNo);
            PAGE.RunModal(PAGE::"Registration Log", RegnLog);
        end;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure InitServiceSetup()
    var
        RegNoSrvConfig: Record "Reg. No. Srv Config";
        RegLookupExtDataHndl: Codeunit "Reg. Lookup Ext. Data Hndl";
    begin
        if not RegNoSrvConfig.FindFirst then begin
            RegNoSrvConfig.Init();
            RegNoSrvConfig.Insert();
        end;

        RegNoSrvConfig."Service Endpoint" := RegLookupExtDataHndl.GetRegistrationNoValidationWebServiceURL;
        RegNoSrvConfig.Enabled := false;
        RegNoSrvConfig.Modify();
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure SetupService()
    var
        RegNoSrvConfig: Record "Reg. No. Srv Config";
    begin
        if RegNoSrvConfig.FindFirst then
            exit;
        InitServiceSetup;
    end;

    local procedure ExtractValue(Xpath: Text; XMLDoc: DotNet XmlDocument; Namespace: Text): Text
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        FoundXmlNode: DotNet XmlNode;
    begin
        if not XMLDOMMgt.FindNodeWithNamespace(XMLDoc.DocumentElement, Xpath, 'D', Namespace, FoundXmlNode) then
            exit('');
        exit(FoundXmlNode.InnerText);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure CheckARESForRegNo(var RecordRef: RecordRef; var RegistrationLog: Record "Registration Log"; RecordVariant: Variant; EntryNo: Code[20]; AccountType: Option)
    var
        Customer: Record Customer;
        RegNoSrvConfig: Record "Reg. No. Srv Config";
        DataTypeManagement: Codeunit "Data Type Management";
        RegNoFieldRef: FieldRef;
        RegNo: Text[20];
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, RecordRef);
        if RegNoSrvConfig.RegNoSrvIsEnabled then begin
            if not DataTypeManagement.FindFieldByName(RecordRef, RegNoFieldRef, Customer.FieldName("Registration No.")) then
                exit;
            RegNo := RegNoFieldRef.Value;

            RegistrationLog.InitRegLog(RegistrationLog, AccountType, EntryNo, RegNo);
            CODEUNIT.Run(CODEUNIT::"Reg. Lookup Ext. Data Hndl", RegistrationLog);
        end;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure UpdateRecordFromRegLog(var RecordRef: RecordRef; RecordVariant: Variant; RegistrationLog: Record "Registration Log")
    var
        DataTypeManagement: Codeunit "Data Type Management";
    begin
        DataTypeManagement.GetRecordRef(RecordVariant, RecordRef);
        case RegistrationLog.Status of
            RegistrationLog.Status::Valid:
                if Confirm(ValidRegNoQst) then
                    RunARESUpdate(RecordRef, RecordVariant, RegistrationLog);
            RegistrationLog.Status::Invalid:
                Message(InvalidRegNoMsg);
            else
                Message(NotVerifiedRegNoMsg);
        end;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure RunARESUpdate(var RecordRef: RecordRef; RecordVariant: Variant; RegistrationLog: Record "Registration Log")
    var
        AresUpdate: Report "Ares Update";
    begin
        AresUpdate.InitializeReport(RecordVariant, RegistrationLog);
        AresUpdate.UseRequestPage(true);
        AresUpdate.RunModal;
        AresUpdate.GetRecord(RecordRef);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure ValidateRegNoWithARES(var RecordRef: RecordRef; RecordVariant: Variant; EntryNo: Code[20]; AccountType: Option)
    var
        RegistrationLog: Record "Registration Log";
    begin
        CheckARESForRegNo(RecordRef, RegistrationLog, RecordVariant, EntryNo, AccountType);

        if RegistrationLog.Find then // Only update if the log was created
            UpdateRecordFromRegLog(RecordRef, RecordVariant, RegistrationLog);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure GetServiceConditionsURL(): Text
    begin
        exit(ServiceConditionsURLTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    procedure HandleAresRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        RegNoSrvConfig: Record "Reg. No. Srv Config";
        RecRef: RecordRef;
    begin
        SetupService;
        RegNoSrvConfig.FindFirst;

        RecRef.GetTable(RegNoSrvConfig);

        if RegNoSrvConfig.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            ServiceConnection.Status := ServiceConnection.Status::Disabled;
        with RegNoSrvConfig do
            ServiceConnection.InsertServiceConnection(
              ServiceConnection, RecRef.RecordId, DescriptionLbl, "Service Endpoint", PAGE::"Registration Config");
    end;
}


#endif