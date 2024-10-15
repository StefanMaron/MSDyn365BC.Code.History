codeunit 20347 "Tax Subledger Posting Handler"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Tax Document GL Posting", 'OnAfterPrepareTaxTransaction', '', false, false)]
    local procedure OnAfterPrepareTaxTransaction(
        var TaxPostingBuffer: Record "Transaction Posting Buffer";
        var TempSymbols: Record "Script Symbol Value" Temporary)
    var
        UseCase: Record "Tax Use Case";
        TaxJnlMgmt: Codeunit "Tax Posting Buffer Mgmt.";
        RecID: RecordId;
        NewCaseID: Guid;
        GroupingType: Option "Component","Line / Component";
        Record: Variant;
    begin
        if TaxPostingBuffer.FindSet() then
            repeat
                RecID := TaxPostingBuffer."Tax Record ID";
                if GetPostingUseCaseID(
                    TaxPostingBuffer."Case ID",
                    TaxPostingBuffer."Component ID",
                    GroupingType::"Line / Component", NewCaseID)
                then begin
                    UseCase.Get(NewCaseID);
                    Record := RecID;
                    SymbolStore.SetDefaultSymbolValue(
                        TempSymbols,
                        TempSymbols.Type::"Posting Field",
                        "Posting Field Symbol"::"Gen. Bus. Posting Group".AsInteger(),
                        TaxPostingBuffer."Gen. Bus. Posting Group",
                        "Symbol Data Type"::STRING);

                    SymbolStore.SetDefaultSymbolValue(
                        TempSymbols,
                        TempSymbols.Type::"Posting Field",
                        "Posting Field Symbol"::"Gen. Prod. Posting Group".AsInteger(),
                        TaxPostingBuffer."Gen. Prod. Posting Group",
                        "Symbol Data Type"::STRING);

                    SymbolStore.SetDefaultSymbolValue(
                        TempSymbols,
                        TempSymbols.Type::"Posting Field",
                        "Posting Field Symbol"::"Dimension Set ID".AsInteger(),
                        TaxPostingBuffer."Dimension Set ID",
                        "Symbol Data Type"::NUMBER);

                    SymbolStore.SetDefaultSymbolValue(
                        TempSymbols,
                        TempSymbols.Type::"Posting Field",
                        "Posting Field Symbol"::"Posted Document No.".AsInteger(),
                        TaxPostingBuffer."Posted Document No.",
                        "Symbol Data Type"::STRING);

                    SymbolStore.SetDefaultSymbolValue(
                        TempSymbols,
                        TempSymbols.Type::"Posting Field",
                        "Posting Field Symbol"::"Posted Document Line No.".AsInteger(),
                        TaxPostingBuffer."Posted Document Line No.",
                        "Symbol Data Type"::NUMBER);

                    SymbolStore.SetDefaultSymbolValue(
                        TempSymbols,
                        TempSymbols.Type::"Posting Field",
                        "Posting Field Symbol"::"G/L Entry No.".AsInteger(),
                        TaxPostingBuffer."G/L Entry No",
                        "Symbol Data Type"::NUMBER);

                    SymbolStore.SetDefaultSymbolValue(
                        TempSymbols,
                        TempSymbols.Type::"Posting Field",
                        "Posting Field Symbol"::"G/L Entry Transaction No.".AsInteger(),
                        TaxPostingBuffer."G/L Entry Transaction No.",
                        "Symbol Data Type"::NUMBER);

                    TaxPostingExecution.ExecutePosting(
                        UseCase,
                        Record,
                        TempSymbols,
                        TaxPostingBuffer."Component ID",
                        GroupingType::"Line / Component");
                end;
            until TaxPostingBuffer.Next() = 0;
    end;

    local procedure GetPostingUseCaseID(
        CaseID: Guid;
        ComponentID: Integer;
        ExpectedType: Option;
        var NewCaseId: Guid): Boolean
    var
        UseCase: Record "Tax Use Case";
        TaxPostingSetup: Record "Tax Posting Setup";
        SwitchCase: Record "Switch Case";
        InsertRecord: Record "Tax Insert Record";
    begin
        UseCase.Get(CaseID);
        if UseCase."Posting Table ID" <> 0 then begin
            TaxPostingSetup.Reset();
            TaxPostingSetup.SetRange("Case ID", UseCase.ID);
            TaxPostingSetup.SetRange("Component ID", ComponentID);
            if TaxPostingSetup.FindFirst() then begin
                SwitchCase.SetRange("Switch Statement ID", TaxPostingSetup."Switch Statement ID");
                if SwitchCase.FindSet() then
                    repeat
                        if InsertRecord.Get(
                            SwitchCase."Case ID",
                            UseCase."Posting Script ID",
                            SwitchCase."Action ID")
                        then
                            if InsertRecord."Sub Ledger Group By" = ExpectedType then begin
                                NewCaseId := UseCase.ID;
                                exit(true);
                            end;
                    until SwitchCase.Next() = 0;
            end;

            exit(false);
        end else
            if not IsNullGuid(UseCase."Parent Use Case ID") then
                exit(GetPostingUseCaseID(
                    UseCase."Parent Use Case ID",
                    ComponentID,
                    ExpectedType,
                    NewCaseId))
            else
                exit(false);
    end;

    var
        TaxPostingExecution: Codeunit "Tax Posting Execution";
        TaxAttributeMgmt: Codeunit "Tax Attribute Management";
        SymbolStore: Codeunit "Script Symbol Store";
        DataTypeMgmt: Codeunit "Use Case Data Type Mgmt.";
        EmptyGuid: Guid;
}