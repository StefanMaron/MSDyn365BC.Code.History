page 10501 "Postcode Configuration Page"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Postcode provider configuration page';
    PageType = StandardDialog;
    SourceTable = "Postcode Service Config";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(Control1040001)
            {
                ShowCaption = false;
                group(Control1040002)
                {
                    InstructionalText = 'Select address postcode lookup provider.';
                    ShowCaption = false;
                    field(SelectedService; ServiceKeyText)
                    {
                        ApplicationArea = Basic, Suite, Invoicing;
                        Caption = 'Address Provider';
                        Editable = false;

                        trigger OnDrillDown()
                        var
                            TempNameValueBuffer: Record "Name/Value Buffer" temporary;
                        begin
                            if PAGE.RunModal(PAGE::"Postcode Service Lookup", TempNameValueBuffer) = ACTION::LookupOK then
                                ServiceKeyText := TempNameValueBuffer.Name;
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            TempNameValueBuffer: Record "Name/Value Buffer" temporary;
                        begin
                            if PAGE.RunModal(PAGE::"Postcode Service Lookup", TempNameValueBuffer) = ACTION::LookupOK then
                                ServiceKeyText := TempNameValueBuffer.Name;
                        end;

                        trigger OnValidate()
                        begin
                            if (ServiceKeyText <> '') and (not EncryptionEnabled) then
                                if Confirm(CryptographyManagement.GetEncryptionIsNotActivatedQst) then
                                    PAGE.RunModal(PAGE::"Data Encryption Management");
                        end;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        PostcodeServiceManager: Codeunit "Postcode Service Manager";
    begin
        if not FindFirst() then begin
            Init;
            Insert;
            ServiceKeyText := DisabledTok;
            SaveServiceKey(DisabledTok);
        end;
        // If we reopen the page and the service status was
        // changed to invalid for some reason, make sure that we
        // also show this on config page
        if not PostcodeServiceManager.IsConfigured then begin
            ServiceKeyText := DisabledTok;
            SaveServiceKey(DisabledTok);
        end;

        PrevValue := GetServiceKey;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::Cancel then begin
            SaveServiceKey(PrevValue);
            exit(true);
        end;
        if CloseAction = ACTION::OK then begin
            if not Get then
                Insert;
            SaveServiceKey(ServiceKeyText);
        end;

        Commit();
    end;

    var
        CryptographyManagement: Codeunit "Cryptography Management";
        PrevValue: Text;
        DisabledTok: Label 'Disabled';
        ServiceKeyText: Text;
}

