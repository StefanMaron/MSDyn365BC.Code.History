codeunit 431 "IC Outbox Export"
{
    TableNo = "IC Outbox Transaction";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(Text003, true) then
            exit;
        RunOutboxTransactions(Rec);
    end;

    var
        Text001: Label 'Intercompany transactions from %1.';
        Text002: Label 'Attached to this mail is an xml file containing one or more intercompany transactions from %1 (%2 %3).';
        Text003: Label 'Do you want to complete line actions?';
        CompanyInfo: Record "Company Information";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        FileMgt: Codeunit "File Management";
        ClientTypeManagement: Codeunit "Client Type Management";
        FolderPathMissingErr: Label 'Folder Path must have a value in IC Partner: Code=%1. It cannot be zero or empty.', Comment = '%1=Intercompany Code';
        EmailAddressMissingErr: Label 'Email Address must have a value in IC Partner: Code=%1. It cannot be zero or empty.', Comment = '%1=Intercompany Code';

    [Scope('OnPrem')]
    procedure RunOutboxTransactions(var ICOutboxTransaction: Record "IC Outbox Transaction")
    var
        CopyICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        CompanyInfo.Get();
        CopyICOutboxTransaction.Copy(ICOutboxTransaction);
        CopyICOutboxTransaction.SetRange("Line Action",
          CopyICOutboxTransaction."Line Action"::"Send to IC Partner");
        UpdateICStatus(CopyICOutboxTransaction);
        OnRunOutboxTransactionsOnBeforeSend(CopyICOutboxTransaction);
        SendToExternalPartner(CopyICOutboxTransaction);
        SendToInternalPartner(CopyICOutboxTransaction);
        CopyICOutboxTransaction.SetRange("Line Action",
          CopyICOutboxTransaction."Line Action"::"Return to Inbox");
        ReturnToInbox(CopyICOutboxTransaction);
        CancelTrans(CopyICOutboxTransaction);
    end;

    local procedure ModifyAndRunOutboxTransactionNo(ICOutboxTransactionNo: Integer)
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        ICOutboxTransaction.SetRange("Transaction No.", ICOutboxTransactionNo);
        if ICOutboxTransaction.FindFirst then begin
            ICOutboxTransaction."Line Action" := ICOutboxTransaction."Line Action"::"Send to IC Partner";
            ICOutboxTransaction.Modify();
            RunOutboxTransactions(ICOutboxTransaction);
        end;
    end;

    [Scope('OnPrem')]
    procedure ProcessAutoSendOutboxTransactionNo(ICOutboxTransactionNo: Integer)
    begin
        CompanyInfo.Get();
        if CompanyInfo."Auto. Send Transactions" then
            ModifyAndRunOutboxTransactionNo(ICOutboxTransactionNo);
    end;

    local procedure SendToExternalPartner(var ICOutboxTrans: Record "IC Outbox Transaction")
    var
        ICPartner: Record "IC Partner";
        EmailItem: Record "Email Item";
        MailHandler: Codeunit Mail;
        DocumentMailing: Codeunit "Document-Mailing";
        ICOutboxExportXML: XMLport "IC Outbox Imp/Exp";
        EmailDialog: Page "Email Dialog";
        OFile: File;
        FileName: Text;
        ICPartnerFilter: Text[1024];
        i: Integer;
        ToName: Text[100];
        CcName: Text[100];
        OutFileName: Text;
    begin
        ICPartner.SetFilter("Inbox Type", '<>%1', ICPartner."Inbox Type"::Database);
        ICPartnerFilter := ICOutboxTrans.GetFilter("IC Partner Code");
        if ICPartnerFilter <> '' then
            ICPartner.SetFilter(Code, ICPartnerFilter);
        if ICPartner.Find('-') then
            repeat
                ICOutboxTrans.SetRange("IC Partner Code", ICPartner.Code);
                if ICOutboxTrans.Find('-') then begin
                    if (ICPartner."Inbox Type" = ICPartner."Inbox Type"::"File Location") and not IsWebClient() then begin
                        ICPartner.TestField(Blocked, false);
                        if ICPartner."Inbox Details" = '' then
                            Error(FolderPathMissingErr, ICPartner.Code);
                        i := 1;
                        while i <> 0 do begin
                            FileName :=
                              StrSubstNo('%1\%2_%3_%4.xml', ICPartner."Inbox Details", ICPartner.Code, ICOutboxTrans."Transaction No.", i);
                            if Exists(FileName) then
                                i := i + 1
                            else
                                i := 0;
                        end;
                    end else begin
                        OFile.CreateTempFile;
                        FileName := StrSubstNo('%1.%2.xml', OFile.Name, ICPartner.Code);
                        OFile.Close;
                    end;

                    ExportOutboxTransaction(ICOutboxTrans, FileName);

                    if IsWebClient() then begin
                        OutFileName := StrSubstNo('%1_%2.xml', ICPartner.Code, ICOutboxTrans."Transaction No.");
                        Download(FileName, '', '', '', OutFileName)
                    end else
                        FileName := FileMgt.DownloadTempFile(FileName);

                    if ICPartner."Inbox Type" = ICPartner."Inbox Type"::Email then begin
                        ICPartner.TestField(Blocked, false);
                        if ICPartner."Inbox Details" = '' then
                            Error(EmailAddressMissingErr, ICPartner.Code);
                        ToName := ICPartner."Inbox Details";
                        if StrPos(ToName, ';') > 0 then begin
                            CcName := CopyStr(ToName, StrPos(ToName, ';') + 1);
                            ToName := CopyStr(ToName, 1, StrPos(ToName, ';') - 1);
                            if StrPos(CcName, ';') > 0 then
                                CcName := CopyStr(CcName, 1, StrPos(CcName, ';') - 1);
                        end;

                        if IsWebClient() then begin
                            CreateEmailItem(
                              EmailItem,
                              ICPartner."Inbox Details",
                              StrSubstNo('%1 %2', ICOutboxTrans."Document Type", ICOutboxTrans."Document No."),
                              Format(FileName, -MaxStrLen(EmailItem."Attachment File Path")),
                              StrSubstNo('%1.xml', ICPartner.Code));
                            Commit();

                            EmailDialog.SetValues(EmailItem, false, true);
                            if EmailDialog.RunModal = ACTION::Cancel then
                                exit;

                            EmailDialog.GetRecord(EmailItem);
                            DocumentMailing.EmailFile(
                              EmailItem."Attachment File Path",
                              EmailItem."Attachment Name",
                              '',
                              ICOutboxTrans."Document No.",
                              EmailItem."Send to",
                              EmailItem.Subject,
                              true,
                              5); // S.Test
                        end else
                            MailHandler.NewMessage(
                              ToName, CcName, '',
                              StrSubstNo(Text001, CompanyInfo.Name),
                              StrSubstNo(
                                Text002, CompanyInfo.Name, CompanyInfo.FieldCaption("IC Partner Code"), CompanyInfo."IC Partner Code"),
                              FileName, false);
                    end;
                    ICOutboxTrans.Find('-');
                    repeat
                        ICInboxOutboxMgt.MoveOutboxTransToHandledOutbox(ICOutboxTrans);
                    until ICOutboxTrans.Next = 0;
                end;
            until ICPartner.Next = 0;
        ICOutboxTrans.SetRange("IC Partner Code");
        if ICPartnerFilter <> '' then
            ICOutboxTrans.SetFilter("IC Partner Code", ICPartnerFilter);
    end;

    procedure SendToInternalPartner(var ICOutboxTrans: Record "IC Outbox Transaction")
    var
        Company: Record Company;
        ICPartner: Record "IC Partner";
        MoveICTransToPartnerCompany: Report "Move IC Trans. to Partner Comp";
        IsHandled: Boolean;
    begin
        if ICOutboxTrans.Find('-') then
            repeat
                ICPartner.Get(ICOutboxTrans."IC Partner Code");
                ICPartner.TestField(Blocked, false);
                if ICPartner."Inbox Type" = ICPartner."Inbox Type"::Database then begin
                    ICPartner.TestField("Inbox Details");
                    Company.Get(ICPartner."Inbox Details");
                    ICOutboxTrans.SetRange("Transaction No.", ICOutboxTrans."Transaction No.");
                    IsHandled := false;
                    OnSendToInternalPartnerOnBeforeMoveICTransToPartnerCompany(ICOutboxTrans, IsHandled);
                    if not IsHandled then begin
                        MoveICTransToPartnerCompany.SetTableView(ICOutboxTrans);
                        MoveICTransToPartnerCompany.UseRequestPage := false;
                        MoveICTransToPartnerCompany.Run;
                    end;
                    ICOutboxTrans.SetRange("Transaction No.");
                    if ICOutboxTrans."Line Action" = ICOutboxTrans."Line Action"::"Send to IC Partner" then
                        ICInboxOutboxMgt.MoveOutboxTransToHandledOutbox(ICOutboxTrans);
                end;
            until ICOutboxTrans.Next = 0;
    end;

    local procedure ReturnToInbox(var ICOutboxTrans: Record "IC Outbox Transaction")
    var
        ICPartner: Record "IC Partner";
        MoveICTransToPartnerCompany: Report "Move IC Trans. to Partner Comp";
    begin
        if ICOutboxTrans.Find('-') then
            repeat
                if ICPartner.Get(ICOutboxTrans."IC Partner Code") then
                    ICPartner.TestField(Blocked, false);
                MoveICTransToPartnerCompany.RecreateInboxTrans(ICOutboxTrans);
                ICOutboxTrans.Delete(true);
            until ICOutboxTrans.Next = 0;
    end;

    local procedure CancelTrans(var ICOutboxTrans: Record "IC Outbox Transaction")
    begin
        ICOutboxTrans.SetRange("Line Action", ICOutboxTrans."Line Action"::Cancel);
        if ICOutboxTrans.Find('-') then
            repeat
                ICInboxOutboxMgt.MoveOutboxTransToHandledOutbox(ICOutboxTrans);
            until ICOutboxTrans.Next = 0;
    end;

    local procedure UpdateICStatus(var ICOutboxTransaction: Record "IC Outbox Transaction")
    var
        PurchHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        if ICOutboxTransaction.FindSet then
            repeat
                if ICOutboxTransaction."Source Type" = ICOutboxTransaction."Source Type"::"Purchase Document" then
                    case ICOutboxTransaction."Document Type" of
                        ICOutboxTransaction."Document Type"::Order:
                            if PurchHeader.Get(PurchHeader."Document Type"::Order, ICOutboxTransaction."Document No.") then begin
                                PurchHeader.Validate("IC Status", PurchHeader."IC Status"::Sent);
                                PurchHeader.Modify();
                            end;
                        ICOutboxTransaction."Document Type"::"Return Order":
                            if PurchHeader.Get(PurchHeader."Document Type"::"Return Order", ICOutboxTransaction."Document No.") then begin
                                PurchHeader.Validate("IC Status", PurchHeader."IC Status"::Sent);
                                PurchHeader.Modify();
                            end;
                    end
                else
                    if ICOutboxTransaction."Source Type" = ICOutboxTransaction."Source Type"::"Sales Document" then
                        case ICOutboxTransaction."Document Type" of
                            ICOutboxTransaction."Document Type"::Order:
                                if SalesHeader.Get(SalesHeader."Document Type"::Order, ICOutboxTransaction."Document No.") then begin
                                    SalesHeader.Validate("IC Status", SalesHeader."IC Status"::Sent);
                                    SalesHeader.Modify();
                                end;
                            ICOutboxTransaction."Document Type"::"Return Order":
                                if SalesHeader.Get(SalesHeader."Document Type"::"Return Order", ICOutboxTransaction."Document No.") then begin
                                    SalesHeader.Validate("IC Status", SalesHeader."IC Status"::Sent);
                                    SalesHeader.Modify();
                                end;
                        end;
            until ICOutboxTransaction.Next = 0
    end;

    local procedure CreateEmailItem(var EmailItem: Record "Email Item"; SendTo: Text[250]; Subject: Text[250]; AttachmentFilePath: Text[250]; AttachmentFileName: Text[250])
    begin
        EmailItem.Initialize;
        EmailItem.Insert();
        EmailItem."Send to" := SendTo;
        EmailItem.Subject := Subject;

        if AttachmentFilePath <> '' then begin
            EmailItem."Attachment File Path" := AttachmentFilePath;
            EmailItem."Attachment Name" := AttachmentFileName;
        end;
        EmailItem.Modify(true);
    end;

    local procedure ExportOutboxTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction"; var FileName: Text)
    var
        ICOutboxImpExpXML: XMLport "IC Outbox Imp/Exp";
        OFile: File;
        OStr: OutStream;
        IsHandled: Boolean;
    begin
        OFile.Create(FileName);
        OFile.CreateOutStream(OStr);

        IsHandled := false;
        OnBeforeExportOutboxTransaction(ICOutboxTransaction, OStr, IsHandled);
        if IsHandled then
            exit;

        ICOutboxImpExpXML.SetICOutboxTrans(ICOutboxTransaction);
        ICOutboxImpExpXML.SetDestination(OStr);
        ICOutboxImpExpXML.Export;

        OFile.Close;
        Clear(OStr);
        Clear(ICOutboxImpExpXML);
    end;

    local procedure IsWebClient(): Boolean
    begin
        exit(ClientTypeManagement.GetCurrentClientType in [CLIENTTYPE::Web, CLIENTTYPE::Phone, CLIENTTYPE::Tablet, CLIENTTYPE::Desktop]);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportOutboxTransaction(ICOutboxTransaction: Record "IC Outbox Transaction"; OutStr: OutStream; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOutboxTransactionsOnBeforeSend(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendToInternalPartnerOnBeforeMoveICTransToPartnerCompany(var ICOutboxTransaction: Record "IC Outbox Transaction"; var IsHandled: Boolean)
    begin
    end;
}

