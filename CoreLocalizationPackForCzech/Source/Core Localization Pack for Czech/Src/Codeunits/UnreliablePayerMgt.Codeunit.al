codeunit 11758 "Unreliable Payer Mgt. CZL"
{
    var
        UnrelPayerServiceSetupCZL: Record "Unrel. Payer Service Setup CZL";
        CompanyInformation: Record "Company Information";
        UnreliablePayerMgtCZL: Codeunit "Unreliable Payer Mgt. CZL";
        UnreliablePayerWSCZL: Codeunit "Unreliable Payer WS CZL";
        VATRegNoList: List of [Code[20]];
        UnreliablePayerServiceSetupRead: Boolean;
        BankAccCodeNotExistQst: Label 'There is no bank account code in the document.\\Do you want to continue?';
        BankAccIsForeignQst: Label 'The bank account %1 of vendor %2 is foreign.\\Do you want to continue?', Comment = '%1=Bank Account No.;%2=Vendor No.';
        BankAccNotPublicQst: Label 'The bank account %1 of vendor %2 is not public.\\Do you want to continue?', Comment = '%1=Bank Account No.;%2=Vendor No.';
        CZCountryCodeTok: Label 'CZ', Locked = true;
        ImportSuccessfulMsg: Label 'Import was successful. %1 new entries have been inserted.', Comment = '%1=Processed Entries Count';
        VendUnrVATPayerStatusNotCheckedQst: Label 'The unreliability VAT payer status has not been checked for vendor %1 (%2).\\Do you want to continue?', Comment = '%1=Vendor No.;%2=VAT Registration No.';
        VendUnrVATPayerQst: Label 'The vendor %1 (%2) is unreliable VAT payer.\\Do you want to continue?', Comment = '%1=Vendor No.;%2=VAT Registration No.';
        UnreliablePayerServiceURLTok: Label 'http://adisrws.mfcr.cz/adistc/axis2/services/rozhraniCRPDPH.rozhraniCRPDPHSOAP', Locked = true;

    procedure GetUnreliablePayerServiceURL(): Text[250]
    begin
        exit(UnreliablePayerServiceURLTok);
    end;

    procedure ImportUnrPayerStatus(ShowMessage: Boolean): Boolean
    var
        TempBlobResponse: Codeunit "Temp Blob";
        InsertEntryCount: Integer;
        VATRegNoCount: Integer;
        MaxVATRegNoCount: Integer;
        CurrVATRegNoCount: Integer;
    begin
        GetUnreliablePayerServiceSetup();
        VATRegNoCount := GetVATRegNoCount();
        if VATRegNoCount = 0 then
            exit(false);

        MaxVATRegNoCount := GetMaxVATRegNoCount();
        repeat
            CurrVATRegNoCount := MaxVATRegNoCount;
            if VATRegNoCount <= MaxVATRegNoCount then
                CurrVATRegNoCount := VATRegNoCount;
            if not GetUnrPayerStatus(VATRegNoList, TempBlobResponse) then
                exit(false);

            InsertEntryCount += ImportUnrPayerStatusResponse(TempBlobResponse);
            VATRegNoCount -= CurrVATRegNoCount;
        until VATRegNoCount = 0;

        if ShowMessage then
            Message(ImportSuccessfulMsg, InsertEntryCount);
        exit(true);
    end;

    procedure ImportUnrPayerStatusForVendor(Vendor: Record Vendor): Boolean
    var
        VatRegNoEmptyMsg: Label 'Check is not possible.\%1 must not be empty and must match %2 in %3.', Comment = '%1 = VAT Registration No. FieldCaption, %2 =  Country/Region CodeFieldCaption, %3 = CompanyInfromation TabeCaption';
    begin
        GetUnreliablePayerServiceSetup();
        if not Vendor.IsUnreliablePayerCheckPossibleCZL() then begin
            Message(VatRegNoEmptyMsg, Vendor.FieldCaption("VAT Registration No."), CompanyInformation.FieldCaption("Country/Region Code"), CompanyInformation.TableCaption());
            exit(false);
        end;

        Clear(VATRegNoList);
        if AddVATRegNoToList(Vendor."VAT Registration No.") then
            exit(ImportUnrPayerStatus(true));
    end;

    procedure ImportUnrPayerList(ShowMessage: Boolean): Boolean
    var
        TempBlobResponse: Codeunit "Temp Blob";
        InsertEntryCount: Integer;
    begin
        GetUnreliablePayerServiceSetup();
        if not GetUnrPayerList(TempBlobResponse) then
            exit(false);

        InsertEntryCount := ImportUnrPayerListResponse(TempBlobResponse);
        if ShowMessage then
            Message(ImportSuccessfulMsg, InsertEntryCount);
        exit(true);
    end;

    local procedure GetUnrPayerStatus(VATRegNoList: List of [Code[20]]; var TempBlobResponse: Codeunit "Temp Blob"): Boolean
    begin
        exit(UnreliablePayerWSCZL.GetStatus(VATRegNoList, TempBlobResponse));
    end;

    local procedure GetUnrPayerList(var TempBlobResponse: Codeunit "Temp Blob"): Boolean
    begin
        exit(UnreliablePayerWSCZL.GetList(TempBlobResponse));
    end;

    local procedure ImportUnrPayerStatusResponse(var TempBlobResponse: Codeunit "Temp Blob"): Integer
    var
        UnreliablePayerStatusCZL: XMLport "Unreliable Payer Status CZL";
        ResponseInStream: InStream;
    begin
        TempBlobResponse.CreateInStream(ResponseInStream);
        UnreliablePayerStatusCZL.SetSource(ResponseInStream);
        UnreliablePayerStatusCZL.Import();
        exit(UnreliablePayerStatusCZL.GetInsertEntryCount());
    end;

    local procedure ImportUnrPayerListResponse(var TempBlobResponse: Codeunit "Temp Blob"): Integer
    var
        UnreliablePayerListCZL: XMLport "Unreliable Payer List CZL";
        ResponseInStream: InStream;
    begin
        TempBlobResponse.CreateInStream(ResponseInStream);
        UnreliablePayerListCZL.SetSource(ResponseInStream);
        UnreliablePayerListCZL.Import();
        exit(UnreliablePayerListCZL.GetInsertEntryCount());
    end;

    local procedure GetMaxVATRegNoCount(): Integer
    begin
        GetUnreliablePayerServiceSetup();
        if UnrelPayerServiceSetupCZL."Unr.Payer Request Record Limit" <> 0 then
            exit(UnrelPayerServiceSetupCZL."Unr.Payer Request Record Limit");
        exit(UnreliablePayerWSCZL.GetInputRecordLimit());
    end;

    local procedure GetUnreliablePayerServiceSetup()
    begin
        if UnreliablePayerServiceSetupRead then
            exit;
        if not UnrelPayerServiceSetupCZL.Get() then begin
            UnrelPayerServiceSetupCZL.Init();
            UnrelPayerServiceSetupCZL."Unreliable Payer Web Service" := UnreliablePayerMgtCZL.GetUnreliablePayerServiceURL();
            UnrelPayerServiceSetupCZL.Enabled := false;
            UnrelPayerServiceSetupCZL.Insert();
        end;
        CompanyInformation.Get();
        UnreliablePayerServiceSetupRead := true;
    end;

    procedure AddVATRegNoToList(VATRegNo: Code[20]): Boolean
    begin
        if VATRegNo = '' then
            exit(false);
        if VATRegNoList.Contains(VATRegNo) then
            exit(false);
        VATRegNoList.Add(VATRegNo);
        exit(true);
    end;

    procedure GetVATRegNoCount(): Integer
    begin
        exit(VATRegNoList.Count);
    end;

    procedure IsVATRegNoExportPossible(VATRegNo: Code[20]; CountryCode: Code[10]) ReturnValue: Boolean
    begin
        GetUnreliablePayerServiceSetup();
        ReturnValue := true;
        if ((CountryCode <> '') and (CountryCode <> CompanyInformation."Country/Region Code") and
            (CompanyInformation."Country/Region Code" <> '')) or (CopyStr(VATRegNo, 1, 2) <> CZCountryCodeTok) then
            ReturnValue := false;
        OnAfterIsVATRegNoExportPossible(VATRegNo, CountryCode, ReturnValue);
    end;

    procedure GetLongVATRegNo(VatRegNo: Code[20]): Code[20]
    var
        TempCode: Code[1];
    begin
        if VatRegNo = '' then
            exit;
        TempCode := CopyStr(VatRegNo, 1, 1);
        if (TempCode >= '0') and (TempCode <= '9') then
            exit(CopyStr(CZCountryCodeTok + VatRegNo, 1, 20));
        exit(VatRegNo);
    end;

    procedure GetVendFromVATRegNo(VATRegNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        if VATRegNo = '' then
            exit('');

        VATRegNo := GetLongVATRegNo(VATRegNo);
        Vendor.SetCurrentKey("VAT Registration No.");
        Vendor.SetRange("VAT Registration No.", VATRegNo);
        Vendor.SetRange(Blocked, Vendor.Blocked::" ");
        case true of
            Vendor.FindFirst() and (Vendor.Count = 1):
                exit(Vendor."No.");
            else
                exit('');
        end;
    end;

    procedure IsPublicBankAccount(VendNo: Code[20]; VATRegNo: Code[20]; BankAccountNo: Code[30]; IBAN: Code[50]) ReturnValue: Boolean
    var
        Vendor: Record Vendor;
        UnreliablePayerEntryCZL: Record "Unreliable Payer Entry CZL";
    begin
        if Vendor.Get(VendNo) then
            if not Vendor.IsUnreliablePayerCheckPossibleCZL() then
                exit;
        if VATRegNo = '' then
            VATRegNo := Vendor."VAT Registration No.";
        if not IsVATRegNoExportPossible(VATRegNo, Vendor."Country/Region Code") then
            exit;

        UnreliablePayerEntryCZL.SetCurrentKey("VAT Registration No.");
        UnreliablePayerEntryCZL.SetRange("VAT Registration No.", VATRegNo);
        UnreliablePayerEntryCZL.SetRange("Entry Type", UnreliablePayerEntryCZL."Entry Type"::"Bank Account");
        UnreliablePayerEntryCZL.SetRange("End Public Date", 0D);
        if BankAccountNo <> '' then begin
            UnreliablePayerEntryCZL.SetRange("Full Bank Account No.", BankAccountNo);
            ReturnValue := not UnreliablePayerEntryCZL.IsEmpty();
        end;
        if ReturnValue then
            exit;

        if IBAN <> '' then begin
            UnreliablePayerEntryCZL.SetRange("Full Bank Account No.", IBAN);
            ReturnValue := not UnreliablePayerEntryCZL.IsEmpty();
        end;
    end;

    procedure PublicBankAccountCheckPossible(CheckDate: Date; AmountInclVAT: Decimal) CheckIsPossible: Boolean
    begin
        GetUnreliablePayerServiceSetup();
        CheckIsPossible := true;
        if UnrelPayerServiceSetupCZL."Public Bank Acc.Chck.Star.Date" <> 0D then
            CheckIsPossible := UnrelPayerServiceSetupCZL."Public Bank Acc.Chck.Star.Date" < CheckDate;
        if not CheckIsPossible then
            exit;
        if UnrelPayerServiceSetupCZL."Public Bank Acc.Check Limit" > 0 then
            CheckIsPossible := AmountInclVAT >= UnrelPayerServiceSetupCZL."Public Bank Acc.Check Limit";
    end;

    procedure ForeignBankAccountCheckPossible(VendNo: Code[20]; VendorBankAccountNo: Code[20]): Boolean
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.Get(VendNo, VendorBankAccountNo);
        exit(not VendorBankAccount.IsStandardFormatBankAccountCZL() and VendorBankAccount.IsForeignBankAccountCZL());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    local procedure HandleUnrelPayerServiceConnection(var ServiceConnection: Record "Service Connection")
    begin
        if not UnrelPayerServiceSetupCZL.Get() then begin
            if not UnrelPayerServiceSetupCZL.WritePermission then
                exit;
            UnrelPayerServiceSetupCZL.Init();
            UnrelPayerServiceSetupCZL.Insert();
        end;

        if UnrelPayerServiceSetupCZL.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            ServiceConnection.Status := ServiceConnection.Status::Disabled;
        ServiceConnection.InsertServiceConnection(
              ServiceConnection, UnrelPayerServiceSetupCZL.RecordId, UnrelPayerServiceSetupCZL.TableCaption, UnrelPayerServiceSetupCZL."Unreliable Payer Web Service", PAGE::"Unrel. Payer Service Setup CZL");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReleasePurchaseDoc', '', false, false)]
    local procedure CheckUnreliablePayerOnAfterReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    var
        UnreliablePayerEntryCZL: Record "Unreliable Payer Entry CZL";
        TotalPurchaseLine: Record "Purchase Line";
        TotalPurchaseLineLCY: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        PurchPost: Codeunit "Purch.-Post";
        VATAmount: Decimal;
        VATAmountText: Text[30];
    begin
        GetUnreliablePayerServiceSetup();
        PurchaseHeader.CalcFields("Third Party Bank Account CZL", "Amount Including VAT");
        if PurchaseHeader."Third Party Bank Account CZL" then
            exit;

        PurchPost.GetPurchLines(PurchaseHeader, TempPurchaseLine, 0);
        Clear(PurchPost);
        PurchPost.SumPurchLinesTemp(PurchaseHeader, TempPurchaseLine, 0, TotalPurchaseLine, TotalPurchaseLineLCY, VATAmount, VATAmountText);

        if PurchaseHeader.IsUnreliablePayerCheckPossibleCZL() then begin
            case PurchaseHeader.GetUnreliablePayerStatusCZL() of
                UnreliablePayerEntryCZL."Unreliable Payer"::YES:
                    ConfirmProcess(StrSubstNo(VendUnrVATPayerQst, PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."VAT Registration No."));
                UnreliablePayerEntryCZL."Unreliable Payer"::NOTFOUND:
                    ConfirmProcess(StrSubstNo(VendUnrVATPayerStatusNotCheckedQst, PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."VAT Registration No."));
            end;

            if not (PurchaseHeader."Document Type" in [PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Document Type"::"Return Order"]) then begin
                if PurchaseHeader."Bank Account Code" = '' then begin
                    if PublicBankAccountCheckPossible(PurchaseHeader."Posting Date", TotalPurchaseLineLCY."Amount Including VAT") then
                        ConfirmProcess(BankAccCodeNotExistQst);
                    exit;
                end;

                if PublicBankAccountCheckPossible(PurchaseHeader."Posting Date", TotalPurchaseLineLCY."Amount Including VAT") and
                   not ForeignBankAccountCheckPossible(PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."Bank Account Code") and
                   not IsPublicBankAccount(PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."VAT Registration No.", PurchaseHeader."Bank Account No.", PurchaseHeader.IBAN)
                then
                    ConfirmProcess(StrSubstNo(BankAccNotPublicQst, PurchaseHeader."Bank Account No.", PurchaseHeader."Pay-to Vendor No."));

                if ForeignBankAccountCheckPossible(PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."Bank Account Code") then
                    ConfirmProcess(StrSubstNo(BankAccIsForeignQst, PurchaseHeader."Bank Account Code", PurchaseHeader."Pay-to Vendor No."));
            end;
        end;
    end;

    local procedure ConfirmProcess(ConfirmQuestion: Text)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        OnBeforeConfirmProcess(ConfirmQuestion, IsHandled);
        if IsHandled then
            exit;
        if not IsConfirmDialogAllowed() then
            exit;
        if not ConfirmManagement.GetResponse(ConfirmQuestion, false) then
            Error('');
    end;

    local procedure IsConfirmDialogAllowed() IsAllowed: Boolean
    begin
        IsAllowed := GuiAllowed();
        OnIsConfirmDialogAllowed(IsAllowed);
    end;

    procedure CreateUnrelPayerServiceNotSetNotification()
    var
        ServiceNotSetNotification: Notification;
        ServiceNotSetLbl: Label 'Unreliable Payer Service is not set.';
        SetupLbl: Label 'Setup';
    begin
        ServiceNotSetNotification.Message := ServiceNotSetLbl;
        ServiceNotSetNotification.Scope := NotificationScope::LocalScope;
        ServiceNotSetNotification.AddAction(SetupLbl, Codeunit::"Unreliable Payer Mgt. CZL", 'OpenUnrelPayerServiceSetup');
        ServiceNotSetNotification.Send();
    end;

    procedure OpenUnrelPayerServiceSetup(ServiceNotSetNotification: Notification)
    begin
        Page.Run(Page::"Unrel. Payer Service Setup CZL");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsVATRegNoExportPossible(VATRegNo: Code[20]; CountryCode: Code[10]; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure  OnBeforeConfirmProcess(ConfirmQuestion: Text; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure  OnIsConfirmDialogAllowed(var IsAllowed: Boolean)
    begin
    end;

}
