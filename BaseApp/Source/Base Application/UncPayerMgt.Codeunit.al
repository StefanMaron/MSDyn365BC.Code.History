#if not CLEAN17
codeunit 11760 "Unc. Payer Mgt."
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '17.0';

    trigger OnRun()
    begin
    end;

    var
        ElectronicallyGovernSetup: Record "Electronically Govern. Setup";
        CompanyInformation: Record "Company Information";
        VATRegNoList: DotNet GenericList1;
        SetupReaded: Boolean;
        BankAccCodeNotExistQst: Label 'There is no bank account code in the document.\\Do you want to continue?';
        BankAccIsForeignQst: Label 'The bank account %1 of vendor %2 is foreign.\\Do you want to continue?', Comment = '%1=Bank Account No.;%2=Vendor No.';
        BankAccNotPublicQst: Label 'The bank account %1 of vendor %2 is not public.\\Do you want to continue?', Comment = '%1=Bank Account No.;%2=Vendor No.';
        CZCountryCodeTxt: Label 'CZ', Locked = true;
        ImportSuccessfulMsg: Label 'Import was successful. %1 new entries have been inserted.', Comment = '%1=Processed Entries Count';
        InterruptErr: Label 'The event was interrupted by the light of warnings.';
        UncVATPayerLinesExistQst: Label 'The count of lines with uncertainty VAT payer - %1\\Do you want to continue?', Comment = '%1=Count of Lines';
        UncVATPayerStatusNotCheckedQst: Label 'The uncertainty VAT payer status has not been checked.\\Do you want to continue?';
        VendUncVATPayerStatusNotCheckedQst: Label 'The uncertainty VAT payer status has not been checked for vendor %1 (%2).\\Do you want to continue?', Comment = '%1=Vendor No.;%2=VAT Registration No.';
        VendUncVATPayerQst: Label 'The vendor %1 (%2) is uncertainty VAT payer.\\Do you want to continue?', Comment = '%1=Vendor No.;%2=VAT Registration No.';

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure ImportUncPayerStatus(ShowMessage: Boolean): Boolean
    var
        DotNetArrayVATRegNo: Codeunit DotNet_Array;
        TempBlobResponse: Codeunit "Temp Blob";
        InsertEntryCount: Integer;
        VATRegNoCount: Integer;
        MaxVATRegNoCount: Integer;
        CurrVATRegNoCount: Integer;
        Index: Integer;
    begin
        if not GetSetup then
            exit(false);

        VATRegNoCount := GetVATRegNoCount;
        if VATRegNoCount = 0 then
            exit(false);

        MaxVATRegNoCount := GetMaxVATRegNoCount;
        Index := 0;

        repeat
            CurrVATRegNoCount := MaxVATRegNoCount;
            if VATRegNoCount <= MaxVATRegNoCount then
                CurrVATRegNoCount := VATRegNoCount;

            if not CopyVATRegNoListToArray(Index, CurrVATRegNoCount, DotNetArrayVATRegNo) then
                exit(false);

            if not GetUncPayerStatus(DotNetArrayVATRegNo, TempBlobResponse) then
                exit(false);

            InsertEntryCount += ImportUncPayerStatusResponse(TempBlobResponse);

            VATRegNoCount -= CurrVATRegNoCount;
            Index += CurrVATRegNoCount;
        until VATRegNoCount = 0;

        if ShowMessage then
            Message(ImportSuccessfulMsg, InsertEntryCount);

        exit(true);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure ImportUncPayerStatusForVendor(Vendor: Record Vendor): Boolean
    begin
        if not GetSetup then
            exit(false);

        if not Vendor.IsUncertaintyPayerCheckPossible then
            exit(false);

        ClearVATRegNoList;
        AddVATRegNoToList(Vendor."VAT Registration No.");
        exit(ImportUncPayerStatus(true));
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure ImportUncPayerStatusForPaymentOrder(PaymentOrderHeader: Record "Payment Order Header"): Boolean
    var
        PaymentOrderLine: Record "Payment Order Line";
        Vendor: Record Vendor;
    begin
        if not GetSetup then
            exit(false);

        SetPaymentOrderLineFilter(PaymentOrderHeader, PaymentOrderLine);
        if not PaymentOrderLine.FindSet then
            exit(false);

        ClearVATRegNoList;
        repeat
            Vendor.Get(PaymentOrderLine."No.");
            if Vendor.IsUncertaintyPayerCheckPossible then
                AddVATRegNoToList(Vendor."VAT Registration No.");
        until PaymentOrderLine.Next() = 0;

        if GetVATRegNoCount = 0 then
            exit(false);

        exit(ImportUncPayerStatus(false));
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure ImportUncPayerList(ShowMessage: Boolean): Boolean
    var
        TempBlobResponse: Codeunit "Temp Blob";
        InsertEntryCount: Integer;
    begin
        if not GetSetup then
            exit(false);

        if not GetUncPayerList(TempBlobResponse) then
            exit(false);

        InsertEntryCount := ImportUncPayerListResponse(TempBlobResponse);

        if ShowMessage then
            Message(ImportSuccessfulMsg, InsertEntryCount);

        exit(true);
    end;

    local procedure GetUncPayerStatus(DotNetArrayVATRegNo: Codeunit DotNet_Array; var TempBlobResponse: Codeunit "Temp Blob"): Boolean
    var
        UncPayerWSConnector: Codeunit "Unc. Payer WS Connector";
    begin
        GetSetup;
        UncPayerWSConnector.SetServiceUrl(ElectronicallyGovernSetup.UncertaintyPayerWebService);
        exit(UncPayerWSConnector.GetStatus(DotNetArrayVATRegNo, TempBlobResponse));
    end;

    local procedure GetUncPayerList(var TempBlobResponse: Codeunit "Temp Blob"): Boolean
    var
        UncPayerWSConnector: Codeunit "Unc. Payer WS Connector";
    begin
        GetSetup;
        UncPayerWSConnector.SetServiceUrl(ElectronicallyGovernSetup.UncertaintyPayerWebService);
        exit(UncPayerWSConnector.GetList(TempBlobResponse));
    end;

    local procedure ImportUncPayerStatusResponse(var TempBlobResponse: Codeunit "Temp Blob"): Integer
    var
        UncPayerStatusResponse: XMLport "Unc. Payer Status - Response";
        ResponseInStream: InStream;
    begin
        TempBlobResponse.CreateInStream(ResponseInStream);
        UncPayerStatusResponse.SetSource(ResponseInStream);
        UncPayerStatusResponse.Import;
        exit(UncPayerStatusResponse.GetInsertEntryCount);
    end;

    local procedure ImportUncPayerListResponse(var TempBlobResponse: Codeunit "Temp Blob"): Integer
    var
        UncPayerListResponse: XMLport "Unc. Payer List - Response";
        ResponseInStream: InStream;
    begin
        TempBlobResponse.CreateInStream(ResponseInStream);
        UncPayerListResponse.SetSource(ResponseInStream);
        UncPayerListResponse.Import;
        exit(UncPayerListResponse.GetInsertEntryCount);
    end;

    local procedure GetMaxVATRegNoCount(): Integer
    var
        UncPayerWSConnector: Codeunit "Unc. Payer WS Connector";
    begin
        GetSetup;
        if ElectronicallyGovernSetup."Unc.Payer Request Record Limit" <> 0 then
            exit(ElectronicallyGovernSetup."Unc.Payer Request Record Limit");
        exit(UncPayerWSConnector.GetInputRecordLimit);
    end;

    local procedure GetSetup(): Boolean
    begin
        if SetupReaded then
            exit(true);

        if not ElectronicallyGovernSetup.Get then
            exit(false);

        if ElectronicallyGovernSetup.UncertaintyPayerWebService = '' then
            exit(false);

        CompanyInformation.Get();
        SetupReaded := true;
        exit(true);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure AddVATRegNoToList(VATRegNo: Code[20])
    begin
        if VATRegNo = '' then
            exit;

        if IsNull(VATRegNoList) then
            VATRegNoList := VATRegNoList.List;

        if VATRegNoList.Contains(VATRegNo) then
            exit;

        VATRegNoList.Add(VATRegNo);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure GetVATRegNoCount(): Integer
    begin
        if IsNull(VATRegNoList) then
            exit(0);

        exit(VATRegNoList.Count);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure ClearVATRegNoList()
    begin
        if IsNull(VATRegNoList) then
            exit;

        VATRegNoList.Clear;
    end;

    [TryFunction]
    local procedure CopyVATRegNoListToArray(Index: Integer; "Count": Integer; var DotNetArrayVATRegNo: Codeunit DotNet_Array)
    var
        DotNetArray: DotNet Array;
    begin
        DotNetArrayVATRegNo.StringArray(Count);
        DotNetArrayVATRegNo.GetArray(DotNetArray);
        VATRegNoList.CopyTo(Index, DotNetArray, 0, Count);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    procedure IsVATRegNoExportPossible(VATRegNo: Code[20]; CountryCode: Code[10]) ReturnValue: Boolean
    begin
        if not GetSetup then
            exit(false);

        ReturnValue := true;
        if ((CountryCode <> '') and (CountryCode <> CompanyInformation."Country/Region Code") and
            (CompanyInformation."Country/Region Code" <> '')) or
           (CopyStr(VATRegNo, 1, 2) <> CZCountryCodeTxt)
        then
            ReturnValue := false;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure GetLongVATRegNo(VatRegNo: Code[20]): Code[20]
    var
        TempCode: Code[1];
    begin
        if VatRegNo = '' then
            exit;

        TempCode := CopyStr(VatRegNo, 1, 1);
        if (TempCode >= '0') and (TempCode <= '9') then
            exit(CZCountryCodeTxt + VatRegNo);

        exit(VatRegNo);
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure GetVendFromVATRegNo(VATRegNo: Code[20]): Code[20]
    var
        Vend: Record Vendor;
    begin
        if VATRegNo = '' then
            exit('');

        VATRegNo := GetLongVATRegNo(VATRegNo);

        Vend.SetCurrentKey("VAT Registration No.");
        Vend.SetRange("VAT Registration No.", VATRegNo);
        Vend.SetRange(Blocked, Vend.Blocked::" ");

        case true of
            Vend.FindFirst and (Vend.Count = 1):
                exit(Vend."No.");
            else
                exit('');
        end;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure IsPublicBankAccount(VendNo: Code[20]; VATRegNo: Code[20]; BankAccountNo: Code[30]; IBAN: Code[50]) ReturnValue: Boolean
    var
        Vendor: Record Vendor;
        UncertaintyPayerEntry: Record "Uncertainty Payer Entry";
    begin
        if Vendor.Get(VendNo) then
            if not Vendor.IsUncertaintyPayerCheckPossible then
                exit;

        if VATRegNo = '' then
            VATRegNo := Vendor."VAT Registration No.";

        if not IsVATRegNoExportPossible(VATRegNo, Vendor."Country/Region Code") then
            exit;

        UncertaintyPayerEntry.SetCurrentKey("VAT Registration No.");
        UncertaintyPayerEntry.SetRange("VAT Registration No.", VATRegNo);
        UncertaintyPayerEntry.SetRange("Entry Type", UncertaintyPayerEntry."Entry Type"::"Bank Account");
        UncertaintyPayerEntry.SetFilter("End Public Date", '%1', 0D);
        if BankAccountNo <> '' then begin
            UncertaintyPayerEntry.SetFilter("Full Bank Account No.", '%1', BankAccountNo);
            ReturnValue := UncertaintyPayerEntry.FindLast;
        end;

        if ReturnValue then
            exit;

        if IBAN <> '' then begin
            UncertaintyPayerEntry.SetFilter("Full Bank Account No.", '%1', IBAN);
            ReturnValue := UncertaintyPayerEntry.FindLast;
        end;
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure PublicBankAccountCheckPossible(CheckDate: Date; AmountInclVAT: Decimal) CheckIsPossible: Boolean
    begin
        if not GetSetup then
            exit;
        CheckIsPossible := true;
        if ElectronicallyGovernSetup."Public Bank Acc.Chck.Star.Date" <> 0D then
            CheckIsPossible := ElectronicallyGovernSetup."Public Bank Acc.Chck.Star.Date" < CheckDate;
        if not CheckIsPossible then
            exit;
        if ElectronicallyGovernSetup."Public Bank Acc.Check Limit" > 0 then
            CheckIsPossible := AmountInclVAT >= ElectronicallyGovernSetup."Public Bank Acc.Check Limit";
    end;

    [Obsolete('Moved to Core Localization Pack for Czech.', '17.4')]
    [Scope('OnPrem')]
    procedure ForeignBankAccountCheckPossible(VendNo: Code[20]; VendBankAccNo: Code[20]): Boolean
    var
        VendBankAcc: Record "Vendor Bank Account";
    begin
        VendBankAcc.Get(VendNo, VendBankAccNo);
        exit(not VendBankAcc.IsStandardFormatBankAccount and VendBankAcc.IsForeignBankAccount);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    local procedure HandleElGovernmentRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    begin
        if not ElectronicallyGovernSetup.Get then begin
            if not ElectronicallyGovernSetup.WritePermission then
                exit;
            ElectronicallyGovernSetup.Init();
            ElectronicallyGovernSetup.Insert();
        end;

        ServiceConnection.Status := ServiceConnection.Status::Enabled;
        if ElectronicallyGovernSetup.UncertaintyPayerWebService = '' then
            ServiceConnection.Status := ServiceConnection.Status::Disabled;

        with ElectronicallyGovernSetup do
            ServiceConnection.InsertServiceConnection(
              ServiceConnection, RecordId, TableCaption, UncertaintyPayerWebService, PAGE::"Electronically Govern. Setup");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReleasePurchaseDoc', '', false, false)]
    local procedure CheckUncertaintyPayerOnAfterReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    var
        UncertaintyPayerEntry: Record "Uncertainty Payer Entry";
        TotalPurchLine: Record "Purchase Line";
        TotalPurchLineLCY: Record "Purchase Line";
        TempPurchLine: Record "Purchase Line" temporary;
        PurchPost: Codeunit "Purch.-Post";
        VATAmount: Decimal;
        VATAmountText: Text[30];
    begin
        if not GuiAllowed then
            exit;

        if not GetSetup then
            exit;

        PurchaseHeader.CalcFields("Third Party Bank Account", "Amount Including VAT");
        if PurchaseHeader."Third Party Bank Account" then
            exit;

        PurchPost.GetPurchLines(PurchaseHeader, TempPurchLine, 0);
        Clear(PurchPost);
        PurchPost.SumPurchLinesTemp(
          PurchaseHeader, TempPurchLine, 0, TotalPurchLine, TotalPurchLineLCY, VATAmount, VATAmountText);

        with PurchaseHeader do
            if IsUncertaintyPayerCheckPossible then begin
                case GetUncertaintyPayerStatus of
                    UncertaintyPayerEntry."Uncertainty Payer"::YES:
                        ConfirmProcess(StrSubstNo(VendUncVATPayerQst, "Pay-to Vendor No.", "VAT Registration No."));
                    UncertaintyPayerEntry."Uncertainty Payer"::NOTFOUND:
                        ConfirmProcess(StrSubstNo(VendUncVATPayerStatusNotCheckedQst, "Pay-to Vendor No.", "VAT Registration No."));
                end;

                if not ("Document Type" in ["Document Type"::"Credit Memo", "Document Type"::"Return Order"]) then begin
                    if "Bank Account Code" = '' then begin
                        if PublicBankAccountCheckPossible("Posting Date", TotalPurchLineLCY."Amount Including VAT") then
                            ConfirmProcess(BankAccCodeNotExistQst);
                        exit;
                    end;

                    if PublicBankAccountCheckPossible("Posting Date", TotalPurchLineLCY."Amount Including VAT") and
                       not ForeignBankAccountCheckPossible("Pay-to Vendor No.", "Bank Account Code") and
                       not IsPublicBankAccount("Pay-to Vendor No.", "VAT Registration No.", "Bank Account No.", IBAN)
                    then
                        ConfirmProcess(StrSubstNo(BankAccNotPublicQst, "Bank Account No.", "Pay-to Vendor No."));

                    if ForeignBankAccountCheckPossible("Pay-to Vendor No.", "Bank Account Code") then
                        ConfirmProcess(StrSubstNo(BankAccIsForeignQst, "Bank Account Code", "Pay-to Vendor No."));
                end;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Issue Payment Order", 'OnCodeOnAfterCheck', '', false, false)]
    local procedure CheckUncertaintyPayerOnCodeOnAfterCheckIssuePmtOrder(var PaymentOrderHeader: Record "Payment Order Header")
    var
        PaymentOrderLine: Record "Payment Order Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CheckAmount: Decimal;
        UncPayerLinesCount: Integer;
        CheckPossible: Boolean;
    begin
        if not GuiAllowed then
            exit;

        if not GetSetup then
            exit;

        SetPaymentOrderLineFilter(PaymentOrderHeader, PaymentOrderLine);
        if PaymentOrderLine.IsEmpty() then
            exit;

        if PaymentOrderHeader.UncertaintyPayerCheckExpired then
            PaymentOrderHeader.ImportUncPayerStatus;

        if PaymentOrderLine.FindSet then
            repeat
                if PaymentOrderLine.IsUncertaintyPayerCheckPossible then begin
                    CheckPossible := true;

                    if PaymentOrderHeader."Uncertainty Pay.Check DateTime" <> 0DT then begin
                        if PaymentOrderLine."VAT Uncertainty Payer" then
                            UncPayerLinesCount += 1;

                        PaymentOrderLine.CalcFields("Third Party Bank Account");

                        if not PaymentOrderLine."Public Bank Account" then begin
                            CheckAmount := Abs(PaymentOrderLine."Amount (LCY) to Pay");
                            if PaymentOrderLine."Applies-to C/V/E Entry No." <> 0 then begin
                                VendLedgEntry.Get(PaymentOrderLine."Applies-to C/V/E Entry No.");
                                VendLedgEntry.CalcFields("Original Amt. (LCY)");
                                CheckAmount := Abs(VendLedgEntry."Original Amt. (LCY)");
                            end;
                            if (not PaymentOrderLine."Third Party Bank Account") and
                               PublicBankAccountCheckPossible(PaymentOrderHeader."Document Date", CheckAmount) and
                               not ForeignBankAccountCheckPossible(
                                 PaymentOrderLine."No.", PaymentOrderLine."Cust./Vendor Bank Account Code")
                            then
                                ConfirmProcess(
                                  StrSubstNo(BankAccNotPublicQst, PaymentOrderLine."Cust./Vendor Bank Account Code", PaymentOrderLine."No."));
                        end;

                        if (not PaymentOrderLine."Third Party Bank Account") and
                           ForeignBankAccountCheckPossible(
                             PaymentOrderLine."No.", PaymentOrderLine."Cust./Vendor Bank Account Code")
                        then
                            ConfirmProcess(
                              StrSubstNo(BankAccIsForeignQst, PaymentOrderLine."Cust./Vendor Bank Account Code", PaymentOrderLine."No."));
                    end;
                end;
            until PaymentOrderLine.Next() = 0;

        if CheckPossible then begin
            if PaymentOrderHeader."Uncertainty Pay.Check DateTime" = 0DT then
                ConfirmProcess(UncVATPayerStatusNotCheckedQst);

            if UncPayerLinesCount > 0 then
                ConfirmProcess(StrSubstNo(UncVATPayerLinesExistQst, UncPayerLinesCount))
        end;
    end;

    local procedure SetPaymentOrderLineFilter(PaymentOrderHeader: Record "Payment Order Header"; var PaymentOrderLine: Record "Payment Order Line")
    begin
        PaymentOrderLine.Reset();
        PaymentOrderLine.SetRange("Payment Order No.", PaymentOrderHeader."No.");
        PaymentOrderLine.SetRange(Type, PaymentOrderLine.Type::Vendor);
        PaymentOrderLine.SetRange("Skip Payment", false);
    end;

    local procedure ConfirmProcess(ConfirmQuestion: Text)
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not GuiAllowed then
            exit;

        if not ConfirmManagement.GetResponse(ConfirmQuestion, false) then
            Error(InterruptErr);
    end;
}


#endif