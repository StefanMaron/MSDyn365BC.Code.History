codeunit 5473 "Graph Mgt - Company Info."
{

    trigger OnRun()
    begin
    end;

    procedure ProcessComplexTypes(var CompanyInformation: Record "Company Information"; PostalAddressJSON: Text)
    begin
        UpdatePostalAddress(PostalAddressJSON, CompanyInformation);
    end;

    procedure PostalAddressToJSON(CompanyInformation: Record "Company Information") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with CompanyInformation do
            GraphMgtComplexTypes.GetPostalAddressJSON(Address, "Address 2", City, County, "Country/Region Code", "Post Code", JSON);
    end;

    procedure UpdateIntegrationRecords(IsCompanyIdFound: Boolean)
    var
        DummyCompanyInfo: Record "Company Information";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        CompanyRecRef: RecordRef;
    begin
        CompanyRecRef.Open(DATABASE::"Company Information");
        GraphMgtGeneralTools.UpdateIntegrationRecords(CompanyRecRef, DummyCompanyInfo.FieldNo(Id), IsCompanyIdFound);
    end;

    local procedure UpdatePostalAddress(PostalAddressJSON: Text; var CompanyInformation: Record "Company Information")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if PostalAddressJSON = '' then
            exit;

        with CompanyInformation do begin
            RecRef.GetTable(CompanyInformation);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(PostalAddressJSON, RecRef,
              FieldNo(Address), FieldNo("Address 2"), FieldNo(City), FieldNo(County), FieldNo("Country/Region Code"), FieldNo("Post Code"));
            RecRef.SetTable(CompanyInformation);
        end;
    end;

    procedure AddEmailAddress(var JSONManagement: Codeunit "JSON Management"; Name: Text; Type: Text; Address: Text)
    var
        JObject: DotNet JObject;
    begin
        if Address = '' then
            exit;

        JObject := JObject.JObject;
        JSONManagement.AddJPropertyToJObject(JObject, 'name', Name);
        JSONManagement.AddJPropertyToJObject(JObject, 'type', Type);
        JSONManagement.AddJPropertyToJObject(JObject, 'address', Address);
        JSONManagement.AddJObjectToCollection(JObject);
    end;

    procedure GetPostalAddress(PostalAddressesString: Text; AddressType: Text; var Address: Text[100]; var Address2: Text[50]; var City: Text[30]; var County: Text[30]; var CountryRegionCode: Code[10]; var PostCode: Code[20])
    var
        JSONManagement: Codeunit "JSON Management";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        JObject: DotNet JObject;
        Value: Text;
    begin
        JSONManagement.InitializeCollection(PostalAddressesString);
        if not JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'type', AddressType) then
            exit;

        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'street', Value);
        GraphCollectionMgtContact.SplitStreet(Value, Address, Address2);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'city', Value);
        City := CopyStr(Value, 1, MaxStrLen(Value));
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'state', Value);
        County := CopyStr(Value, 1, MaxStrLen(Value));
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'countryOrRegion', Value);
        CountryRegionCode := GraphCollectionMgtContact.FindCountryRegionCode(Value);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'postalCode', Value);
        PostCode := CopyStr(Value, 1, MaxStrLen(PostCode));
    end;

    procedure GetEmailAddress(EmailAddressesString: Text; AddressType: Text; var Address: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeCollection(EmailAddressesString);
        if not JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'type', AddressType) then
            exit;

        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'address', Address);
    end;

    procedure GetPhone(PhonesString: Text; PhoneType: Text; var Number: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeCollection(PhonesString);
        if not JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'type', PhoneType) then
            exit;

        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'number', Number);
    end;

    procedure GetWebsite(WebsiteString: Text; var Website: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeObject(WebsiteString);
        JSONManagement.GetJSONObject(JObject);
        JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, 'address', Website);
    end;

    procedure GetSocialNetworksJSON(var O365SocialNetwork: Record "O365 Social Network"; var SocialNetworks: Text)
    var
        JSONMgt: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        if O365SocialNetwork.FindSet then begin
            JSONMgt.InitializeEmptyCollection;
            repeat
                JSONMgt.InitializeEmptyObject;
                JSONMgt.GetJSONObject(JObject);
                JSONMgt.AddJPropertyToJObject(JObject, 'address', O365SocialNetwork.URL);
                JSONMgt.AddJPropertyToJObject(JObject, 'displayName', O365SocialNetwork.Name);
                JSONMgt.AddJObjectToCollection(JObject);
            until O365SocialNetwork.Next = 0;
            SocialNetworks := JSONMgt.WriteCollectionToString;
        end;
    end;

    procedure HasPostalAddress(AddressString: Text; AddressType: Text): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeCollection(AddressString);
        exit(JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'type', AddressType));
    end;

    procedure HasEmailAddress(EmailAddressString: Text; AddressType: Text): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeCollection(EmailAddressString);
        exit(JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'type', AddressType));
    end;

    procedure HasPhoneNumber(PhoneNumberString: Text; PhoneType: Text): Boolean
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeCollection(PhoneNumberString);
        exit(JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'type', PhoneType));
    end;

    procedure UpdateEmailAddressJson(EmailAddressesString: Text; AddressType: Text; Address: Text): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeCollection(EmailAddressesString);
        if JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'type', AddressType) then begin
            JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'name', '');
            JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'address', Address)
        end else
            AddEmailAddress(JSONManagement, AddressType, AddressType, Address);

        exit(JSONManagement.WriteCollectionToString);
    end;

    procedure UpdatePhoneJson(PhonesString: Text; PhoneType: Text; Number: Text): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeCollection(PhonesString);
        if not JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'type', PhoneType) then begin
            if Number = '' then
                exit;
            JObject := JObject.JObject;
            JSONManagement.AddJPropertyToJObject(JObject, 'type', PhoneType);
            JSONManagement.AddJObjectToCollection(JObject);
            JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'type', PhoneType)
        end;
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'number', Number);
        exit(JSONManagement.WriteCollectionToString);
    end;

    procedure UpdatePostalAddressJson(PostalAddressesString: Text; AddressType: Text; Address: Text[100]; Address2: Text[50]; City: Text[30]; County: Text[30]; CountryRegionCode: Code[10]; PostCode: Code[20]): Text
    var
        JSONManagement: Codeunit "JSON Management";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        JObject: DotNet JObject;
    begin
        JSONManagement.InitializeCollection(PostalAddressesString);
        if (Address = '') and (Address2 = '') and (City = '') and (County = '') and (PostCode = '') then begin
            if JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'type', AddressType) then
                JObject.Remove;
            exit(JSONManagement.WriteCollectionToString);
        end;

        if not JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'type', AddressType) then begin
            JObject := JObject.JObject;
            JSONManagement.AddJPropertyToJObject(JObject, 'type', AddressType);
            JSONManagement.AddJObjectToCollection(JObject);
            JSONManagement.GetJObjectFromCollectionByPropertyValue(JObject, 'type', AddressType);
        end;
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'street', GraphCollectionMgtContact.ConcatenateStreet(Address, Address2));
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'city', City);
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'state', County);
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'countryOrRegion', CountryRegionCode);
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'postalCode', PostCode);
        exit(JSONManagement.WriteCollectionToString);
    end;

    procedure UpdateSocialNetworks(SocialLinksString: Text)
    var
        O365SocialNetwork: Record "O365 Social Network";
        TempO365SocialNetwork: Record "O365 Social Network" temporary;
        JSONMgt: Codeunit "JSON Management";
        JArray: DotNet JArray;
        JObject: DotNet JObject;
        FieldVariant: Variant;
        Address: Text;
        DisplayName: Text;
    begin
        if SocialLinksString <> '' then begin
            JSONMgt.InitializeCollection(SocialLinksString);
            JSONMgt.GetJsonArray(JArray);
            foreach JObject in JArray do begin
                JSONMgt.GetPropertyValueFromJObjectByName(JObject, 'displayName', FieldVariant);
                DisplayName := Format(FieldVariant);
                if DisplayName <> '' then begin
                    JSONMgt.GetPropertyValueFromJObjectByName(JObject, 'address', FieldVariant);
                    Address := Format(FieldVariant);
                    O365SocialNetwork.FilterGroup(-1);
                    O365SocialNetwork.SetRange(Code, DisplayName);
                    O365SocialNetwork.SetRange(Name, DisplayName);
                    if O365SocialNetwork.FindFirst then begin
                        O365SocialNetwork.Validate(URL, CopyStr(Address, 1, MaxStrLen(O365SocialNetwork.URL)));
                        O365SocialNetwork.Modify(true);
                    end else begin
                        O365SocialNetwork.Init();
                        O365SocialNetwork.Code := CopyStr(DisplayName, 1, MaxStrLen(O365SocialNetwork.Code));
                        O365SocialNetwork.Name := CopyStr(DisplayName, 1, MaxStrLen(O365SocialNetwork.Name));
                        O365SocialNetwork.Validate(URL, CopyStr(Address, 1, MaxStrLen(O365SocialNetwork.URL)));
                        O365SocialNetwork.Insert(true);
                    end;
                    if not TempO365SocialNetwork.Get(DisplayName) then begin
                        TempO365SocialNetwork.Init();
                        TempO365SocialNetwork.Code := CopyStr(DisplayName, 1, MaxStrLen(TempO365SocialNetwork.Code));
                        TempO365SocialNetwork.Insert();
                    end;
                end;
            end;
        end;
        O365SocialNetwork.Reset();
        if O365SocialNetwork.FindSet then
            repeat
                if not TempO365SocialNetwork.Get(O365SocialNetwork.Code) then
                    if O365SocialNetwork."Media Resources Ref" <> '' then begin
                        O365SocialNetwork.Validate(URL, '');
                        O365SocialNetwork.Modify(true);
                    end else
                        O365SocialNetwork.Delete(true);
            until O365SocialNetwork.Next = 0;
    end;

    procedure UpdateWorkWebsiteJson(WebsitesString: Text; WebsiteType: Text; Address: Text[80]): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        Type: Variant;
    begin
        JSONManagement.InitializeObject(WebsitesString);
        JSONManagement.GetJSONObject(JObject);
        JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'address', Address);
        if not JSONManagement.GetPropertyValueFromJObjectByName(JObject, 'type', Type) then
            JSONManagement.ReplaceOrAddJPropertyInJObject(JObject, 'type', WebsiteType);
        exit(JSONManagement.WriteObjectToString);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIntegrationRecords(false);
    end;
}

