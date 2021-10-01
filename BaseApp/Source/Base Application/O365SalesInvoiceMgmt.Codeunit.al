codeunit 2310 "O365 Sales Invoice Mgmt"
{

    trigger OnRun()
    begin
    end;

    var
        ProcessDraftInvoiceInstructionTxt: Label 'Do you want to keep the new invoice?';
        ProcessDraftEstimateInstructionTxt: Label 'Do you want to keep the new estimate?';
        AddDiscountTxt: Label 'Add discount';
        ChangeDiscountTxt: Label 'Change discount';
        AddAttachmentTxt: Label 'Add attachment';
        NoOfAttachmentsTxt: Label 'Attachments (%1)', Comment = '%1=an integer number, starting at 0';
        InvoiceDiscountChangedMsg: Label 'Changing the quantity has cleared the line discount.';
        AmountOutsideRangeMsg: Label 'We adjusted the discount to not exceed the line amount.';
        O365SalesAttachmentMgt: Codeunit "O365 Sales Attachment Mgt";
        ConfigValidateManagement: Codeunit "Config. Validate Management";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustomerCreatedMsg: Label 'We added %1 to your customer list.', Comment = '%1= Customer name';
        InvoiceDiscountLbl: Label 'Invoice Discount';
        UndoTxt: Label 'Undo';
        CustomerBlockedErr: Label 'This customer has been blocked and cannot be invoiced.';
        ItemCreatedMsg: Label 'We added %1 to your item list.', Comment = '%1= Item description';
        ItemNotExistErr: Label 'The item does not exist.';
        CountryDoesntExistErr: Label 'Please choose an existing country or region, or add a new one.';
        CustomerIsBlockedMsg: Label 'The customer %1 has been blocked for any further business.', Comment = '%1= Customer name';
        NotificationShownForBlockedCustomer: Boolean;
        InvoiceDiscountNotificationGuidTok: Label '75d7aad4-7009-4f7f-836c-d034596b944b', Locked = true;
        AmountOutOfBoundsNotificationGuidTok: Label '281dfa97-d2a2-4379-ab39-b70d92cc83f1', Locked = true;
        CustomerCreatedNotificationGuidTok: Label 'f42cd036-ffcd-4fb7-a50a-ba0b8746640e', Locked = true;
        CustomerBlockedNotificationGuidTok: Label '4f05b604-52b6-4940-a801-8ee0cbf28648', Locked = true;
        DraftInvoiceCategoryLbl: Label 'AL Draft Invoice', Locked = true;
        InlineItemCreatedTelemetryTxt: Label 'Inline item created.', Locked = true;

    procedure GetCustomerEmail(CustomerNo: Code[20]): Text[80]
    var
        Customer: Record Customer;
    begin
        if CustomerNo <> '' then
            if Customer.Get(CustomerNo) then
                exit(Customer."E-Mail");
        exit('');
    end;

    procedure ConfirmKeepOrDeleteDocument(var SalesHeader: Record "Sales Header"): Boolean
    var
        InstructionsWithDocumentTypeTxt: Text;
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Quote then
            InstructionsWithDocumentTypeTxt := ProcessDraftEstimateInstructionTxt
        else
            InstructionsWithDocumentTypeTxt := ProcessDraftInvoiceInstructionTxt;

        if Confirm(InstructionsWithDocumentTypeTxt, true) then
            exit(true);

        exit(SalesHeader.Delete(true)); // Delete all invoice lines and invoice header
    end;

    procedure IsCustomerCompanyContact(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if CustomerNo <> '' then
            if Customer.Get(CustomerNo) then
                exit(Customer."Contact Type" = Customer."Contact Type"::Company);
        exit(false);
    end;

    procedure FindCountryCodeFromInput(UserInput: Text): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        if UserInput = '' then
            exit('');

        if CountryRegion.Get(CopyStr(UpperCase(UserInput), 1, MaxStrLen(CountryRegion.Code))) then
            exit(CountryRegion.Code);

        CountryRegion.SetFilter(
          Name,
          '@*' + CopyStr(UserInput, 1, MaxStrLen(CountryRegion.Name)) + '*'
          );

        if CountryRegion.FindFirst then
            exit(CountryRegion.Code);

        Error(CountryDoesntExistErr);
    end;

    procedure UpdateAddress(var SalesHeader: Record "Sales Header"; var FullAddress: Text; var CountryRegionCode: Code[10])
    var
        TempStandardAddress: Record "Standard Address" temporary;
    begin
        TempStandardAddress.CopyFromSalesHeaderSellTo(SalesHeader);
        FullAddress := TempStandardAddress.ToString;
        CountryRegionCode := SalesHeader."Sell-to Country/Region Code";

        SalesHeader."Bill-to Address" := SalesHeader."Sell-to Address";
        SalesHeader."Bill-to Address 2" := SalesHeader."Sell-to Address 2";
        SalesHeader."Bill-to Post Code" := SalesHeader."Sell-to Post Code";
        SalesHeader."Bill-to City" := SalesHeader."Sell-to City";
        SalesHeader."Bill-to Country/Region Code" := SalesHeader."Sell-to Country/Region Code";
        SalesHeader."Bill-to County" := SalesHeader."Sell-to County";
    end;

    procedure UpdateSellToAddress(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        SalesHeader."Sell-to Address" := Customer.Address;
        SalesHeader."Sell-to Address 2" := Customer."Address 2";
        SalesHeader."Sell-to City" := Customer.City;
        SalesHeader."Sell-to Post Code" := Customer."Post Code";
        SalesHeader."Sell-to County" := Customer.County;
        SalesHeader."Sell-to Country/Region Code" := Customer."Country/Region Code";
    end;

    procedure CalcInvoiceDiscountAmount(var SalesHeader: Record "Sales Header"; var SubTotalAmount: Decimal; var DiscountTxt: Text; var InvoiceDiscountAmount: Decimal; var InvDiscAmountVisible: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.CalcSums("Inv. Discount Amount", "Line Amount");
        SubTotalAmount := SalesLine."Line Amount";
        InvoiceDiscountAmount := SalesLine."Inv. Discount Amount";
        if SalesHeader."Invoice Discount Value" <> 0 then
            DiscountTxt := ChangeDiscountTxt
        else
            DiscountTxt := AddDiscountTxt;

        InvDiscAmountVisible := SalesHeader."Invoice Discount Value" <> 0;
    end;

    procedure UpdateNoOfAttachmentsLabel(NoOfAttachments: Integer; var NoOfAttachmentsValueTxt: Text)
    begin
        if NoOfAttachments = 0 then
            NoOfAttachmentsValueTxt := AddAttachmentTxt
        else
            NoOfAttachmentsValueTxt := StrSubstNo(NoOfAttachmentsTxt, NoOfAttachments);
    end;

    procedure OnAfterGetSalesHeaderRecord(var SalesHeader: Record "Sales Header"; var CurrencyFormat: Text; var TaxAreaDescription: Text[50]; var NoOfAttachmentsValueTxt: Text; var WorkDescription: Text)
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        TaxArea: Record "Tax Area";
        CurrencySymbol: Text[10];
    begin
        SalesHeader.SetDefaultPaymentServices;

        UpdateNoOfAttachmentsLabel(O365SalesAttachmentMgt.GetNoOfAttachments(SalesHeader), NoOfAttachmentsValueTxt);
        WorkDescription := SalesHeader.GetWorkDescription;

        if SalesHeader."Currency Code" = '' then begin
            GLSetup.Get();
            CurrencySymbol := GLSetup.GetCurrencySymbol;
        end else begin
            if Currency.Get(SalesHeader."Currency Code") then;
            CurrencySymbol := Currency.GetCurrencySymbol;
        end;
        CurrencyFormat := StrSubstNo('%1<precision, 2:2><standard format, 0>', CurrencySymbol);

        TaxAreaDescription := '';
        if SalesHeader."Tax Area Code" <> '' then
            if TaxArea.Get(SalesHeader."Tax Area Code") then
                TaxAreaDescription := TaxArea.GetDescriptionInCurrentLanguage;
    end;

    procedure LookupCustomerName(var SalesHeader: Record "Sales Header"; Text: Text; var CustomerName: Text[100]; var CustomerEmail: Text[80]): Boolean
    var
        Customer: Record Customer;
        BCO365CustomerList: Page "BC O365 Customer List";
    begin
        if Text <> '' then begin
            Customer.SetRange(Name, Text);
            if Customer.FindFirst then;
            Customer.SetRange(Name);
        end;

        BCO365CustomerList.LookupMode(true);
        BCO365CustomerList.SetRecord(Customer);

        if BCO365CustomerList.RunModal = ACTION::LookupOK then begin
            BCO365CustomerList.GetRecord(Customer);
            SalesHeader.SetHideValidationDialog(true);
            CustomerName := Customer.Name;
            SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
            CustomerEmail := GetCustomerEmail(SalesHeader."Sell-to Customer No.");
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateCustomerFields(SalesHeader: Record "Sales Header"; var CustomerName: Text[100]; var CustomerEmail: Text[80]; var IsCompanyContact: Boolean)
    begin
        CustomerName := SalesHeader."Sell-to Customer Name";
        CustomerEmail := GetCustomerEmail(SalesHeader."Sell-to Customer No.");
        IsCompanyContact := IsCustomerCompanyContact(SalesHeader."Sell-to Customer No.");
    end;

    procedure ValidateCustomerName(var SalesHeader: Record "Sales Header"; var CustomerName: Text[100]; var CustomerEmail: Text[80])
    var
        Customer: Record Customer;
        Contact: Record Contact;
    begin
        if SalesHeader."Sell-to Customer Name" = '' then
            exit;

        // Lookup by contact number
        if StrLen(SalesHeader."Sell-to Customer Name") <= MaxStrLen(Contact."No.") then
            if Contact.Get(CopyStr(SalesHeader."Sell-to Customer Name", 1, MaxStrLen(Contact."No."))) then
                if not FindCustomerByContactNo(Contact."No.", Customer) then
                    Customer.Get(CreateCustomerFromContact(Contact));

        // Lookup by customer number/name
        if Customer."No." = '' then
            if not Customer.Get(Customer.GetCustNoOpenCard(SalesHeader."Sell-to Customer Name", false, false)) then
                // Lookup by contact name
                if Contact.Get(Contact.GetContNo(SalesHeader."Sell-to Customer Name")) then begin
                    if FindCustomerByContactNo(Contact."No.", Customer) then begin
                        if Customer.IsBlocked then
                            Error(CustomerBlockedErr);
                    end else
                        Customer.Get(CreateCustomerFromContact(Contact));
                end;

        // A customer is found, but it is blocked: silently undo the lookup.
        // (e.g. a new customer is created from lookup and immediately deleted from customer card)
        if (Customer."No." <> '') and Customer.IsBlocked then
            Error('');

        // When no customer or contact is found, create a new and notify the user
        CreateCustomer(SalesHeader, Customer, CustomerName, CustomerEmail);
    end;

    [Scope('OnPrem')]
    procedure CreateCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer; var CustomerName: Text[100]; var CustomerEmail: Text[80])
    begin
        if SalesHeader."Sell-to Customer Name" = '' then
            exit;

        // When no customer or contact is found, create a new and notify the user
        if Customer."No." = '' then begin
            if SalesHeader."No." = '' then
                SalesHeader.Insert(true);
            Customer.Get(Customer.CreateNewCustomer(CopyStr(SalesHeader."Sell-to Customer Name", 1, MaxStrLen(Customer.Name)), false));
            SendCustomerCreatedNotification(Customer, SalesHeader);
        end;

        EnforceCustomerTemplateIntegrity(Customer);

        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        CustomerName := Customer.Name;
        CustomerEmail := GetCustomerEmail(SalesHeader."Sell-to Customer No.");
    end;

    procedure ValidateCustomerEmail(var SalesHeader: Record "Sales Header"; CustomerEmail: Text[80])
    var
        Customer: Record Customer;
        MailManagement: Codeunit "Mail Management";
    begin
        MailManagement.ValidateEmailAddressField(CustomerEmail);

        if CustomerEmail <> '' then begin
            Customer.LockTable();
            if (SalesHeader."Sell-to Customer No." <> '') and Customer.WritePermission then
                if Customer.Get(SalesHeader."Sell-to Customer No.") then
                    if CustomerEmail <> Customer."E-Mail" then begin
                        Customer.SetForceUpdateContact(true);
                        Customer."E-Mail" := CustomerEmail;
                        Customer.Modify(true);
                    end;
        end;
    end;

    procedure ValidateCustomerAddress(Address: Text[100]; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        if (Address <> '') and (CustomerNo <> '') then begin
            Customer.LockTable();
            if Customer.WritePermission and Customer.Get(CustomerNo) then
                if Customer.Address = '' then begin
                    Customer.SetForceUpdateContact(true);
                    Customer.Address := Address;
                    Customer.Modify(true);
                end;
        end;
    end;

    procedure ValidateCustomerAddress2(Address2: Text[50]; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        if (Address2 <> '') and (CustomerNo <> '') then begin
            Customer.LockTable();
            if Customer.WritePermission and Customer.Get(CustomerNo) then
                if Customer."Address 2" = '' then begin
                    Customer.SetForceUpdateContact(true);
                    Customer."Address 2" := Address2;
                    Customer.Modify(true);
                end;
        end;
    end;

    procedure ValidateCustomerCity(City: Text[30]; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        if (City <> '') and (CustomerNo <> '') then begin
            Customer.LockTable();
            if Customer.WritePermission and Customer.Get(CustomerNo) then
                if Customer.City = '' then begin
                    Customer.SetForceUpdateContact(true);
                    Customer.City := City;
                    Customer.Modify(true);
                end;
        end;
    end;

    procedure ValidateCustomerPostCode(PostCode: Code[20]; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        if (PostCode <> '') and (CustomerNo <> '') then begin
            Customer.LockTable();
            if Customer.WritePermission and Customer.Get(CustomerNo) then
                if Customer."Post Code" = '' then begin
                    Customer.SetForceUpdateContact(true);
                    Customer."Post Code" := PostCode;
                    Customer.Modify(true);
                end;
        end;
    end;

    procedure ValidateCustomerCounty(County: Text[30]; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        if (County <> '') and (CustomerNo <> '') then begin
            Customer.LockTable();
            if Customer.WritePermission and Customer.Get(CustomerNo) then
                if Customer.County = '' then begin
                    Customer.SetForceUpdateContact(true);
                    Customer.County := County;
                    Customer.Modify(true);
                end;
        end;
    end;

    procedure ValidateCustomerCountryRegion(CountryCode: Code[10]; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        if (CountryCode <> '') and (CustomerNo <> '') then begin
            Customer.LockTable();
            if Customer.WritePermission and Customer.Get(CustomerNo) then
                if Customer."Country/Region Code" = '' then begin
                    Customer.SetForceUpdateContact(true);
                    Customer."Country/Region Code" := CountryCode;
                    Customer.Modify(true);
                end;
        end;
    end;

    procedure EditCustomerCardFromSalesHeader(var SalesHeader: Record "Sales Header"; var FullAddress: Text; var CountryRegionCode: Code[10])
    var
        BeforeCustomer: Record Customer;
        AfterCustomer: Record Customer;
    begin
        if SalesHeader."Sell-to Customer No." = '' then
            exit;
        if not BeforeCustomer.Get(SalesHeader."Sell-to Customer No.") then
            exit;

        PAGE.RunModal(PAGE::"BC O365 Sales Customer Card", BeforeCustomer);

        if not AfterCustomer.Get(SalesHeader."Sell-to Customer No.") then
            exit;
        if not BeforeCustomer.HasDifferentAddress(AfterCustomer) then
            exit;

        if SalesHeaderHasAddress(SalesHeader) then
            exit;

        UpdateSellToAddress(SalesHeader, AfterCustomer);
        UpdateAddress(SalesHeader, FullAddress, CountryRegionCode);
    end;

    local procedure SalesHeaderHasAddress(SalesHeader: Record "Sales Header"): Boolean
    begin
        case true of
            SalesHeader."Sell-to Address" <> '':
                exit(true);
            SalesHeader."Sell-to Address 2" <> '':
                exit(true);
            SalesHeader."Sell-to City" <> '':
                exit(true);
            SalesHeader."Sell-to County" <> '':
                exit(true);
            SalesHeader."Sell-to Post Code" <> '':
                exit(true);
        end;

        exit(false);
    end;

    procedure OnQueryCloseForSalesHeader(var SalesHeader: Record "Sales Header"; ForceExit: Boolean; CustomerName: Text[100]): Boolean
    begin
        if ForceExit then
            exit(true);

        if SalesHeader."No." = '' then
            exit(true);

        if CustomerName = '' then begin
            SalesHeader.Delete(true);
            exit(true);
        end;

        if SalesHeader.SalesLinesExist then
            exit(true);

        if GuiAllowed then
            exit(ConfirmKeepOrDeleteDocument(SalesHeader));
    end;

    procedure ShowInvoiceDiscountNotification(var InvoiceDiscountNotification: Notification; DocumentRecordId: RecordID)
    begin
        InvoiceDiscountNotification.Id := InvoiceDiscountNotificationGuidTok;
        InvoiceDiscountNotification.Message := InvoiceDiscountChangedMsg;
        InvoiceDiscountNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        NotificationLifecycleMgt.SendNotification(InvoiceDiscountNotification, DocumentRecordId);
    end;

    procedure LookupDescription(var SalesLine: Record "Sales Line"; Text: Text; var DescriptionSelected: Boolean): Boolean
    var
        Item: Record Item;
        BCO365ItemList: Page "BC O365 Item List";
    begin
        if Text <> '' then begin
            Item.SetRange(Description, Text);
            if Item.FindFirst then;
            Item.SetRange(Description);
        end;

        BCO365ItemList.LookupMode(true);
        BCO365ItemList.SetRecord(Item);

        if BCO365ItemList.RunModal = ACTION::LookupOK then begin
            BCO365ItemList.GetRecord(Item);
            SalesLine.SetHideValidationDialog(true);
            SalesLine.Validate("No.", Item."No.");
            DescriptionSelected := SalesLine.Description <> '';
            exit(true);
        end;

        exit(false);
    end;

    procedure ConstructCurrencyFormatString(var SalesLine: Record "Sales Line"; var CurrencyFormat: Text)
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        CurrencySymbol: Text[10];
    begin
        if SalesLine."Currency Code" = '' then begin
            GLSetup.Get();
            CurrencySymbol := GLSetup.GetCurrencySymbol;
        end else begin
            if Currency.Get(SalesLine."Currency Code") then;
            CurrencySymbol := Currency.GetCurrencySymbol;
        end;
        CurrencyFormat := StrSubstNo('%1<precision, 2:2><standard format, 0>', CurrencySymbol);
    end;

    procedure GetValueWithinBounds(Value: Decimal; MinValue: Decimal; MaxValue: Decimal; var AmountOutsideOfBoundsNotificationSend: Boolean; DocumentRecordId: RecordID): Decimal
    begin
        if Value < MinValue then begin
            SendOutsideRangeNotification(AmountOutsideOfBoundsNotificationSend, DocumentRecordId);
            exit(MinValue);
        end;
        if Value > MaxValue then begin
            SendOutsideRangeNotification(AmountOutsideOfBoundsNotificationSend, DocumentRecordId);
            exit(MaxValue);
        end;
        exit(Value);
    end;

    procedure OpenNewPaymentInstructionsCard() IsDefault: Boolean
    var
        BCO365PaymentInstrCard: Page "BC O365 Payment Instr. Card";
    begin
        BCO365PaymentInstrCard.LookupMode := true;
        if BCO365PaymentInstrCard.RunModal = ACTION::LookupOK then
            IsDefault := BCO365PaymentInstrCard.GetIsDefault
        else
            IsDefault := false;
    end;

    procedure GetPaymentInstructionsName(PaymentInstructionsId: Integer; var Name: Text[20])
    var
        O365PaymentInstructions: Record "O365 Payment Instructions";
    begin
        Name := '';
        if O365PaymentInstructions.Get(PaymentInstructionsId) then
            Name := O365PaymentInstructions.GetNameInCurrentLanguage;
    end;

    procedure GetDefaultPaymentInstructionsId(): Integer
    var
        O365PaymentInstructions: Record "O365 Payment Instructions";
    begin
        O365PaymentInstructions.SetRange(Default, true);
        if O365PaymentInstructions.FindFirst then
            exit(O365PaymentInstructions.Id);

        exit(0);
    end;

#if not CLEAN19
    [Scope('OnPrem')]
    procedure GetPaymentInstructionsFromPostedInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        if not SalesInvoiceHeader."Payment Instructions".HasValue then
            exit('');

        SalesInvoiceHeader."Payment Instructions".CreateInStream(InStream, TEXTENCODING::Windows);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator));
    end;
#endif

    procedure SendOutsideRangeNotification(var AmountOutsideOfBoundsNotificationSend: Boolean; DocumentRecordId: RecordID)
    var
        AmountOutOfBoundsNotification: Notification;
    begin
        if AmountOutsideOfBoundsNotificationSend then
            exit;

        AmountOutOfBoundsNotification.Id := AmountOutOfBoundsNotificationGuidTok;
        AmountOutOfBoundsNotification.Message := AmountOutsideRangeMsg;
        AmountOutOfBoundsNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        NotificationLifecycleMgt.SendNotification(AmountOutOfBoundsNotification, DocumentRecordId);
        AmountOutsideOfBoundsNotificationSend := true;
    end;

    procedure LookupContactFromSalesHeader(var SalesHeader: Record "Sales Header"): Boolean
    var
        Customer: Record Customer;
        Contact: Record Contact;
        BCO365ContactLookup: Page "BC O365 Contact Lookup";
    begin
        if SalesHeader."Sell-to Contact No." <> '' then begin
            Contact.Get(SalesHeader."Sell-to Contact No.");
            BCO365ContactLookup.SetRecord(Contact);
        end;

        BCO365ContactLookup.LookupMode(true);
        if BCO365ContactLookup.RunModal = ACTION::LookupOK then begin
            BCO365ContactLookup.GetRecord(Contact);
            if SalesHeader."Sell-to Contact No." <> Contact."No." then begin
                if not FindCustomerByContactNo(Contact."No.", Customer) then
                    Customer.Get(CreateCustomerFromContact(Contact));
                EnforceCustomerTemplateIntegrity(Customer);
                SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
            end;
            exit(true);
        end;
        exit(false);
    end;

    local procedure FindCustomerByContactNo(ContactNo: Code[20]; var Customer: Record Customer): Boolean
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        if not ContBusRel.FindByContact(ContBusRel."Link to Table"::Customer, ContactNo) then
            exit(false);

        Customer.Get(ContBusRel."No.");
        exit(true);
    end;

    local procedure CreateCustomerFromContact(Contact: Record Contact): Code[20]
    var
        MarketingSetup: Record "Marketing Setup";
        Customer: Record Customer;
    begin
        MarketingSetup.Get();
        Contact.SetHideValidationDialog(true);
        case Contact.Type of
            Contact.Type::Company:
                begin
                    MarketingSetup.TestField("Cust. Template Company Code");
#if not CLEAN18
                    Contact.CreateCustomer(MarketingSetup."Cust. Template Company Code");
#else
                    Contact.CreateCustomerFromTemplate(MarketingSetup."Cust. Template Company Code");
#endif
                end;
            Contact.Type::Person:
                begin
                    MarketingSetup.TestField("Cust. Template Person Code");
#if not CLEAN18
                    Contact.CreateCustomer(MarketingSetup."Cust. Template Person Code");
#else
                    Contact.CreateCustomerFromTemplate(MarketingSetup."Cust. Template Person Code");
#endif
                end;
        end;

        FindCustomerByContactNo(Contact."No.", Customer);
        exit(Customer."No.");
    end;

    local procedure SendCustomerCreatedNotification(Customer: Record Customer; SalesHeader: Record "Sales Header")
    var
        CustomerCreatedNotification: Notification;
        Type: Integer;
    begin
        CustomerCreatedNotification.Id := CustomerCreatedNotificationGuidTok;
        CustomerCreatedNotification.Message(StrSubstNo(CustomerCreatedMsg, Customer.Name));
        CustomerCreatedNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        CustomerCreatedNotification.AddAction(UndoTxt, CODEUNIT::"O365 Sales Invoice Mgmt", 'UndoCustomerCreation');
        CustomerCreatedNotification.SetData('CustomerNo', Customer."No.");
        CustomerCreatedNotification.SetData('SalesHeaderNo', SalesHeader."No.");

        Type := SalesHeader."Document Type".AsInteger();
        CustomerCreatedNotification.SetData('SalesHeaderType', Format(Type));
        NotificationLifecycleMgt.SendNotification(CustomerCreatedNotification, SalesHeader.RecordId);
    end;

    procedure SendCustomerHasBeenBlockedNotification(CustomerName: Text[100])
    var
        DummyCustomer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustomerBlockedNotification: Notification;
    begin
        if not NotificationShownForBlockedCustomer then begin
            CustomerBlockedNotification.Id := CustomerBlockedNotificationGuidTok;
            CustomerBlockedNotification.Message(StrSubstNo(CustomerIsBlockedMsg, CustomerName));
            CustomerBlockedNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
            NotificationLifecycleMgt.SendNotification(CustomerBlockedNotification, DummyCustomer.RecordId);
            NotificationShownForBlockedCustomer := true;
        end;
    end;

    local procedure SendItemCreatedNotification(Item: Record Item; SalesLine: Record "Sales Line")
    var
        ItemCreatedNotification: Notification;
    begin
        Session.LogMessage('000023X', InlineItemCreatedTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DraftInvoiceCategoryLbl);
        ItemCreatedNotification.Id := CreateGuid;
        ItemCreatedNotification.Message(StrSubstNo(ItemCreatedMsg, Item.Description));
        ItemCreatedNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        ItemCreatedNotification.AddAction(UndoTxt, CODEUNIT::"O365 Sales Invoice Mgmt", 'UndoItemCreation');
        ItemCreatedNotification.SetData('ItemNo', Item."No.");
        NotificationLifecycleMgt.SendNotification(ItemCreatedNotification, SalesLine.RecordId);
    end;

    procedure UndoItemCreation(var CreateItemNotification: Notification)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        SalesLine.SetRange("No.", CreateItemNotification.GetData('ItemNo'));
        if SalesLine.FindSet then
            repeat
                SalesLine.Delete(true);
            until SalesLine.Next() = 0;

        if Item.Get(CreateItemNotification.GetData('ItemNo')) then
            Item.Delete(true);
    end;

    procedure UndoCustomerCreation(var CreateCustomerNotification: Notification)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustContUpdate: Codeunit "CustCont-Update";
        DocumentType: Option;
    begin
        Evaluate(DocumentType, CreateCustomerNotification.GetData('SalesHeaderType'));

        if SalesHeader.Get(DocumentType, CreateCustomerNotification.GetData('SalesHeaderNo')) then begin
            SalesHeader.Init();
            SalesHeader.Modify();
        end;

        if Customer.Get(CreateCustomerNotification.GetData('CustomerNo')) then begin
            CustContUpdate.DeleteCustomerContacts(Customer);
            Customer.Delete(true);
        end;
    end;

    procedure GetInvoiceDiscountCaption(InvoiceDiscountValue: Decimal): Text
    begin
        if InvoiceDiscountValue = 0 then
            exit(InvoiceDiscountLbl);
        exit(StrSubstNo('%1 (%2%)', InvoiceDiscountLbl, Round(InvoiceDiscountValue, 0.1)));
    end;

    procedure EnforceCustomerTemplateIntegrity(var Customer: Record Customer)
    var
        ConfigTemplateLine: Record "Config. Template Line";
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
        EnvInfoProxy: Codeunit "Env. Info Proxy";
        CustomerRecRef: RecordRef;
        CustomerFieldRef: FieldRef;
        CustomerFixed: Boolean;
        OriginalLanguageID: Integer;
    begin
        if not EnvInfoProxy.IsInvoicing then
            exit;

        if not O365SalesInitialSetup.Get then
            exit;

        ConfigTemplateLine.SetRange("Data Template Code", O365SalesInitialSetup."Default Customer Template");
        ConfigTemplateLine.SetRange("Table ID", DATABASE::Customer);
        // 88 = Gen. Bus. Posting Group
        // 21 = Customer Posting Group
        // 80 = Application Method
        // 104 = Reminder Terms Code
        // 28 = Fin. Charge Terms Code
        ConfigTemplateLine.SetFilter("Field ID", '88|21|80|104|28');
        if not ConfigTemplateLine.FindSet then
            exit;

        OriginalLanguageID := GlobalLanguage;
        CustomerRecRef.GetTable(Customer);
        repeat
            if CustomerRecRef.FieldExist(ConfigTemplateLine."Field ID") then begin
                if ConfigTemplateLine."Language ID" <> 0 then
                    GlobalLanguage := ConfigTemplateLine."Language ID"; // When formatting the value, make sure we are using the correct language
                CustomerFieldRef := CustomerRecRef.Field(ConfigTemplateLine."Field ID");
                if Format(CustomerFieldRef.Value) <> ConfigTemplateLine."Default Value" then begin
                    CustomerFieldRef.Validate(ConfigTemplateLine."Default Value");
                    ConfigValidateManagement.ValidateFieldValue(
                      CustomerRecRef, CustomerFieldRef, ConfigTemplateLine."Default Value", false, ConfigTemplateLine."Language ID");
                    CustomerFixed := true;
                end;
                GlobalLanguage := OriginalLanguageID;
            end;
        until ConfigTemplateLine.Next() = 0;

        if CustomerFixed then
            if CustomerRecRef.Modify(true) then
                Customer.Get(Customer."No.");
    end;

    procedure ValidateItemDescription(var SalesLine: Record "Sales Line"; var DescriptionSelected: Boolean)
    var
        Item: Record Item;
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        O365SalesManagement: Codeunit "O365 Sales Management";
        ReturnValue: Text[100];
        Found: Boolean;
    begin
        if SalesLine.Description = '' then
            exit;

        // Lookup by item number/description
        if not Item.TryGetItemNoOpenCard(ReturnValue, SalesLine.Description, false, false, false) then begin
            if ItemTemplMgt.InsertItemFromTemplate(Item) then begin
                Item.Validate(Description, SalesLine.Description);
                O365SalesManagement.SetItemDefaultValues(Item);
                SendItemCreatedNotification(Item, SalesLine);
            end else
                Error(ItemNotExistErr);
        end else begin
            Found := false;
            if StrLen(ReturnValue) <= MaxStrLen(Item."No.") then
                Found := Item.Get(ReturnValue);
            if not Found then begin
                Item.SetRange(Description, ReturnValue);
                if Item.FindFirst then;
            end;
        end;
        if (Item."No." <> '') and (Item."No." <> SalesLine."No.") then
            SalesLine.Validate("No.", Item."No.");
        DescriptionSelected := SalesLine.Description <> '';
    end;

    procedure ValidateItemUnitOfMeasure(var SalesLine: Record "Sales Line")
    var
        TempUOM: Record "Unit of Measure" temporary;
        Item: Record Item;
        OriginalLineDiscount: Decimal;
        OriginalUnitPrice: Decimal;
    begin
        TempUOM.CreateListInCurrentLanguage(TempUOM);
        if not TryFindUnitOfMeasure(TempUOM, SalesLine."Unit of Measure") then begin
            TempUOM.Code := CreateUnitOfMeasure(
                CopyStr(SalesLine."Unit of Measure", 1, MaxStrLen(SalesLine."Unit of Measure Code")),
                SalesLine."Unit of Measure");

            if TempUOM.Code = '' then
                Error('');
        end;

        if Item.WritePermission then
            if Item.Get(SalesLine."No.") then
                if Item."Base Unit of Measure" <> TempUOM.Code then begin
                    Item.Validate("Base Unit of Measure", TempUOM.Code);
                    Item.Modify
                end;

        OriginalUnitPrice := SalesLine."Unit Price"; // Changing uom resets the unit price and line discount.
        OriginalLineDiscount := SalesLine."Line Discount %";
        SalesLine.Validate("Unit of Measure Code", TempUOM.Code);
        if SalesLine."Unit Price" <> OriginalUnitPrice then
            SalesLine.Validate("Unit Price", OriginalUnitPrice);
        if OriginalLineDiscount <> 0 then
            SalesLine.Validate("Line Discount %", OriginalLineDiscount);
    end;

    procedure CreateUnitOfMeasure(CodeToSet: Code[10]; DescriptionToSet: Text[50]): Code[10]
    var
        UOM: Record "Unit of Measure";
    begin
        if UOM.Get(CodeToSet) then
            exit(UOM.Code);

        UOM.Init();
        UOM.Validate(Code, CodeToSet);
        UOM.Validate(Description, DescriptionToSet);
        UOM.Insert(true);

        exit(UOM.Code);
    end;

    [TryFunction]
    procedure TryFindUnitOfMeasure(var TempUOM: Record "Unit of Measure" temporary; Description: Text[50])
    begin
        TempUOM.SetFilter(Description, '@' + Description);
        TempUOM.FindFirst;
    end;

    procedure ValidateItemPrice(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        GLSetup: Record "General Ledger Setup";
        PriceExclVAT: Decimal;
    begin
        if SalesLine."No." = '' then
            exit;

        if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            exit;

        if not GLSetup.Get then
            exit;

        if Item.WritePermission then
            if Item.Get(SalesLine."No.") then begin
                if SalesHeader."Prices Including VAT" and not Item."Price Includes VAT" then begin
                    PriceExclVAT := Round(SalesLine."Unit Price" / (1 + (SalesLine."VAT %" / 100)), GLSetup."Unit-Amount Rounding Precision");
                    Item.Validate("Unit Price", PriceExclVAT);
                    Item.Modify();
                    exit;
                end;
                Item.Validate("Unit Price", SalesLine."Unit Price");
                Item.Modify();
            end;
    end;

    procedure ValidateVATRate(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
    begin
        if SalesLine."No." = '' then
            exit;

        if Item.WritePermission then
            if Item.Get(SalesLine."No.") then begin
                Item.Validate("VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
                Item.Modify();
            end;
    end;

    procedure IsCustomerBlocked(CustomerNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if Customer.Get(CustomerNo) then
            exit(Customer.IsBlocked);
        exit(false);
    end;

    procedure GetCustomerStatus(Customer: Record Customer; var BlockedStatus: Text)
    begin
        if Customer.IsBlocked then
            BlockedStatus := Customer.FieldCaption(Blocked)
        else
            BlockedStatus := '';
    end;

    procedure IsBusinessCenterExperience(): Boolean
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        exit(ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Tablet);
    end;
}

