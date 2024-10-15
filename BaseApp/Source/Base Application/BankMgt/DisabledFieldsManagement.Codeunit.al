codeunit 31449 "Disabled Fields Management"
{
    Access = Internal;

    var
        DisabledFieldErr: Label 'will be removed and should not be used';

    [EventSubscriber(ObjectType::Table, Database::"Bank Pmt. Appl. Rule", 'OnBeforeInsertEvent', '', false, false)]
    local procedure DisableInsertBankPmtApplRuleWithCode(var Rec: Record "Bank Pmt. Appl. Rule")
    begin
        CheckBankPmtApplRuleCode(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Pmt. Appl. Rule", 'OnBeforeModifyEvent', '', false, false)]
    local procedure DisableModifyBankPmtApplRuleWithCode(var Rec: Record "Bank Pmt. Appl. Rule")
    begin
        CheckBankPmtApplRuleCode(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Pmt. Appl. Rule", 'OnBeforeRenameEvent', '', false, false)]
    local procedure DisableRenameBankPmtApplRuleWithCode(var Rec: Record "Bank Pmt. Appl. Rule")
    begin
        CheckBankPmtApplRuleCode(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Pmt. Appl. Rule", 'OnBeforeValidateEvent', 'Bank Pmt. Appl. Rule Code', false, false)]
    local procedure DisableBankPmtApplRuleCodeValidation(var Rec: Record "Bank Pmt. Appl. Rule")
    begin
        CheckBankPmtApplRuleCode(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Text-to-Account Mapping", 'OnBeforeInsertEvent', '', false, false)]
    local procedure DisableInsertTexttoAccountMappingWithCode(var Rec: Record "Text-to-Account Mapping")
    begin
        CheckTexttoAccountMappingCode(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Text-to-Account Mapping", 'OnBeforeModifyEvent', '', false, false)]
    local procedure DisableModifyTexttoAccountMappingWithCode(var Rec: Record "Text-to-Account Mapping")
    begin
        CheckTexttoAccountMappingCode(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Text-to-Account Mapping", 'OnBeforeRenameEvent', '', false, false)]
    local procedure DisableRenameTexttoAccountMappingWithCode(var Rec: Record "Text-to-Account Mapping")
    begin
        CheckTexttoAccountMappingCode(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Text-to-Account Mapping", 'OnBeforeValidateEvent', 'Text-to-Account Mapping Code', false, false)]
    local procedure DisableTexttoAccountMappingCodeValidation(var Rec: Record "Text-to-Account Mapping")
    begin
        CheckTexttoAccountMappingCode(Rec);
    end;

    local procedure CheckBankPmtApplRuleCode(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule")
    begin
        if BankPmtApplRule."Bank Pmt. Appl. Rule Code" <> '' then
            BankPmtApplRule.FieldError("Bank Pmt. Appl. Rule Code", DisabledFieldErr);
    end;

    local procedure CheckTexttoAccountMappingCode(var TexttoAccountMapping: Record "Text-to-Account Mapping")
    begin
        if TexttoAccountMapping."Text-to-Account Mapping Code" <> '' then
            TexttoAccountMapping.FieldError("Text-to-Account Mapping Code", DisabledFieldErr);
    end;
}