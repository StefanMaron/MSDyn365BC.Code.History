codeunit 5460 "Graph Int. - Contact Addresses"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnAfterTransferRecordFields', '', false, false)]
    [Scope('OnPrem')]
    procedure OnAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var AdditionalFieldsWereModified: Boolean)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Contact-Graph Contact':
                begin
                    SetContactAddressesOnGraph(SourceRecordRef, DestinationRecordRef);
                    AdditionalFieldsWereModified := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnAfterInsertRecord', '', false, false)]
    [Scope('OnPrem')]
    procedure OnAfterInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Graph Contact-Contact':
                begin
                    CreateContactAddressesFromGraph(SourceRecordRef, DestinationRecordRef);
                    DestinationRecordRef.Modify(true);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, 5345, 'OnAfterModifyRecord', '', false, false)]
    [Scope('OnPrem')]
    procedure OnAfterModifyRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Graph Contact-Contact':
                begin
                    SetContactAddressesFromGraph(SourceRecordRef, DestinationRecordRef);
                    DestinationRecordRef.Modify(true);
                end;
        end;
    end;

    local procedure GetSourceDestCode(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Text
    begin
        if (SourceRecordRef.Number <> 0) and (DestinationRecordRef.Number <> 0) then
            exit(StrSubstNo('%1-%2', SourceRecordRef.Name, DestinationRecordRef.Name));
        exit('');
    end;

    procedure GetContactAlternativeHomeAddressCode(): Code[10]
    begin
        exit(UpperCase('Home'));
    end;

    procedure GetContactAlternativeOtherAddressCode(): Code[10]
    begin
        exit(UpperCase('Other'));
    end;

    local procedure SetContactAddressesOnGraph(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        Contact: Record Contact;
        GRAPHContact: Record "Graph Contact";
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        AddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
    begin
        SourceRecordRef.SetTable(Contact);
        DestinationRecordRef.SetTable(GRAPHContact);

        AddressesString := GRAPHContact.GetPostalAddressesString;
        PhonesString := GRAPHContact.GetPhonesString;
        WebsitesString := GRAPHContact.GetWebsitesString;

        AddressesString := GraphCollectionMgtContact.UpdateBusinessAddress(AddressesString, Contact.Address,
            Contact."Address 2", Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");
        PhonesString := GraphCollectionMgtContact.UpdateBusinessPhone(PhonesString, Contact."Phone No.");
        PhonesString := GraphCollectionMgtContact.UpdateBusinessFaxPhone(PhonesString, Contact."Fax No.");
        PhonesString := GraphCollectionMgtContact.UpdateMobilePhone(PhonesString, Contact."Mobile Phone No.");
        PhonesString := GraphCollectionMgtContact.UpdatePagerPhone(PhonesString, Contact.Pager);
        WebsitesString := GraphCollectionMgtContact.UpdateHomeWebsite(WebsitesString, Contact."Home Page");

        if ContactAltAddress.Get(Contact."No.", GetContactAlternativeHomeAddressCode) then begin
            AddressesString := GraphCollectionMgtContact.UpdateHomeAddress(AddressesString, ContactAltAddress.Address,
                ContactAltAddress."Address 2", ContactAltAddress.City, ContactAltAddress.County,
                ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");
            PhonesString := GraphCollectionMgtContact.UpdateHomePhone(PhonesString, ContactAltAddress."Phone No.");
            PhonesString := GraphCollectionMgtContact.UpdateHomeFaxPhone(PhonesString, ContactAltAddress."Fax No.");
        end;

        if ContactAltAddress.Get(Contact."No.", GetContactAlternativeOtherAddressCode) then begin
            AddressesString := GraphCollectionMgtContact.UpdateOtherAddress(AddressesString, ContactAltAddress.Address,
                ContactAltAddress."Address 2", ContactAltAddress.City, ContactAltAddress.County,
                ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");
            PhonesString := GraphCollectionMgtContact.UpdateOtherPhone(PhonesString, ContactAltAddress."Phone No.");
            PhonesString := GraphCollectionMgtContact.UpdateOtherFaxPhone(PhonesString, ContactAltAddress."Fax No.");
        end;

        GRAPHContact.SetPostalAddressesString(AddressesString);
        GRAPHContact.SetPhonesString(PhonesString);
        GRAPHContact.SetWebsitesString(WebsitesString);

        DestinationRecordRef.GetTable(GRAPHContact);
    end;

    local procedure CreateContactAddressesFromGraph(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        SetContactAddressesFromGraph(SourceRecordRef, DestinationRecordRef);
    end;

    local procedure SetContactAddressesFromGraph(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        Contact: Record Contact;
        GRAPHContact: Record "Graph Contact";
        ContactAltAddress: Record "Contact Alt. Address";
        GraphCollectionMgtContact: Codeunit "Graph Collection Mgt - Contact";
        AddressesString: Text;
        PhonesString: Text;
        WebsitesString: Text;
    begin
        SourceRecordRef.SetTable(GRAPHContact);
        DestinationRecordRef.SetTable(Contact);

        AddressesString := GRAPHContact.GetPostalAddressesString;
        PhonesString := GRAPHContact.GetPhonesString;
        WebsitesString := GRAPHContact.GetWebsitesString;

        if GraphCollectionMgtContact.HasBusinessAddressOrPhone(AddressesString, PhonesString, WebsitesString) then begin
            GraphCollectionMgtContact.GetBusinessAddress(AddressesString, Contact.Address,
              Contact."Address 2", Contact.City, Contact.County, Contact."Country/Region Code", Contact."Post Code");
            GraphCollectionMgtContact.GetBusinessPhone(PhonesString, Contact."Phone No.");
            GraphCollectionMgtContact.GetBusinessFaxPhone(PhonesString, Contact."Fax No.");
            GraphCollectionMgtContact.GetMobilePhone(PhonesString, Contact."Mobile Phone No.");
            GraphCollectionMgtContact.GetPagerPhone(PhonesString, Contact.Pager);
            GraphCollectionMgtContact.GetWorkWebsite(WebsitesString, Contact."Home Page");
        end;

        if GraphCollectionMgtContact.HasHomeAddressOrPhone(AddressesString, PhonesString, WebsitesString) then begin
            if not ContactAltAddress.Get(Contact."No.", GetContactAlternativeHomeAddressCode) then begin
                ContactAltAddress.Init();
                ContactAltAddress.Validate("Contact No.", Contact."No.");
                ContactAltAddress.Validate(Code, GetContactAlternativeHomeAddressCode);
                ContactAltAddress.Insert(true);
            end;
            GraphCollectionMgtContact.GetHomeAddress(AddressesString, ContactAltAddress.Address,
              ContactAltAddress."Address 2", ContactAltAddress.City, ContactAltAddress.County,
              ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");
            GraphCollectionMgtContact.GetHomePhone(PhonesString, ContactAltAddress."Phone No.");
            GraphCollectionMgtContact.GetHomeFaxPhone(PhonesString, ContactAltAddress."Fax No.");
            GraphCollectionMgtContact.GetHomeWebsite(WebsitesString, ContactAltAddress."Home Page");
            ContactAltAddress.Modify(true);
        end;

        if GraphCollectionMgtContact.HasOtherAddressOrPhone(AddressesString, PhonesString, WebsitesString) then begin
            if not ContactAltAddress.Get(Contact."No.", GetContactAlternativeOtherAddressCode) then begin
                ContactAltAddress.Init();
                ContactAltAddress.Validate("Contact No.", Contact."No.");
                ContactAltAddress.Validate(Code, GetContactAlternativeOtherAddressCode);
                ContactAltAddress.Insert(true);
            end;
            GraphCollectionMgtContact.GetOtherAddress(AddressesString, ContactAltAddress.Address,
              ContactAltAddress."Address 2", ContactAltAddress.City, ContactAltAddress.County,
              ContactAltAddress."Country/Region Code", ContactAltAddress."Post Code");
            GraphCollectionMgtContact.GetOtherPhone(PhonesString, ContactAltAddress."Phone No.");
            GraphCollectionMgtContact.GetOtherFaxPhone(PhonesString, ContactAltAddress."Fax No.");
            ContactAltAddress.Modify(true);
        end;

        DestinationRecordRef.GetTable(Contact);
    end;
}

