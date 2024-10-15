#if not CLEAN18
codeunit 31121 "EET Entry Management"
{
    Permissions = TableData "EET Entry" = rimd,
                  TableData "EET Entry Status" = rimd;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Cash Desk Localization for Czech.';
    ObsoleteTag = '18.0';

    var
        EETServiceSetup: Record "EET Service Setup";
        TempErrorMessage: Record "Error Message" temporary;
        TempBlob: Codeunit "Temp Blob";
        InputStream: InStream;
        OutputStream: OutStream;
        HasGotSetup: Boolean;
        WarningsTxt: Label 'Warnings...';
        EETEntryAlreadyCanceledQst: Label 'The %1 No. %2 has been already canceled by Entry No. %3.\\Continue?', Comment = '%1 = Tablecaption;%2 =  EET Entry No..;%3 = Canceled by Entry No.';
        CancelByEETEntryNoMsg: Label 'Cancel by EET Entry No. %1.', Comment = '%1 = EET Entry No.';
        CancelEntryToEntryMsg: Label 'Cancel Entry to Original Entry No. %1.', Comment = '%1 = EET Entry No.';
        CancelByEETEntryNoQst: Label 'EET Entry No. %1 will be canceled.\Continue?', Comment = '%1 = EET Entry No.';

    [Scope('OnPrem')]
    procedure IsEETEnabled(): Boolean
    begin
        exit(EETServiceSetup.Get and EETServiceSetup.Enabled);
    end;

    [Scope('OnPrem')]
    procedure IsEETCashRegister(CashDeskNo: Code[20]): Boolean
    var
        EETCashReg: Record "EET Cash Register";
        EETCashRegister: Boolean;
    begin
        EETCashRegister := FindEETCashRegister(CashDeskNo, EETCashReg);
        OnBeforeIsEETCashRegister(CashDeskNo, EETCashRegister);
        exit(EETCashRegister);
    end;

    [Scope('OnPrem')]
    procedure FindEETCashRegister(CashDeskNo: Code[20]; var EETCashReg: Record "EET Cash Register"): Boolean
    begin
        if CashDeskNo = '' then
            exit(false);
        EETCashReg.Reset();
        EETCashReg.SetCurrentKey("Register Type", "Register No.");
        EETCashReg.SetRange("Register Type", EETCashReg."Register Type"::"Cash Desk");
        EETCashReg.SetRange("Register No.", CashDeskNo);
        exit(EETCashReg.FindFirst);
    end;

    [Scope('OnPrem')]
    procedure SetEntryStatus(var EETEntry: Record "EET Entry"; NewStatus: Option; NewDescription: Text)
    begin
        EETEntry.TestField("Entry No.");
        EETEntry."EET Status" := NewStatus;
        EETEntry."EET Status Last Changed" := CurrentDateTime;
        EETEntry.Modify();
        LogEntryStatus(EETEntry, NewDescription);
    end;

    local procedure LogEntryStatus(EETEntry: Record "EET Entry"; Description: Text)
    var
        EETEntryStatus: Record "EET Entry Status";
        ErrorMessage: Record "Error Message";
        NextEntryNo: Integer;
    begin
        EETEntry.TestField("Entry No.");
        EETEntryStatus.LockTable();
        NextEntryNo := EETEntryStatus.GetLastEntryNo() + 1;

        EETEntryStatus.Init();
        EETEntryStatus."Entry No." := NextEntryNo;
        EETEntryStatus."EET Entry No." := EETEntry."Entry No.";
        EETEntryStatus.Status := EETEntry."EET Status";
        EETEntryStatus."Change Datetime" := EETEntry."EET Status Last Changed";
        EETEntryStatus.Description := CopyStr(Description, 1, MaxStrLen(EETEntryStatus.Description));
        EETEntryStatus.Insert();

        if TempErrorMessage.ErrorMessageCount(TempErrorMessage."Message Type"::Warning) > 0 then
            if TempErrorMessage.FindSet() then
                repeat
                    ErrorMessage := TempErrorMessage;
                    ErrorMessage.ID := 0;
                    ErrorMessage.Validate("Record ID", EETEntryStatus.RecordId);
                    ErrorMessage.Validate("Context Record ID", EETEntryStatus.RecordId);
                    ErrorMessage.Insert(true);
                until TempErrorMessage.Next() = 0;
    end;

    local procedure InitEntry(var EETEntry: Record "EET Entry")
    var
        NextEntryNo: Integer;
    begin
        EETEntry.Reset();
        EETEntry.LockTable();
        NextEntryNo := EETEntry.GetLastEntryNo() + 1;
        EETEntry.Init();
        EETEntry."Entry No." := NextEntryNo;
        EETEntry."User ID" := UserId;
        EETEntry."Creation Datetime" := CurrentDateTime;
    end;

    local procedure GetSetup()
    begin
        if not HasGotSetup then
            EETServiceSetup.Get();
        HasGotSetup := true;
    end;

    [Scope('OnPrem')]
    procedure SendEntryToService(var EETEntry: Record "EET Entry"; VerificationMode: Boolean)
    begin
        EETEntry.TestField("Entry No.");
        TempErrorMessage.ClearLog;
        if not VerificationMode then
            SendEntryToRegister(EETEntry)
        else
            SendEntryToVerification(EETEntry);
    end;

    local procedure SendEntryToRegister(var EETEntry: Record "EET Entry")
    var
        EETServiceMgt: Codeunit "EET Service Mgt.";
    begin
        if EETEntry."EET Status" in [EETEntry."EET Status"::Created,
                                     EETEntry."EET Status"::Sent,
                                     EETEntry."EET Status"::Success,
                                     EETEntry."EET Status"::"Success with Warnings"]
        then
            EETEntry.FieldError("EET Status");

        PrepareEntryToSend(EETEntry);
        SetEntryStatus(EETEntry, EETEntry."EET Status"::Sent, '');

        if EETServiceMgt.SendRegisteredSalesDataMessage(EETEntry) then begin
            EETEntry."Fiscal Identification Code" := EETServiceMgt.GetFIKControlCode;

            if EETServiceMgt.HasWarnings then begin
                EETServiceMgt.CopyErrorMessageToTemp(TempErrorMessage);
                SetEntryStatus(EETEntry, EETEntry."EET Status"::"Success with Warnings", WarningsTxt);
            end else
                SetEntryStatus(EETEntry, EETEntry."EET Status"::Success, '');
        end else begin
            EETServiceMgt.CopyErrorMessageToTemp(TempErrorMessage);
            SetEntryStatus(EETEntry, EETEntry."EET Status"::Failure, EETServiceMgt.GetResponseText);
        end;
    end;

    local procedure SendEntryToVerification(var EETEntry: Record "EET Entry")
    var
        EETServiceMgt: Codeunit "EET Service Mgt.";
    begin
        if EETEntry."EET Status" in [EETEntry."EET Status"::Sent,
                                     EETEntry."EET Status"::"Sent to Verification",
                                     EETEntry."EET Status"::Success,
                                     EETEntry."EET Status"::"Success with Warnings"]
        then
            EETEntry.FieldError("EET Status");

        PrepareEntryToSend(EETEntry);
        SetEntryStatus(EETEntry, EETEntry."EET Status"::"Sent to Verification", '');

        EETServiceMgt.SetVerificationMode(true);
        if EETServiceMgt.SendRegisteredSalesDataMessage(EETEntry) then
            if EETServiceMgt.HasWarnings then begin
                EETServiceMgt.CopyErrorMessageToTemp(TempErrorMessage);
                SetEntryStatus(EETEntry, EETEntry."EET Status"::"Verified with Warnings", WarningsTxt);
            end else
                SetEntryStatus(EETEntry, EETEntry."EET Status"::Verified, EETServiceMgt.GetResponseText)
        else begin
            EETServiceMgt.CopyErrorMessageToTemp(TempErrorMessage);
            SetEntryStatus(EETEntry, EETEntry."EET Status"::Failure, EETServiceMgt.GetResponseText);
        end;
    end;

    local procedure PrepareEntryToSend(var EETEntry: Record "EET Entry")
    begin
        EETEntry."Message UUID" := CreateUUID;
    end;

    local procedure GenerateControlCodes(var EETEntry: Record "EET Entry")
    begin
        EETEntry.SaveSignatureCode(EETEntry.GenerateSignatureCode);
        EETEntry."Security Code (BKP)" := EETEntry.GenerateSecurityCode;
    end;

    [Scope('OnPrem')]
    procedure GenerateSignatureCodePlainText(var EETEntry: Record "EET Entry"): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        with EETEntry do
            exit(
              StrSubstNo('%1|%2|%3|%4|%5|%6',
                CompanyInformation."VAT Registration No.", GetBusinessPremisesId, GetCashRegisterNo,
                "Receipt Serial No.", FormatDateTime("Creation Datetime"), FormatDecimal("Total Sales Amount")));
    end;

    [Scope('OnPrem')]
    procedure GenerateSignatureCode(var EETEntry: Record "EET Entry"): Text
    var
        IsolatedCertificate: Record "Isolated Certificate";
        CertificateCZCode: Record "Certificate CZ Code";
        Base64Convert: Codeunit "Base64 Convert";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        CertificateCZCode.Get(EETEntry.GetCertificateCode);
        if not CertificateCZCode.LoadValidCertificate(IsolatedCertificate) then
            exit;

        InitBlob();
        SignText(GenerateSignatureCodePlainText(EETEntry), IsolatedCertificate, HashAlgorithmType::SHA256, OutputStream);
        exit(Base64Convert.ToBase64(InputStream));
    end;

    [Scope('OnPrem')]
    procedure GenerateSecurityCode(SignatureCode: Text): Text[44]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        Base64Convert: Codeunit "Base64 Convert";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        Hash: Text;
    begin
        if SignatureCode = '' then
            exit;

        InitBlob();
        Base64Convert.FromBase64(SignatureCode, OutputStream);
        Hash := CryptographyManagement.GenerateHash(InputStream, HashAlgorithmType::SHA1);
        exit(
          StrSubstNo('%1-%2-%3-%4-%5',
            CopyStr(Hash, 1, 8), CopyStr(Hash, 9, 8), CopyStr(Hash, 17, 8),
            CopyStr(Hash, 25, 8), CopyStr(Hash, 33, 8)));
    end;

    local procedure SignText(InputString: Text; IsolatedCertificate: Record "Isolated Certificate"; HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512; SignatureStream: OutStream)
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        DotNetAsimmetricAlgorithm: Codeunit DotNet_AsymmetricAlgorithm;
        DotNetX509Certificate2: Codeunit DotNet_X509Certificate2;
#if CLEAN18
        SignatureKey: Record "Signature Key";
#else
        TempBlob: Codeunit "Temp Blob";
        KeyStream: InStream;
        OutputStream: OutStream;
#endif
    begin
        IsolatedCertificate.GetDotNetX509Certificate2(DotNetX509Certificate2);
        DotNetX509Certificate2.PrivateKey(DotNetAsimmetricAlgorithm);

#if CLEAN18
        SignatureKey."Signature Algorithm" := Enum::SignatureAlgorithm::RSA;
        SignatureKey.FromXmlString(DotNetAsimmetricAlgorithm.ToXmlString(true));
        CryptographyManagement.SignData(InputString, SignatureKey, Enum::"Hash Algorithm".FromInteger(HashAlgorithmType), SignatureStream);
#else
        TempBlob.CreateOutStream(OutputStream);
        TempBlob.CreateInStream(KeyStream);
        OutputStream.Write(DotNetAsimmetricAlgorithm.ToXmlString(true));
        CryptographyManagement.SignData(InputString, KeyStream, HashAlgorithmType, SignatureStream);
#endif
    end;

    local procedure InitBlob()
    begin
        Clear(TempBlob);
        TempBlob.CreateInStream(InputStream);
        TempBlob.CreateOutStream(OutputStream);
    end;

    [Scope('OnPrem')]
    procedure FormatOption(Option: Option): Text
    begin
        exit(Format(Option, 0, 9));
    end;

    [Scope('OnPrem')]
    procedure FormatDecimal(Decimal: Decimal): Text
    begin
        exit(Format(Decimal, 0, '<Precision,2:2><Standard Format,2>'));
    end;

    [Scope('OnPrem')]
    procedure FormatBoolean(Boolean: Boolean): Text
    begin
        exit(Format(Boolean, 0, 9));
    end;

    [Scope('OnPrem')]
    procedure FormatDateTime(DateTime: DateTime): Text
    begin
        exit(Format(RoundDateTime(DateTime), 0, 9));
    end;

    local procedure CreateUUID(): Text[36]
    begin
        exit(DelChr(LowerCase(Format(CreateGuid)), '=', '{}'));
    end;

    [Scope('OnPrem')]
    procedure CreateCancelEETEntry(EETEntryNo: Integer; Send: Boolean; WithConfirmation: Boolean): Integer
    var
        EETEntryOrig: Record "EET Entry";
        NewEETEntry: Record "EET Entry";
    begin
        if not EETEntryOrig.Get(EETEntryNo) then
            exit;

        OnBeforeCreateCancelEETEntry(EETEntryOrig);

        if GuiAllowed and WithConfirmation then begin
            if EETEntryOrig."Canceled By Entry No." = 0 then
                if not Confirm(
                     CancelByEETEntryNoQst,
                     false,
                     EETEntryOrig."Entry No.")
                then
                    Error('');

            if EETEntryOrig."Canceled By Entry No." <> 0 then
                if not Confirm(
                     EETEntryAlreadyCanceledQst,
                     false,
                     EETEntryOrig.TableCaption,
                     EETEntryOrig."Entry No.",
                     EETEntryOrig."Canceled By Entry No.")
                then
                    Error('');
        end;

        NewEETEntry.CopySourceInfoFromEntry(EETEntryOrig, true);
        NewEETEntry.CopyAmountsFromEntry(EETEntryOrig);
        NewEETEntry.ReverseAmounts;

        NewEETEntry.Get(CreateEETEntrySimple(NewEETEntry, false, false, true));

        NewEETEntry."User ID" := UserId;
        NewEETEntry."Creation Datetime" := CurrentDateTime;

        SetEntryStatus(
          NewEETEntry,
          NewEETEntry."EET Status"::Created,
          StrSubstNo(
            CancelEntryToEntryMsg, EETEntryOrig."Entry No.")
          );

        EETEntryOrig."Canceled By Entry No." := NewEETEntry."Entry No.";
        EETEntryOrig.Modify();

        SetEntryStatus(
          EETEntryOrig,
          EETEntryOrig."EET Status",
          StrSubstNo(
            CancelByEETEntryNoMsg,
            EETEntryOrig."Canceled By Entry No.")
          );

        // Process entry
        if Send then
            RegisterEntry(NewEETEntry."Entry No.");

        exit(NewEETEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure CreateEETEntrySimple(EETEntrySource: Record "EET Entry"; InitializeSerialNo: Boolean; SetStatusToSendPending: Boolean; SimpleRegistration: Boolean): Integer
    var
        EETEntry: Record "EET Entry";
    begin
        InitEntry(EETEntry);
        EETEntry.CopySourceInfoFromEntry(EETEntrySource, InitializeSerialNo);
        EETEntry.CopyAmountsFromEntry(EETEntrySource);
        EETEntry."Simple Registration" := SimpleRegistration;
        EETEntry.Insert();

        GenerateControlCodes(EETEntry);
        EETEntry.Modify();

        if SetStatusToSendPending then
            SetEntryStatus(EETEntry, EETEntry."EET Status"::"Send Pending", '');

        exit(EETEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure RegisterEntry(EETEntryNo: Integer)
    var
        EETEntry: Record "EET Entry";
    begin
        // Process entry
        if EETEntryNo = 0 then
            exit;

        EETEntry.Get(EETEntryNo);

        SetEntryStatus(
          EETEntry,
          EETEntry."EET Status"::"Send Pending",
          ''
          );

        GetSetup;
        if EETServiceSetup."Sales Regime" = EETServiceSetup."Sales Regime"::Regular then
            SendEntryToService(EETEntry, false);
    end;

    [Scope('OnPrem')]
    procedure GetEETStatusStyleExpr(EETStatus: Option): Text
    var
        DummyEETEntry: Record "EET Entry";
    begin
        with DummyEETEntry do
            case EETStatus of
                "EET Status"::Created:
                    exit('Subordinate');
                "EET Status"::Failure:
                    exit('Unfavorable');
                "EET Status"::Success:
                    exit('Favorable');
                "EET Status"::Verified:
                    exit('StandardAccent');
                "EET Status"::"Verified with Warnings":
                    exit('AttentionAccent');
                "EET Status"::"Success with Warnings":
                    exit('Ambiguous');
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCancelEETEntry(OrigEETEntry: Record "EET Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsEETCashRegister(CashDeskNo: Code[20]; var EETCashRegister: Boolean)
    begin
    end;
}
#endif