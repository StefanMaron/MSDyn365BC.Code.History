codeunit 10098 "Generate EFT"
{

    trigger OnRun()
    begin
    end;

    var
        BankAccount: Record "Bank Account";
        DummyLastEFTExportWorkset: Record "EFT Export Workset";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        DataCompression: Codeunit "Data Compression";
        FileManagement: Codeunit "File Management";
        ExportPaymentsACH: Codeunit "Export Payments (ACH)";
        ACHFileCreated: Boolean;
        IATFileCreated: Boolean;
        SaveFolderMsg: Label 'Select a folder to save reports to.';
        Path: Text;
        SelectAFolderMsg: Label 'A folder needs to be selected.';
        NothingToExportErr: Label 'There is nothing to export.';
        ProcessOrderNo: Integer;
        GeneratingFileMsg: Label 'The electronic funds transfer file is now being generated.';
        ZipFileName: Text;

    [Scope('OnPrem')]
    procedure ProcessAndGenerateEFTFile(BalAccountNo: Code[20]; SettlementDate: Date; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; var EFTValues: Codeunit "EFT Values")
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        ExportEFTACH: Codeunit "Export EFT (ACH)";
        Window: Dialog;
    begin
        InitialChecks(BalAccountNo);

        ACHFileCreated := false;
        IATFileCreated := false;

        if FileManagement.IsLocalFileSystemAccessible then
            if not IsTestMode then begin
                FileManagement.SelectFolderDialog(SaveFolderMsg, Path);
                if Path = '' then begin
                    Message(SelectAFolderMsg);
                    exit;
                end;
            end;

        Window.Open(GeneratingFileMsg);

        TempEFTExportWorkset.SetRange("Bank Payment Type", 3, 3);
        if TempEFTExportWorkset.FindFirst then
            StartEFTProcess(SettlementDate, TempEFTExportWorkset, EFTValues);

        EFTValues.SetParentDefCode('');

        TempEFTExportWorkset.Reset;
        TempEFTExportWorkset.SetRange("Bank Payment Type", 4, 4);
        if TempEFTExportWorkset.FindFirst then
            StartEFTProcess(SettlementDate, TempEFTExportWorkset, EFTValues);

        if EFTValues.GetIATFileCreated or EFTValues.GetEFTFileCreated then
            if CustomLayoutReporting.IsWebClient then
                ExportEFTACH.DownloadWebclientZip(TempNameValueBuffer, ZipFileName, DataCompression);

        Window.Close;
    end;

    local procedure InitialChecks(BankAccountNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitalChecks(BankAccountNo, IsHandled);
        if IsHandled then
            exit;

        with BankAccount do begin
            LockTable;
            Get(BankAccountNo);
            TestField(Blocked, false);
            TestField("Currency Code", '');  // local currency only
            TestField("Export Format");
            TestField("Last Remittance Advice No.");
        end;
    end;

    local procedure CheckAndStartExport(var TempEFTExportWorkset: Record "EFT Export Workset" temporary; var EFTValues: Codeunit "EFT Values")
    var
        ExpLauncherEFT: Codeunit "Exp. Launcher EFT";
    begin
        if (not ACHFileCreated and
            (TempEFTExportWorkset."Bank Payment Type" = TempEFTExportWorkset."Bank Payment Type"::"Electronic Payment")) or
           (not IATFileCreated and
            (TempEFTExportWorkset."Bank Payment Type" = TempEFTExportWorkset."Bank Payment Type"::"Electronic Payment-IAT"))
        then
            with TempEFTExportWorkset do begin
                if not FindSet then
                    Error(NothingToExportErr);

                ExpLauncherEFT.EFTPaymentProcess(TempEFTExportWorkset, TempNameValueBuffer, DataCompression, ZipFileName, EFTValues);
            end;
    end;

    local procedure SetGenJrnlCheckTransmitted(JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LineNo: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.SetRange("Line No.", LineNo);
        if GenJournalLine.FindFirst then begin
            GenJournalLine."Check Transmitted" := true;
            GenJournalLine.Modify;
        end;
    end;

    local procedure IsTestMode() TestMode: Boolean
    begin
        // Check to see if the test mode flag is set (usually via test codeunits by subscribing to OnIsTestMode event)
        OnIsTestMode(TestMode);
    end;

    [Scope('OnPrem')]
    procedure SetSavePath(SavePath: Text)
    begin
        // This allows us to set the path ahead of setting request parameters if we know it or need to set it ahead of time
        // e.g. for unit tests
        Path := SavePath;
    end;

    [Scope('OnPrem')]
    procedure UpdateEFTExport(var TempEFTExportWorkset: Record "EFT Export Workset" temporary)
    var
        EFTExport: Record "EFT Export";
    begin
        EFTExport.Get(TempEFTExportWorkset."Journal Template Name", TempEFTExportWorkset."Journal Batch Name",
          TempEFTExportWorkset."Line No.", TempEFTExportWorkset."Sequence No.");
        EFTExport."Posting Date" := TempEFTExportWorkset.UserSettleDate;
        EFTExport."Check Printed" := true;
        EFTExport."Check Exported" := true;
        EFTExport."Exported to Payment File" := true;
        EFTExport.Transmitted := true;
        EFTExport.Modify;
        SetGenJrnlCheckTransmitted(TempEFTExportWorkset."Journal Template Name",
          TempEFTExportWorkset."Journal Batch Name", TempEFTExportWorkset."Line No.");
    end;

    local procedure StartEFTProcess(SettlementDate: Date; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; var EFTValues: Codeunit "EFT Values")
    var
        DummyVendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        LocalBankAccount: Record "Bank Account";
        CheckDigitCheck: Boolean;
    begin
        ProcessOrderNo := 1;

        if TempEFTExportWorkset."Bank Payment Type" = TempEFTExportWorkset."Bank Payment Type"::"Electronic Payment-IAT" then begin
            TempEFTExportWorkset.SetCurrentKey("Account Type", "Account No.", "Foreign Exchange Indicator", "Foreign Exchange Ref.Indicator",
              "Foreign Exchange Reference");
            DummyLastEFTExportWorkset."Account Type" := TempEFTExportWorkset."Account Type";
            DummyLastEFTExportWorkset."Account No." := TempEFTExportWorkset."Account No.";
            DummyLastEFTExportWorkset."Foreign Exchange Indicator" := TempEFTExportWorkset."Foreign Exchange Indicator";
            DummyLastEFTExportWorkset."Foreign Exchange Ref.Indicator" := TempEFTExportWorkset."Foreign Exchange Ref.Indicator";
            DummyLastEFTExportWorkset."Foreign Exchange Reference" := TempEFTExportWorkset."Foreign Exchange Reference";
        end;

        repeat
            with TempEFTExportWorkset do begin
                Pathname := CopyStr(Path, 1, MaxStrLen(Pathname));
                UserSettleDate := SettlementDate;
                if "Bank Payment Type" = "Bank Payment Type"::"Electronic Payment-IAT" then
                    if (DummyLastEFTExportWorkset."Account Type" <> "Account Type") or
                       (DummyLastEFTExportWorkset."Account No." <> "Account No.") or
                       (DummyLastEFTExportWorkset."Foreign Exchange Indicator" <> "Foreign Exchange Indicator") or
                       (DummyLastEFTExportWorkset."Foreign Exchange Ref.Indicator" <> "Foreign Exchange Ref.Indicator") or
                       (DummyLastEFTExportWorkset."Foreign Exchange Reference" <> "Foreign Exchange Reference")
                    then begin
                        ProcessOrderNo := ProcessOrderNo + 1;
                        ProcessOrder := ProcessOrderNo;
                        DummyLastEFTExportWorkset."Account Type" := "Account Type";
                        DummyLastEFTExportWorkset."Account No." := "Account No.";
                        DummyLastEFTExportWorkset."Foreign Exchange Indicator" := "Foreign Exchange Indicator";
                        DummyLastEFTExportWorkset."Foreign Exchange Ref.Indicator" := "Foreign Exchange Ref.Indicator";
                        DummyLastEFTExportWorkset."Foreign Exchange Reference" := "Foreign Exchange Reference";
                    end else
                        ProcessOrder := ProcessOrderNo;
                if "Bank Payment Type" = "Bank Payment Type"::"Electronic Payment" then
                    ProcessOrder := 1;
                Modify;
            end;
        until TempEFTExportWorkset.Next = 0;
        Commit;

        if TempEFTExportWorkset.FindFirst then begin
            repeat
                LocalBankAccount.Get(TempEFTExportWorkset."Bank Account No.");
                CheckDigitCheck := (LocalBankAccount."Export Format" <> LocalBankAccount."Export Format"::CA);
                ExportPaymentsACH.CheckVendorTransitNum(TempEFTExportWorkset."Account No.", DummyVendor, VendorBankAccount, CheckDigitCheck);
                VendorBankAccount.TestField("Bank Account No.");
            until TempEFTExportWorkset.Next = 0;
        end;

        TempEFTExportWorkset.FindFirst;

        if ProcessOrderNo >= 1 then begin
            repeat
                TempEFTExportWorkset.SetRange(ProcessOrder, ProcessOrderNo, ProcessOrderNo);
                CheckAndStartExport(TempEFTExportWorkset, EFTValues);
                ProcessOrderNo := ProcessOrderNo - 1;
            until ProcessOrderNo = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitalChecks(BankAccountNo: Code[20]; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsTestMode(var TestMode: Boolean)
    begin
    end;
}

