codeunit 249 "VAT Registration Log Mgt."
{
    Permissions = TableData "VAT Registration Log" = rimd;

    trigger OnRun()
    begin
    end;

    var
        ValidPathTxt: Label 'descendant::vat:valid', Locked = true;
        NamePathTxt: Label 'descendant::vat:traderName', Locked = true;
        AddressPathTxt: Label 'descendant::vat:traderAddress', Locked = true;
        RequestIdPathTxt: Label 'descendant::vat:requestIdentifier', Locked = true;
        PostcodePathTxt: Label 'descendant::vat:traderPostcode', Locked = true;
        StreetPathTxt: Label 'descendant::vat:traderStreet', Locked = true;
        CityPathTxt: Label 'descendant::vat:traderCity', Locked = true;
        DataTypeManagement: Codeunit "Data Type Management";
        ValidVATNoMsg: Label 'The VAT registration number is valid.';
        InvalidVatRegNoMsg: Label 'We didn''t find a match for this number. Verify that you entered the correct number.';
        NotVerifiedVATRegMsg: Label 'We couldn''t verify the VAT registration number. Try again later.';
        VATSrvDisclaimerUrlTok: Label 'https://go.microsoft.com/fwlink/?linkid=841741', Locked = true;
        DescriptionLbl: Label 'EU VAT Reg. No. Validation Service Setup';
        UnexpectedResponseErr: Label 'The VAT registration number could not be verified because the VIES VAT Registration No. service may be currently unavailable for the selected EU state, %1.', Comment = '%1 - Country / Region Code';
        EUVATRegNoValidationServiceTok: Label 'EUVATRegNoValidationServiceTelemetryCategoryTok', Locked = true;
        ValidationFailureMsg: Label 'VIES service may be currently unavailable', Locked = true;
        NameMatchPathTxt: Label 'descendant::vat:traderNameMatch', Locked = true;
        StreetMatchPathTxt: Label 'descendant::vat:traderStreetMatch', Locked = true;
        PostcodeMatchPathTxt: Label 'descendant::vat:traderPostcodeMatch', Locked = true;
        CityMatchPathTxt: Label 'descendant::vat:traderCityMatch', Locked = true;
        DetailsNotVerifiedMsg: Label 'VAT registration number is valid.\No details information was provided by VIES service.';

    procedure LogCustomer(Customer: Record Customer)
    var
        VATRegistrationLog: Record "VAT Registration Log";
        CountryCode: Code[10];
    begin
        CountryCode := GetCountryCode(Customer."Country/Region Code");
        if not IsEUCountry(CountryCode) then
            exit;

        InsertVATRegistrationLog(
          Customer."VAT Registration No.", CountryCode, VATRegistrationLog."Account Type"::Customer, Customer."No.");
    end;

    procedure LogVendor(Vendor: Record Vendor)
    var
        VATRegistrationLog: Record "VAT Registration Log";
        CountryCode: Code[10];
    begin
        CountryCode := GetCountryCode(Vendor."Country/Region Code");
        if not IsEUCountry(CountryCode) then
            exit;

        InsertVATRegistrationLog(
          Vendor."VAT Registration No.", CountryCode, VATRegistrationLog."Account Type"::Vendor, Vendor."No.");
    end;

    procedure LogContact(Contact: Record Contact)
    var
        VATRegistrationLog: Record "VAT Registration Log";
        CountryCode: Code[10];
    begin
        CountryCode := GetCountryCode(Contact."Country/Region Code");
        if not IsEUCountry(CountryCode) then
            exit;

        InsertVATRegistrationLog(
          Contact."VAT Registration No.", CountryCode, VATRegistrationLog."Account Type"::Contact, Contact."No.");
    end;

    [Scope('OnPrem')]
    procedure LogVerification(var VATRegistrationLog: Record "VAT Registration Log"; XMLDoc: DotNet XmlDocument; Namespace: Text)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        FoundXmlNode: DotNet XmlNode;
        ResponsedName: Text;
        ResponsedPostCode: Text;
        ResponsedCity: Text;
        ResponsedStreet: Text;
        ResponsedAddress: Text;
        MatchName: Boolean;
        MatchStreet: Boolean;
        MatchPostCode: Boolean;
        MatchCity: Boolean;
    begin
        if not XMLDOMMgt.FindNodeWithNamespace(XMLDoc.DocumentElement, ValidPathTxt, 'vat', Namespace, FoundXmlNode) then begin
            Session.LogMessage('0000C4T', ValidationFailureMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EUVATRegNoValidationServiceTok);
            Error(UnexpectedResponseErr, VATRegistrationLog."Country/Region Code");
        end;

        case LowerCase(FoundXmlNode.InnerText) of
            'true':
                begin
                    VATRegistrationLog."Entry No." := 0;
                    VATRegistrationLog.Status := VATRegistrationLog.Status::Valid;
                    VATRegistrationLog."Verified Date" := CurrentDateTime;
                    VATRegistrationLog."User ID" := UserId;

                    VATRegistrationLog."Request Identifier" := CopyStr(ExtractValue(RequestIdPathTxt, XMLDoc, Namespace), 1,
                        MaxStrLen(VATRegistrationLog."Request Identifier"));

                    ResponsedName := ExtractValue(NamePathTxt, XMLDoc, Namespace);
                    ResponsedAddress := ExtractValue(AddressPathTxt, XMLDoc, Namespace);
                    ResponsedStreet := ExtractValue(StreetPathTxt, XMLDoc, Namespace);
                    ResponsedPostCode := ExtractValue(PostcodePathTxt, XMLDoc, Namespace);
                    ResponsedCity := ExtractValue(CityPathTxt, XMLDoc, Namespace);
                    VATRegistrationLog.SetResponseDetails(
                      ResponsedName, ResponsedAddress, ResponsedStreet, ResponsedCity, ResponsedPostCode);

                    MatchName := ExtractValue(NameMatchPathTxt, XMLDoc, Namespace) = '1';
                    MatchStreet := ExtractValue(StreetMatchPathTxt, XMLDoc, Namespace) = '1';
                    MatchPostCode := ExtractValue(PostcodeMatchPathTxt, XMLDoc, Namespace) = '1';
                    MatchCity := ExtractValue(CityMatchPathTxt, XMLDoc, Namespace) = '1';
                    VATRegistrationLog.SetResponseMatchDetails(MatchName, MatchStreet, MatchCity, MatchPostCode);

                    VATRegistrationLog.Insert(true);

                    if VATRegistrationLog.LogDetails() then
                        VATRegistrationLog.Modify();
                end;
            'false':
                begin
                    VATRegistrationLog."Entry No." := 0;
                    VATRegistrationLog."Verified Date" := CurrentDateTime;
                    VATRegistrationLog.Status := VATRegistrationLog.Status::Invalid;
                    VATRegistrationLog."User ID" := UserId;
                    VATRegistrationLog."Verified Name" := '';
                    VATRegistrationLog."Verified Address" := '';
                    VATRegistrationLog."Request Identifier" := '';
                    VATRegistrationLog."Verified Postcode" := '';
                    VATRegistrationLog."Verified Street" := '';
                    VATRegistrationLog."Verified City" := '';
                    VATRegistrationLog.Insert(true);
                end;
        end;
    end;

    local procedure LogUnloggedVATRegistrationNumbers()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        Customer.SetFilter("VAT Registration No.", '<>%1', '');
        if Customer.FindSet() then
            repeat
                VATRegistrationLog.SetRange("VAT Registration No.", Customer."VAT Registration No.");
                if VATRegistrationLog.IsEmpty() then
                    LogCustomer(Customer);
            until Customer.Next() = 0;

        Vendor.SetFilter("VAT Registration No.", '<>%1', '');
        if Vendor.FindSet() then
            repeat
                VATRegistrationLog.SetRange("VAT Registration No.", Vendor."VAT Registration No.");
                if VATRegistrationLog.IsEmpty() then
                    LogVendor(Vendor);
            until Vendor.Next() = 0;

        Contact.SetFilter("VAT Registration No.", '<>%1', '');
        if Contact.FindSet() then
            repeat
                VATRegistrationLog.SetRange("VAT Registration No.", Contact."VAT Registration No.");
                if VATRegistrationLog.IsEmpty() then
                    LogContact(Contact);
            until Contact.Next() = 0;

        Commit();
    end;

    local procedure InsertVATRegistrationLog(VATRegNo: Text[20]; CountryCode: Code[10]; AccountType: Enum "VAT Registration Log Account Type"; AccountNo: Code[20])
    var
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        with VATRegistrationLog do begin
            Init();
            "VAT Registration No." := VATRegNo;
            "Country/Region Code" := CountryCode;
            "Account Type" := AccountType;
            "Account No." := AccountNo;
            "User ID" := UserId;
            Insert(true);
        end;

        OnAfterInsertVATRegistrationLog(VATRegistrationLog);
    end;

    procedure DeleteCustomerLog(Customer: Record Customer)
    var
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        with VATRegistrationLog do begin
            SetRange("Account Type", "Account Type"::Customer);
            SetRange("Account No.", Customer."No.");
            if not IsEmpty() then
                DeleteAll();
        end;
    end;

    procedure DeleteVendorLog(Vendor: Record Vendor)
    var
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        with VATRegistrationLog do begin
            SetRange("Account Type", "Account Type"::Vendor);
            SetRange("Account No.", Vendor."No.");
            if not IsEmpty() then
                DeleteAll();
        end;
    end;

    procedure DeleteContactLog(Contact: Record Contact)
    var
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        with VATRegistrationLog do begin
            SetRange("Account Type", "Account Type"::Contact);
            SetRange("Account No.", Contact."No.");
            if not IsEmpty() then
                DeleteAll();
        end;
    end;

    procedure AssistEditCustomerVATReg(Customer: Record Customer)
    var
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        CheckAndLogUnloggedVATRegistrationNumbers(VATRegistrationLog, VATRegistrationLog."Account Type"::Customer, Customer."No.");
        CheckIfCountryCodeIsSet(Customer);
        OnAssistEditCustomerVATRegOnBeforeRunPageVATRegistrationLog(VATRegistrationLog, Customer);
        Page.RunModal(Page::"VAT Registration Log", VATRegistrationLog);
    end;

    procedure CheckIfCountryCodeIsSet(Customer: Record Customer)
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        CountryRegion: Record "Country/Region";
        EmptyCountryCodeErr: Label 'You must specify the country that issued the VAT registration number. Choose the country in the Country/Region Code field.';
        EmptyEUCountryCodeErr: Label 'You must specify the EU Country/Region Code for the country that issued the VAT registration number. You can specify that on the Country/Regions page.';
    begin
        if VATRegNoSrvConfig.VATRegNoSrvIsEnabled() then begin
            if Customer."Country/Region Code" = '' then
                Error(EmptyCountryCodeErr);

            if not CountryRegion.IsEUCountry(Customer."Country/Region Code") then
                Error(EmptyEUCountryCodeErr);
        end;
    end;

    procedure AssistEditVendorVATReg(Vendor: Record Vendor)
    var
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        CheckAndLogUnloggedVATRegistrationNumbers(VATRegistrationLog, VATRegistrationLog."Account Type"::Vendor, Vendor."No.");
        OnAssistEditVendorVATRegOnBeforeRunPageVATRegistrationLog(VATRegistrationLog, Vendor);
        Page.RunModal(Page::"VAT Registration Log", VATRegistrationLog);
    end;

    procedure AssistEditContactVATReg(Contact: Record Contact)
    var
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        CheckAndLogUnloggedVATRegistrationNumbers(VATRegistrationLog, VATRegistrationLog."Account Type"::Contact, Contact."No.");
        OnAssistEditContactVATRegOnBeforeRunPageVATRegistrationLog(VATRegistrationLog, Contact);
        Page.RunModal(Page::"VAT Registration Log", VATRegistrationLog);
    end;

    procedure AssistEditCompanyInfoVATReg()
    var
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        CheckAndLogUnloggedVATRegistrationNumbers(VATRegistrationLog, VATRegistrationLog."Account Type"::"Company Information", '');
        Page.RunModal(Page::"VAT Registration Log", VATRegistrationLog);
    end;

    local procedure CheckAndLogUnloggedVATRegistrationNumbers(var VATRegistrationLog: Record "VAT Registration Log"; AccountType: Enum "VAT Registration Log Account Type"; AccountNo: Code[20])
    begin
        VATRegistrationLog.SetRange("Account Type", AccountType);
        VATRegistrationLog.SetRange("Account No.", AccountNo);
        if VATRegistrationLog.IsEmpty() then
            LogUnloggedVATRegistrationNumbers();
    end;

    local procedure IsEUCountry(CountryCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
    begin
        if (CountryCode = '') and CompanyInformation.Get() then
            CountryCode := CompanyInformation."Country/Region Code";

        if CountryCode <> '' then
            if CountryRegion.Get(CountryCode) then
                exit(CountryRegion."EU Country/Region Code" <> '');

        exit(false);
    end;

    local procedure GetCountryCode(CountryCode: Code[10]): Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        if CountryCode <> '' then
            exit(CountryCode);

        CompanyInformation.Get();
        exit(CompanyInformation."Country/Region Code");
    end;

    local procedure ExtractValue(Xpath: Text; XMLDoc: DotNet XmlDocument; Namespace: Text): Text
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        FoundXmlNode: DotNet XmlNode;
    begin
        if not XMLDOMMgt.FindNodeWithNamespace(XMLDoc.DocumentElement, Xpath, 'vat', Namespace, FoundXmlNode) then
            exit('');
        exit(FoundXmlNode.InnerText);
    end;

    procedure CheckVIESForVATNo(var RecordRef: RecordRef; var VATRegistrationLog: Record "VAT Registration Log"; RecordVariant: Variant; EntryNo: Code[20]; CountryCode: Code[10]; AccountType: Option)
    var
        Customer: Record Customer;
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        CountryRegion: Record "Country/Region";
        VatRegNoFieldRef: FieldRef;
        VATRegNo: Text[20];
    begin
        RecordRef.GetTable(RecordVariant);
        if not CountryRegion.IsEUCountry(CountryCode) then
            exit; // VAT Reg. check Srv. is only available for EU countries.

        if VATRegNoSrvConfig.VATRegNoSrvIsEnabled() then begin
            DataTypeManagement.GetRecordRef(RecordVariant, RecordRef);
            if not DataTypeManagement.FindFieldByName(RecordRef, VatRegNoFieldRef, Customer.FieldName("VAT Registration No.")) then
                exit;
            VATRegNo := VatRegNoFieldRef.Value;

            VATRegistrationLog.InitVATRegLog(VATRegistrationLog, CountryCode, AccountType, EntryNo, VATRegNo);
            CODEUNIT.Run(CODEUNIT::"VAT Lookup Ext. Data Hndl", VATRegistrationLog);
        end;
    end;

    procedure UpdateRecordFromVATRegLog(var RecordRef: RecordRef; RecordVariant: Variant; VATRegistrationLog: Record "VAT Registration Log")
    begin
        if GuiAllowed() then begin
            RecordRef.GetTable(RecordVariant);
            case VATRegistrationLog.Status of
                VATRegistrationLog.Status::Valid:
                    case VATRegistrationLog."Details Status" of
                        VATRegistrationLog."Details Status"::"Not Verified":
                            Message(DetailsNotVerifiedMsg);
                        VATRegistrationLog."Details Status"::Valid:
                            Message(ValidVATNoMsg);
                        VATRegistrationLog."Details Status"::"Partially Valid",
                        VATRegistrationLog."Details Status"::"Not Valid":
                            begin
                                DataTypeManagement.GetRecordRef(RecordVariant, RecordRef);
                                VATRegistrationLog.OpenDetailsForRecRef(RecordRef);
                            end;
                    end;
                VATRegistrationLog.Status::Invalid:
                    Message(InvalidVatRegNoMsg);
                else
                    Message(NotVerifiedVATRegMsg);
            end;
        end;
    end;

    procedure InitServiceSetup()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        VATLookupExtDataHndl: Codeunit "VAT Lookup Ext. Data Hndl";
    begin
        if not VATRegNoSrvConfig.FindFirst() then begin
            VATRegNoSrvConfig.Init();
            VATRegNoSrvConfig."Service Endpoint" := VATLookupExtDataHndl.GetVATRegNrValidationWebServiceURL();
            VATRegNoSrvConfig.Enabled := false;
            VATRegNoSrvConfig.Insert();
        end;
    end;

    procedure SetupService()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        if VATRegNoSrvConfig.FindFirst() then
            exit;
        InitServiceSetup();
    end;

    procedure EnableService()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        if not VATRegNoSrvConfig.FindFirst() then begin
            InitServiceSetup();
            VATRegNoSrvConfig.FindFirst();
        end;

        VATRegNoSrvConfig.Enabled := true;
        VATRegNoSrvConfig.Modify();
    end;

    procedure ValidateVATRegNoWithVIES(var RecordRef: RecordRef; RecordVariant: Variant; EntryNo: Code[20]; AccountType: Option; CountryCode: Code[10])
    var
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        CheckVIESForVATNo(RecordRef, VATRegistrationLog, RecordVariant, EntryNo, CountryCode, AccountType);

        if VATRegistrationLog.Find() then // Only update if the log was created
            UpdateRecordFromVATRegLog(RecordRef, RecordVariant, VATRegistrationLog);
    end;

    procedure GetServiceDisclaimerUR(): Text
    begin
        exit(VATSrvDisclaimerUrlTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    procedure HandleViesRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        RecRef: RecordRef;
    begin
        SetupService();
        VATRegNoSrvConfig.FindFirst();

        RecRef.GetTable(VATRegNoSrvConfig);

        if VATRegNoSrvConfig.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            ServiceConnection.Status := ServiceConnection.Status::Disabled;
        with VATRegNoSrvConfig do
            ServiceConnection.InsertServiceConnection(
              ServiceConnection, RecRef.RecordId, DescriptionLbl, "Service Endpoint", PAGE::"VAT Registration Config");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertVATRegistrationLog(var VATRegistrationLog: Record "VAT Registration Log")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditContactVATRegOnBeforeRunPageVATRegistrationLog(var VATRegistrationLog: Record "VAT Registration Log"; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditCustomerVATRegOnBeforeRunPageVATRegistrationLog(var VATRegistrationLog: Record "VAT Registration Log"; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditVendorVATRegOnBeforeRunPageVATRegistrationLog(var VATRegistrationLog: Record "VAT Registration Log"; Vendor: Record Vendor)
    begin
    end;
}

