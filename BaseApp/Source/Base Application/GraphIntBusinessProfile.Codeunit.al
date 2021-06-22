codeunit 5442 "Graph Int - Business Profile"
{

    trigger OnRun()
    begin
    end;

    var
        BusinessTypeTxt: Label 'Business', Locked = true;
        ShippingTypeTxt: Label 'Shipping', Locked = true;

    procedure UpdateCompanyBusinessProfileId(BusinessProfileId: Text[250])
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName);
        if Company."Business Profile Id" <> BusinessProfileId then begin
            Company."Business Profile Id" := BusinessProfileId;
            Company.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnAfterTransferRecordFields', '', false, false)]
    [Scope('OnPrem')]
    procedure OnAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var AdditionalFieldsWereModified: Boolean)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Company Information-Graph Business Profile':
                begin
                    SetAddressesOnGraph(SourceRecordRef, DestinationRecordRef);
                    AdditionalFieldsWereModified := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnAfterInsertRecord', '', false, false)]
    [Scope('OnPrem')]
    procedure OnAfterInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
        OnAfterModifyRecord(SourceRecordRef, DestinationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnAfterModifyRecord', '', false, false)]
    [Scope('OnPrem')]
    procedure OnAfterModifyRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        GraphBusinessProfile: Record "Graph Business Profile";
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Graph Business Profile-Company Information':
                begin
                    HandleLogoChanges(DestinationRecordRef, SourceRecordRef);
                    SetAddressesFromGraph(SourceRecordRef, DestinationRecordRef);
                    DestinationRecordRef.Modify(true);
                    SourceRecordRef.SetTable(GraphBusinessProfile);
                    UpdateCompanyBusinessProfileId(GraphBusinessProfile.Id);
                end;
            'Company Information-Graph Business Profile':
                begin
                    HandleLogoChanges(SourceRecordRef, DestinationRecordRef);
                    DestinationRecordRef.SetTable(GraphBusinessProfile);
                    UpdateCompanyBusinessProfileId(GraphBusinessProfile.Id);
                end;
        end;
    end;

    local procedure GetSourceDestCode(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Text
    begin
        if (SourceRecordRef.Number <> 0) and (DestinationRecordRef.Number <> 0) then
            exit(StrSubstNo('%1-%2', SourceRecordRef.Name, DestinationRecordRef.Name));
        exit('');
    end;

    local procedure SetAddressesFromGraph(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CompanyInformation: Record "Company Information";
        GraphBusinessProfile: Record "Graph Business Profile";
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        AddressesString: Text;
        EmailAddressesString: Text;
        PhoneNumbersString: Text;
        SocialLinksString: Text;
        WebsiteString: Text;
        DummyCountryCode: Code[10];
    begin
        SourceRecordRef.SetTable(GraphBusinessProfile);
        DestinationRecordRef.SetTable(CompanyInformation);

        AddressesString := GraphBusinessProfile.GetAddressesString;
        PhoneNumbersString := GraphBusinessProfile.GetPhoneNumbersString;
        WebsiteString := GraphBusinessProfile.GetWebsiteString;
        EmailAddressesString := GraphBusinessProfile.GetEmailAddressesString;
        SocialLinksString := GraphBusinessProfile.GetSocialLinksString;

        if GraphMgtCompanyInfo.HasPostalAddress(AddressesString, BusinessTypeTxt) then
            with CompanyInformation do
                GraphMgtCompanyInfo.GetPostalAddress(AddressesString, BusinessTypeTxt, Address, "Address 2",
                  City, County, DummyCountryCode, "Post Code");

        if GraphMgtCompanyInfo.HasPostalAddress(AddressesString, ShippingTypeTxt) then
            with CompanyInformation do
                GraphMgtCompanyInfo.GetPostalAddress(AddressesString, ShippingTypeTxt, "Ship-to Address", "Ship-to Address 2",
                  "Ship-to City", "Ship-to County", "Ship-to Country/Region Code", "Ship-to Post Code");

        if GraphMgtCompanyInfo.HasEmailAddress(EmailAddressesString, BusinessTypeTxt) then
            GraphMgtCompanyInfo.GetEmailAddress(EmailAddressesString, BusinessTypeTxt, CompanyInformation."E-Mail");

        if GraphMgtCompanyInfo.HasPhoneNumber(PhoneNumbersString, BusinessTypeTxt) then
            GraphMgtCompanyInfo.GetPhone(PhoneNumbersString, BusinessTypeTxt, CompanyInformation."Phone No.");

        if WebsiteString <> '' then
            GraphMgtCompanyInfo.GetWebsite(WebsiteString, CompanyInformation."Home Page");

        if SocialLinksString <> '' then
            GraphMgtCompanyInfo.UpdateSocialNetworks(SocialLinksString);

        DestinationRecordRef.GetTable(CompanyInformation);
    end;

    local procedure SetAddressesOnGraph(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CompanyInformation: Record "Company Information";
        GraphBusinessProfile: Record "Graph Business Profile";
        O365SocialNetwork: Record "O365 Social Network";
        GraphMgtCompanyInfo: Codeunit "Graph Mgt - Company Info.";
        AddressesString: Text;
        EmailAddressesString: Text;
        PhoneNumbersString: Text;
        SocialNetworksString: Text;
        WebsiteString: Text;
    begin
        SourceRecordRef.SetTable(CompanyInformation);
        DestinationRecordRef.SetTable(GraphBusinessProfile);

        AddressesString := GraphBusinessProfile.GetAddressesString;
        with CompanyInformation do begin
            AddressesString := GraphMgtCompanyInfo.UpdatePostalAddressJson(AddressesString, BusinessTypeTxt,
                Address, "Address 2", City, County, "Country/Region Code", "Post Code");
            AddressesString := GraphMgtCompanyInfo.UpdatePostalAddressJson(AddressesString, ShippingTypeTxt,
                "Ship-to Address", "Ship-to Address 2", "Ship-to City", "Ship-to County", "Ship-to Country/Region Code", "Ship-to Post Code");
        end;
        GraphBusinessProfile.SetAddressesString(AddressesString);

        EmailAddressesString := GraphBusinessProfile.GetEmailAddressesString;
        EmailAddressesString :=
          GraphMgtCompanyInfo.UpdateEmailAddressJson(EmailAddressesString, BusinessTypeTxt, CompanyInformation."E-Mail");
        GraphBusinessProfile.SetEmailAddressesString(EmailAddressesString);

        PhoneNumbersString := GraphBusinessProfile.GetPhoneNumbersString;
        PhoneNumbersString := GraphMgtCompanyInfo.UpdatePhoneJson(PhoneNumbersString, BusinessTypeTxt, CompanyInformation."Phone No.");
        GraphBusinessProfile.SetPhoneNumbersString(PhoneNumbersString);

        WebsiteString := GraphBusinessProfile.GetWebsiteString;
        WebsiteString := GraphMgtCompanyInfo.UpdateWorkWebsiteJson(WebsiteString, BusinessTypeTxt, CompanyInformation."Home Page");
        GraphBusinessProfile.SetWebsitesString(WebsiteString);

        GraphMgtCompanyInfo.GetSocialNetworksJSON(O365SocialNetwork, SocialNetworksString);
        GraphBusinessProfile.SetSocialLinksString(SocialNetworksString);

        DestinationRecordRef.GetTable(GraphBusinessProfile);
    end;

    local procedure HandleLogoChanges(var LocalRecRef: RecordRef; var GraphRecRef: RecordRef)
    var
        CompanyInformation: Record "Company Information";
        GraphBusinessProfile: Record "Graph Business Profile";
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        DateVariant: Variant;
        LastModifiedDateTime: DateTime;
        SetFromGraph: Boolean;
    begin
        LocalRecRef.SetTable(CompanyInformation);
        GraphRecRef.SetTable(GraphBusinessProfile);

        if GraphBusinessProfile.CalcFields(Logo) and GraphBusinessProfile.Logo.HasValue then begin
            JSONManagement.InitializeObject(GraphBusinessProfile.GetLogoString);
            JSONManagement.GetJSONObject(JObject);
            JSONManagement.GetPropertyValueFromJObjectByName(JObject, 'lastModifiedDate', DateVariant);
            if Evaluate(LastModifiedDateTime, Format(DateVariant)) then
                if LastModifiedDateTime > DotNet_DateTimeOffset.ConvertToUtcDateTime(CompanyInformation."Picture - Last Mod. Date Time")
                then begin
                    // Need to update picture from graph;
                    GraphBusinessProfile.CalcFields(LogoContent);
                    CompanyInformation.Validate(Picture, GraphBusinessProfile.LogoContent);
                    CompanyInformation.Modify(true);
                    SetFromGraph := true;
                end;
        end;

        if not SetFromGraph then begin
            if CompanyInformation."Last Modified Date Time" = CompanyInformation."Picture - Last Mod. Date Time" then
                if CompanyInformation.Picture.HasValue then begin
                    CompanyInformation.CalcFields(Picture);
                    Clear(GraphBusinessProfile.Logo);
                    GraphBusinessProfile.LogoContent := CompanyInformation.Picture;
                    GraphBusinessProfile.Modify();
                end;

            if (not GraphBusinessProfile.Logo.HasValue) and (not GraphBusinessProfile.LogoContent.HasValue) then begin
                Clear(CompanyInformation.Picture);
                CompanyInformation.Validate(Picture);
                CompanyInformation.Modify(true);
            end;
        end;

        LocalRecRef.GetTable(CompanyInformation);
        GraphRecRef.SetTable(GraphBusinessProfile);
    end;

    procedure SyncFromGraphSynchronously()
    begin
    end;
}

