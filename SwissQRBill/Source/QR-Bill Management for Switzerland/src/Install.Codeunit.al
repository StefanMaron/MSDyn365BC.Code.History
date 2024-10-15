codeunit 11517 "Swiss QR-Bill Install"
{
    Subtype = Install;

    var
        AssistedSetupTxt: Label 'Set up QR-Bill';
        AssistedSetupDescriptionTxt: Label 'Set up QR-Bills and easily generate, send and import QR-Bills in Dynamics 365 Business Central';
        DefaultIBANLbl: Label 'DEFAULT IBAN';
        DefaultQRIBANLbl: Label 'DEFAULT QR-IBAN';

    trigger OnInstallAppPerCompany()
    begin
        OnCompanyInitialize();

        if InitializeDone() then
            exit;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitialize()
    var
        NewDefaultBillInfoFormatCode: Code[20];
        NewDefaultLayoutCode: Code[20];
    begin
        NewDefaultBillInfoFormatCode := InitQRBillingInfoFormat();
        NewDefaultLayoutCode := InitQRBillLayouts(NewDefaultBillInfoFormatCode);
        InitQRBillSetup(NewDefaultLayoutCode);
        AddAssistedSetup();
        ApplyEvaluationClassificationsForPrivacy();
    end;

    local procedure InitializeDone(): boolean
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(AppInfo.DataVersion() <> Version.Create('0.0.0.0'));
    end;

    local procedure InitQRBillSetup(NewDefaultLayoutCode: Code[20])
    var
        SwissQRBillSetup: Record "Swiss QR-Bill Setup";
    begin
        with SwissQRBillSetup do
            if IsEmpty() then begin
            "Address Type" := "Address Type"::Structured;
            "Umlaut Chars Encode Mode" := "Umlaut Chars Encode Mode"::Double;
            if NewDefaultLayoutCode <> '' then
                "Default Layout" := NewDefaultLayoutCode;
            InitDefaultJournalSetup();

                Insert();
        end;
    end;

    local procedure InitQRBillLayouts(NewDefaultBillInfoFormatCode: Code[20]): Code[20]
    var
        QRBillLayout: Record "Swiss QR-Bill Layout";
    begin
        with QRBillLayout do
            if IsEmpty() then begin
                InitQRBillLayout(DefaultIBANLbl, "IBAN Type"::IBAN, "Payment Reference Type"::"Creditor Reference (ISO 11649)", NewDefaultBillInfoFormatCode);
                InitQRBillLayout(DefaultQRIBANLbl, "IBAN Type"::"QR-IBAN", "Payment Reference Type"::"QR Reference", NewDefaultBillInfoFormatCode);
                exit(DefaultQRIBANLbl);
            end;
    end;

    local procedure InitQRBillLayout(LayoutCode: Code[20]; IBANType: Enum "Swiss QR-Bill IBAN Type"; PaymentReferenceType: Enum "Swiss QR-Bill Payment Reference Type";
                                                                             AddInfoFormat: Code[20])
    var
        QRBillLayout: Record "Swiss QR-Bill Layout";
    begin
        with QRBillLayout do begin
            Code := LayoutCode;
            "IBAN Type" := IBANType;
            "Payment Reference Type" := PaymentReferenceType;
            "Billing Information" := AddInfoFormat;
            Insert();
        end;
    end;

    local procedure InitQRBillingInfoFormat(): Code[20]
    var
        QRBillBillingInfo: Record "Swiss QR-Bill Billing Info";
    begin
        with QRBillBillingInfo do
            if IsEmpty() then begin
                InitDefault();
                Insert();
                exit(Code);
            end;
    end;

    local procedure AddAssistedSetup()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        Info: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        if not AssistedSetup.Exists(Page::"Swiss QR-Bill Setup Wizard") then
        AssistedSetup.Add(
            Info.Id(), Page::"Swiss QR-Bill Setup Wizard", CopyStr(AssistedSetupTxt, 1, 250),
            AssistedSetupGroup::FirstInvoice, '', VideoCategory::Uncategorized, '', AssistedSetupDescriptionTxt);
    end;

    local procedure ApplyEvaluationClassificationsForPrivacy()
    var
        IncomingDocument: Record "Incoming Document";
        CompanyInformation: Record "Company Information";
        PaymentMethod: Record "Payment Method";
        Company: Record Company;
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        Company.Get(CompanyName());
        if not Company."Evaluation Company" then
            exit;

        DataClassificationMgt.SetTableFieldsToNormal(Database::"Swiss QR-Bill Setup");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Swiss QR-Bill Buffer");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Swiss QR-Bill Billing Info");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Swiss QR-Bill Billing Detail");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Swiss QR-Bill Layout");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Swiss QR-Bill Setup");
        DataClassificationMgt.SetFieldToNormal(Database::"Company Information", CompanyInformation.FieldNo("Swiss QR-Bill IBAN"));
        DataClassificationMgt.SetFieldToNormal(Database::"Payment Method", PaymentMethod.FieldNo("Swiss QR-Bill Layout"));

        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Unstr. Message"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Bill Info"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Reference Type"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Reference No."));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Vendor Address 1"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Vendor Address 2"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Vendor City"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Vendor Post Code"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Vendor Country"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Debitor Name"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Debitor Address1"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Debitor Address2"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Debitor City"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Debitor PostCode"));
        DataClassificationMgt.SetFieldToNormal(Database::"Incoming Document", IncomingDocument.FieldNo("Swiss QR-Bill Debitor Country"));
    end;
}