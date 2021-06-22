codeunit 6703 "Exchange Contact Sync."
{

    trigger OnRun()
    var
        LocalExchangeSync: Record "Exchange Sync";
    begin
        LocalExchangeSync.SetRange(Enabled, true);
        if LocalExchangeSync.FindSet then
            repeat
                O365SyncManagement.SyncExchangeContacts(LocalExchangeSync, false);
            until LocalExchangeSync.Next = 0;
    end;

    var
        TempContact: Record Contact temporary;
        O365SyncManagement: Codeunit "O365 Sync. Management";
        O365ContactSyncHelper: Codeunit "O365 Contact Sync. Helper";
        SkipDateFilters: Boolean;
        ProcessExchangeContactsMsg: Label 'Processing contacts from Exchange.';
        ProcessNavContactsMsg: Label 'Processing contacts in your company.';
        ExchangeCountTelemetryTxt: Label 'Retrieved %1 Exchange contacts for synchronization.', Locked = true;

    procedure GetRequestParameters(var ExchangeSync: Record "Exchange Sync"): Text
    var
        LocalContact: Record Contact;
        FilterPage: FilterPageBuilder;
        FilterText: Text;
        ContactTxt: Text;
    begin
        FilterText := ExchangeSync.GetSavedFilter;

        ContactTxt := LocalContact.TableCaption;
        FilterPage.PageCaption := ContactTxt;
        FilterPage.AddTable(ContactTxt, DATABASE::Contact);

        if FilterText <> '' then
            FilterPage.SetView(ContactTxt, FilterText);

        FilterPage.ADdField(ContactTxt, LocalContact."Territory Code");
        FilterPage.ADdField(ContactTxt, LocalContact."Company No.");
        FilterPage.ADdField(ContactTxt, LocalContact."Salesperson Code");
        FilterPage.ADdField(ContactTxt, LocalContact.City);
        FilterPage.ADdField(ContactTxt, LocalContact.County);
        FilterPage.ADdField(ContactTxt, LocalContact."Post Code");
        FilterPage.ADdField(ContactTxt, LocalContact."Country/Region Code");

        if FilterPage.RunModal then
            FilterText := FilterPage.GetView(ContactTxt);

        if FilterText <> '' then begin
            ExchangeSync.SaveFilter(FilterText);
            ExchangeSync.Modify(true);
        end;

        exit(FilterText);
    end;

    procedure GetRequestParametersFullSync(var ExchangeSync: Record "Exchange Sync")
    begin
        SkipDateFilters := true;

        GetRequestParameters(ExchangeSync);
    end;

    procedure SyncRecords(var ExchangeSync: Record "Exchange Sync"; FullSync: Boolean)
    begin
        SkipDateFilters := FullSync;
        O365ContactSyncHelper.GetO365Contacts(ExchangeSync, TempContact);
        SendTraceTag('0000ACN', O365SyncManagement.TraceCategory(), Verbosity::Normal, StrSubstNo(ExchangeCountTelemetryTxt, TempContact.Count()), DataClassification::SystemMetadata);

        O365SyncManagement.ShowProgress(ProcessNavContactsMsg);
        ProcessNavContacts(ExchangeSync, TempContact, SkipDateFilters);

        O365SyncManagement.ShowProgress(ProcessExchangeContactsMsg);
        ProcessExchangeContacts(ExchangeSync, TempContact, SkipDateFilters);

        O365SyncManagement.CloseProgress;
        ExchangeSync."Last Sync Date Time" := CreateDateTime(Today, Time);
        ExchangeSync.Modify(true);
    end;

    local procedure ProcessExchangeContacts(var ExchangeSync: Record "Exchange Sync"; var TempContact: Record Contact temporary; SkipDateFilters: Boolean)
    begin
        TempContact.Reset();
        if not SkipDateFilters then
            TempContact.SetLastDateTimeFilter(ExchangeSync."Last Sync Date Time");

        ProcessExchangeContactRecordSet(TempContact, ExchangeSync);
    end;

    local procedure ProcessExchangeContactRecordSet(var LocalContact: Record Contact; var ExchangeSync: Record "Exchange Sync")
    var
        Contact: Record Contact;
        found: Boolean;
        ContactNo: Text;
    begin
        if LocalContact.FindSet then
            repeat
                found := false;
                ContactNo := '';
                Contact.Reset();
                Clear(Contact);
                Contact.SetRange("Search E-Mail", UpperCase(LocalContact."E-Mail"));
                if Contact.FindFirst then begin
                    found := true;
                    ContactNo := Contact."No.";
                end;

                if found then begin
                    if not Contact."Privacy Blocked" then begin
                        O365ContactSyncHelper.TransferExchangeContactToNavContact(LocalContact, Contact, ExchangeSync);
                        Contact."No." := CopyStr(ContactNo, 1, 20);
                        Contact.Modify(true);
                    end
                end else begin
                    Contact."No." := '';
                    Contact.Type := Contact.Type::Person;
                    Contact.Insert(true);
                    O365ContactSyncHelper.TransferExchangeContactToNavContact(LocalContact, Contact, ExchangeSync);
                end;
            until (LocalContact.Next = 0)
    end;

    local procedure ProcessNavContacts(var ExchangeSync: Record "Exchange Sync"; var TempContact: Record Contact temporary; SkipDateFilters: Boolean)
    var
        Contact: Record Contact;
    begin
        SetContactFilter(Contact, ExchangeSync);
        if not SkipDateFilters then
            Contact.SetLastDateTimeFilter(ExchangeSync."Last Sync Date Time");

        O365ContactSyncHelper.ProcessNavContactRecordSet(Contact, TempContact, ExchangeSync);
    end;

    local procedure SetContactFilter(var Contact: Record Contact; var ExchangeSync: Record "Exchange Sync")
    begin
        Contact.SetView(ExchangeSync.GetSavedFilter);
        Contact.SetRange(Type, Contact.Type::Person);
        Contact.SetFilter("E-Mail", '<>%1', '');
        Contact.SetRange("Privacy Blocked", false);
    end;
}

