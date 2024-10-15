codeunit 100 "Calc. G/L Acc. Where-Used"
{

    trigger OnRun()
    begin
    end;

    var
        GLAccWhereUsed: Record "G/L Account Where-Used" temporary;
        NextEntryNo: Integer;
        Text000: Label 'The update has been interrupted to respect the warning.';
        ShowWhereUsedQst: Label 'You cannot delete a %1 that is used in one or more setup windows.\Do you want to open the G/L Account No. Where-Used List Window?', Comment = '%1 -  Table Caption';

    procedure ShowSetupForm(GLAccWhereUsed: Record "G/L Account Where-Used")
    var
        Currency: Record Currency;
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        CustPostingGr: Record "Customer Posting Group";
        VendPostingGr: Record "Vendor Posting Group";
        JobPostingGr: Record "Job Posting Group";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        GenPostingSetup: Record "General Posting Setup";
        BankAccPostingGr: Record "Bank Account Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        FAPostingGr: Record "FA Posting Group";
        FAAlloc: Record "FA Allocation";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ServiceContractAccGr: Record "Service Contract Account Group";
        ICPartner: Record "IC Partner";
        PaymentMethod: Record "Payment Method";
        TransactionMode: Record "Transaction Mode";
    begin
        with GLAccWhereUsed do
            case "Table ID" of
                DATABASE::Currency:
                    begin
                        Currency.Code := CopyStr("Key 1", 1, MaxStrLen(Currency.Code));
                        PAGE.Run(0, Currency);
                    end;
                DATABASE::"Gen. Journal Template":
                    begin
                        GenJnlTemplate.Name := CopyStr("Key 1", 1, MaxStrLen(GenJnlTemplate.Name));
                        PAGE.Run(PAGE::"General Journal Templates", GenJnlTemplate);
                    end;
                DATABASE::"Gen. Journal Batch":
                    begin
                        GenJnlBatch."Journal Template Name" := CopyStr("Key 1", 1, MaxStrLen(GenJnlBatch."Journal Template Name"));
                        GenJnlBatch.Name := CopyStr("Key 2", 1, MaxStrLen(GenJnlBatch.Name));
                        GenJnlBatch.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
                        PAGE.Run(0, GenJnlBatch);
                    end;
                DATABASE::"Customer Posting Group":
                    begin
                        CustPostingGr.Code := CopyStr("Key 1", 1, MaxStrLen(CustPostingGr.Code));
                        PAGE.Run(0, CustPostingGr);
                    end;
                DATABASE::"Vendor Posting Group":
                    begin
                        VendPostingGr.Code := CopyStr("Key 1", 1, MaxStrLen(VendPostingGr.Code));
                        PAGE.Run(0, VendPostingGr);
                    end;
                DATABASE::"Job Posting Group":
                    begin
                        JobPostingGr.Code := CopyStr("Key 1", 1, MaxStrLen(JobPostingGr.Code));
                        PAGE.Run(0, JobPostingGr);
                    end;
                DATABASE::"Gen. Jnl. Allocation":
                    begin
                        GenJnlAlloc."Journal Template Name" := CopyStr("Key 1", 1, MaxStrLen(GenJnlAlloc."Journal Template Name"));
                        GenJnlAlloc."Journal Batch Name" := CopyStr("Key 2", 1, MaxStrLen(GenJnlAlloc."Journal Batch Name"));
                        Evaluate(GenJnlAlloc."Journal Line No.", "Key 3");
                        Evaluate(GenJnlAlloc."Line No.", "Key 4");
                        GenJnlAlloc.SetRange("Journal Template Name", GenJnlAlloc."Journal Template Name");
                        GenJnlAlloc.SetRange("Journal Batch Name", GenJnlAlloc."Journal Batch Name");
                        GenJnlAlloc.SetRange("Journal Line No.", GenJnlAlloc."Journal Line No.");
                        PAGE.Run(PAGE::Allocations, GenJnlAlloc);
                    end;
                DATABASE::"General Posting Setup":
                    begin
                        GenPostingSetup."Gen. Bus. Posting Group" :=
                          CopyStr("Key 1", 1, MaxStrLen(GenPostingSetup."Gen. Bus. Posting Group"));
                        GenPostingSetup."Gen. Prod. Posting Group" :=
                          CopyStr("Key 2", 1, MaxStrLen(GenPostingSetup."Gen. Prod. Posting Group"));
                        PAGE.Run(0, GenPostingSetup);
                    end;
                DATABASE::"Bank Account Posting Group":
                    begin
                        BankAccPostingGr.Code := CopyStr("Key 1", 1, MaxStrLen(BankAccPostingGr.Code));
                        PAGE.Run(0, BankAccPostingGr);
                    end;
                DATABASE::"VAT Posting Setup":
                    begin
                        VATPostingSetup."VAT Bus. Posting Group" :=
                          CopyStr("Key 1", 1, MaxStrLen(VATPostingSetup."VAT Bus. Posting Group"));
                        VATPostingSetup."VAT Prod. Posting Group" :=
                          CopyStr("Key 2", 1, MaxStrLen(VATPostingSetup."VAT Prod. Posting Group"));
                        PAGE.Run(0, VATPostingSetup);
                    end;
                DATABASE::"FA Posting Group":
                    begin
                        FAPostingGr.Code := CopyStr("Key 1", 1, MaxStrLen(FAPostingGr.Code));
                        PAGE.Run(PAGE::"FA Posting Group Card", FAPostingGr);
                    end;
                DATABASE::"FA Allocation":
                    begin
                        FAAlloc.Code := CopyStr("Key 1", 1, MaxStrLen(FAAlloc.Code));
                        Evaluate(FAAlloc."Allocation Type", "Key 2");
                        Evaluate(FAAlloc."Line No.", "Key 3");
                        FAAlloc.SetRange(Code, FAAlloc.Code);
                        FAAlloc.SetRange("Allocation Type", FAAlloc."Allocation Type");
                        PAGE.Run(0, FAAlloc);
                    end;
                DATABASE::"Inventory Posting Setup":
                    begin
                        InventoryPostingSetup."Location Code" := CopyStr("Key 1", 1, MaxStrLen(InventoryPostingSetup."Location Code"));
                        InventoryPostingSetup."Invt. Posting Group Code" :=
                          CopyStr("Key 2", 1, MaxStrLen(InventoryPostingSetup."Invt. Posting Group Code"));
                        PAGE.Run(PAGE::"Inventory Posting Setup", InventoryPostingSetup);
                    end;
                DATABASE::"Service Contract Account Group":
                    begin
                        ServiceContractAccGr.Code := CopyStr("Key 1", 1, MaxStrLen(ServiceContractAccGr.Code));
                        PAGE.Run(0, ServiceContractAccGr);
                    end;
                DATABASE::"IC Partner":
                    begin
                        ICPartner.Code := CopyStr("Key 1", 1, MaxStrLen(ICPartner.Code));
                        PAGE.Run(0, ICPartner);
                    end;
                DATABASE::"Payment Method":
                    begin
                        PaymentMethod.Code := CopyStr("Key 1", 1, MaxStrLen(PaymentMethod.Code));
                        PAGE.Run(0, PaymentMethod);
                    end;
                DATABASE::"Sales & Receivables Setup":
                    PAGE.Run(PAGE::"Sales & Receivables Setup");
                DATABASE::"Purchases & Payables Setup":
                    PAGE.Run(PAGE::"Purchases & Payables Setup");
                DATABASE::"Transaction Mode":
                    begin
                        Evaluate(TransactionMode."Account Type", "Key 1");
                        TransactionMode.Code :=
                          CopyStr("Key 2", 1, MaxStrLen(TransactionMode.Code));
                        PAGE.Run(0, TransactionMode);
                    end;
                else
                    OnShowExtensionPage(GLAccWhereUsed);
            end;
    end;

    procedure DeleteGLNo(GLAccNo: Code[20]): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        GLSetup.Get();
        if GLSetup."Check G/L Account Usage" then begin
            CheckPostingGroups(GLAccNo);
            if GLAccWhereUsed.FindFirst() then begin
                Commit();
                if ConfirmManagement.GetResponse(StrSubstNo(ShowWhereUsedQst, GLAcc.TableCaption), true) then
                    ShowGLAccWhereUsed;
                Error(Text000);
            end;
        end;
        exit(true);
    end;

    procedure CheckGLAcc(GLAccNo: Code[20])
    begin
        CheckPostingGroups(GLAccNo);
        ShowGLAccWhereUsed;
    end;

    local procedure ShowGLAccWhereUsed()
    begin
        OnBeforeShowGLAccWhereUsed(GLAccWhereUsed);

        GLAccWhereUsed.SetCurrentKey("Table Name");
        PAGE.RunModal(0, GLAccWhereUsed);
    end;

    procedure InsertGroupForRecord(var TempGLAccountWhereUsed: Record "G/L Account Where-Used" temporary; TableID: Integer; TableCaption: Text[80]; GLAccNo: Code[20]; GLAccNo2: Code[20]; FieldCaption: Text[80]; "Key": array[8] of Text[80])
    begin
        TempGLAccountWhereUsed."Table ID" := TableID;
        TempGLAccountWhereUsed."Table Name" := TableCaption;
        GLAccWhereUsed.Copy(TempGLAccountWhereUsed, true);
        InsertGroup(GLAccNo, GLAccNo2, FieldCaption, Key);
    end;

    local procedure InsertGroup(GLAccNo: Code[20]; GLAccNo2: Code[20]; FieldCaption: Text[80]; "Key": array[8] of Text[80])
    begin
        if GLAccNo = GLAccNo2 then begin
            if NextEntryNo = 0 then
                NextEntryNo := GLAccWhereUsed.GetLastEntryNo() + 1;

            GLAccWhereUsed."Field Name" := FieldCaption;
            if Key[1] <> '' then
                GLAccWhereUsed.Line := Key[1] + '=' + Key[4]
            else
                GLAccWhereUsed.Line := '';
            if Key[2] <> '' then
                GLAccWhereUsed.Line := GLAccWhereUsed.Line + ', ' + Key[2] + '=' + Key[5];
            if Key[3] <> '' then
                GLAccWhereUsed.Line := GLAccWhereUsed.Line + ', ' + Key[3] + '=' + Key[6];
            if Key[7] <> '' then
                GLAccWhereUsed.Line := GLAccWhereUsed.Line + ', ' + Key[7] + '=' + Key[8];
            GLAccWhereUsed."Entry No." := NextEntryNo;
            GLAccWhereUsed."Key 1" := CopyStr(Key[4], 1, MaxStrLen(GLAccWhereUsed."Key 1"));
            GLAccWhereUsed."Key 2" := CopyStr(Key[5], 1, MaxStrLen(GLAccWhereUsed."Key 2"));
            GLAccWhereUsed."Key 3" := CopyStr(Key[6], 1, MaxStrLen(GLAccWhereUsed."Key 3"));
            GLAccWhereUsed."Key 4" := CopyStr(Key[8], 1, MaxStrLen(GLAccWhereUsed."Key 4"));
            NextEntryNo := NextEntryNo + 1;
            GLAccWhereUsed.Insert();
        end;
    end;

    local procedure InsertGroupFromRecRef(var RecRef: RecordRef; FieldCaption: Text[80])
    var
        KeyRef: KeyRef;
        FieldRef: FieldRef;
        KeyFieldCount: Integer;
        FieldCaptionAndValue: Text;
    begin
        if NextEntryNo = 0 then
            NextEntryNo := GLAccWhereUsed.GetLastEntryNo() + 1;

        GLAccWhereUsed."Entry No." := NextEntryNo;
        GLAccWhereUsed."Field Name" := FieldCaption;
        GLAccWhereUsed.Line := '';
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            FieldCaptionAndValue := StrSubstNo('%1=%2', FieldRef.Caption, FieldRef.Value);
            if GLAccWhereUsed.Line = '' then
                GLAccWhereUsed.Line := CopyStr(FieldCaptionAndValue, 1, MaxStrLen(GLAccWhereUsed.Line))
            else
                GLAccWhereUsed.Line :=
                  CopyStr(GLAccWhereUsed.Line + ', ' + FieldCaptionAndValue, 1, MaxStrLen(GLAccWhereUsed.Line));

            case KeyFieldCount of
                1:
                    GLAccWhereUsed."Key 1" := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(GLAccWhereUsed."Key 1"));
                2:
                    GLAccWhereUsed."Key 2" := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(GLAccWhereUsed."Key 2"));
                3:
                    GLAccWhereUsed."Key 3" := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(GLAccWhereUsed."Key 3"));
                4:
                    GLAccWhereUsed."Key 4" := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(GLAccWhereUsed."Key 4"));
            end;
        end;
        NextEntryNo := NextEntryNo + 1;
        GLAccWhereUsed.Insert();
    end;

    procedure CheckPostingGroups(GLAccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
        TableBuffer: Record "Integer" temporary;
    begin
        NextEntryNo := 0;
        Clear(GLAccWhereUsed);
        GLAccWhereUsed.DeleteAll();
        GLAcc.Get(GLAccNo);
        GLAccWhereUsed."G/L Account No." := GLAccNo;
        GLAccWhereUsed."G/L Account Name" := GLAcc.Name;

        if FillTableBuffer(TableBuffer) then
            repeat
                CheckTable(GLAccNo, TableBuffer.Number);
            until TableBuffer.Next() = 0;

        OnAfterCheckPostingGroups(GLAccWhereUsed, GLAccNo);
    end;

    local procedure FillTableBuffer(var TableBuffer: Record "Integer"): Boolean
    begin
        AddTable(TableBuffer, DATABASE::Currency);
        AddTable(TableBuffer, DATABASE::"Gen. Journal Template");
        AddTable(TableBuffer, DATABASE::"Gen. Journal Batch");
        AddTable(TableBuffer, DATABASE::"Customer Posting Group");
        AddTable(TableBuffer, DATABASE::"Vendor Posting Group");
        AddTable(TableBuffer, DATABASE::"Job Posting Group");
        AddTable(TableBuffer, DATABASE::"Gen. Jnl. Allocation");
        AddTable(TableBuffer, DATABASE::"General Posting Setup");
        AddTable(TableBuffer, DATABASE::"Bank Account Posting Group");
        AddTable(TableBuffer, DATABASE::"VAT Posting Setup");
        AddTable(TableBuffer, DATABASE::"FA Posting Group");
        AddTable(TableBuffer, DATABASE::"FA Allocation");
        AddTable(TableBuffer, DATABASE::"Inventory Posting Setup");
        AddTable(TableBuffer, DATABASE::"Service Contract Account Group");
        AddTable(TableBuffer, DATABASE::"IC Partner");
        AddTable(TableBuffer, DATABASE::"Payment Method");
        AddTable(TableBuffer, DATABASE::"Sales & Receivables Setup");
        AddTable(TableBuffer, DATABASE::"Purchases & Payables Setup");
        AddTable(TableBuffer, DATABASE::"Employee Posting Group");
        AddTable(TableBuffer, DATABASE::"Business Unit");
        AddTable(TableBuffer, DATABASE::"Cash Flow Setup");

        AddCountryTables(TableBuffer);

        OnAfterFillTableBuffer(TableBuffer);

        exit(TableBuffer.FindSet);
    end;

    procedure AddTable(var TableBuffer: Record "Integer"; TableID: Integer)
    begin
        if not TableBuffer.Get(TableID) then begin
            TableBuffer.Number := TableID;
            TableBuffer.Insert();
        end;
    end;

    local procedure AddCountryTables(var TableBuffer: Record "Integer")
    begin
        TableBuffer.Reset();
        AddTable(TableBuffer, DATABASE::"Transaction Mode");
    end;

    local procedure CheckTable(GLAccNo: Code[20]; TableID: Integer)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
        "Field": Record "Field";
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        GLAccWhereUsed.Init();
        GLAccWhereUsed."Table ID" := TableID;
        GLAccWhereUsed."Table Name" := RecRef.Caption;

        TableRelationsMetadata.SetRange("Table ID", TableID);
        TableRelationsMetadata.SetRange("Related Table ID", DATABASE::"G/L Account");
        if TableRelationsMetadata.FindSet() then
            repeat
                Field.Get(TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No.");
                if (Field.Class = Field.Class::Normal) and (Field.ObsoleteState <> Field.ObsoleteState::Removed) then
                    CheckField(RecRef, TableRelationsMetadata, GLAccNo);
            until TableRelationsMetadata.Next() = 0;
    end;

    local procedure CheckField(var RecRef: RecordRef; TableRelationsMetadata: Record "Table Relations Metadata"; GLAccNo: Code[20])
    var
        FieldRef: FieldRef;
    begin
        RecRef.Reset();
        FieldRef := RecRef.Field(TableRelationsMetadata."Field No.");
        FieldRef.SetRange(GLAccNo);
        SetConditionFilter(RecRef, TableRelationsMetadata);
        if RecRef.FindSet() then
            repeat
                InsertGroupFromRecRef(RecRef, FieldRef.Caption);
            until RecRef.Next() = 0;
    end;

    local procedure SetConditionFilter(var RecRef: RecordRef; TableRelationsMetadata: Record "Table Relations Metadata")
    var
        FieldRef: FieldRef;
    begin
        if TableRelationsMetadata."Condition Field No." <> 0 then begin
            FieldRef := RecRef.Field(TableRelationsMetadata."Condition Field No.");
            FieldRef.SetFilter(TableRelationsMetadata."Condition Value");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowExtensionPage(GLAccountWhereUsed: Record "G/L Account Where-Used")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPostingGroups(var TempGLAccountWhereUsed: Record "G/L Account Where-Used" temporary; GLAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillTableBuffer(var TableBuffer: Record "Integer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowGLAccWhereUsed(var GLAccountWhereUsed: Record "G/L Account Where-Used")
    begin
    end;
}

