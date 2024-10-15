codeunit 20232 "Tax Type Object Helper"
{
    procedure SearchTaxTypeTable(var TableID: Integer; var TableName: Text[30]; TaxType: Code[20]; IsTransactionTable: Boolean)
    var
        TaxEntity: Record "Tax Entity";
        TmpObjectID: Integer;
        IsInteger: Boolean;
    begin
        if TableName = '' then begin
            TableID := 0;
            Exit;
        end;

        IsInteger := Evaluate(TmpObjectID, TableName, 2);

        TaxEntity.Reset();
        TaxEntity.SetRange("Tax Type", TaxType);
        if IsTransactionTable then
            TaxEntity.SetRange("Entity Type", TaxEntity."Entity Type"::Transaction);
        if IsInteger then
            TaxEntity.SetRange("Table ID", TmpObjectID)
        else
            TaxEntity.SetFilter("Table Name", '%1', '@' + TableName + '*');

        if TaxEntity.FindFirst() then begin
            TableID := TaxEntity."Table ID";
            TableName := TaxEntity."Table Name";
        end else
            Error(InvalidTableNoErr, TableName);
    end;

    procedure SearchTaxOptionAttribute(TaxType: Code[20]; AttributeID: Integer; var AttributeValue: Text[250]);
    var
        TaxAttributeValue: Record "Tax Attribute Value";
        InvalidAttributeValueErr: Label 'You cannot enter ''%1'' in Attribute Value.', Comment = '%1 = Attribute Value';
    begin
        if AttributeID = 0 then
            Exit;

        if StrLen(AttributeValue) = 0 then
            exit;

        TaxAttributeValue.Reset();
        TaxAttributeValue.SetRange("Attribute ID", AttributeID);
        TaxAttributeValue.SetFilter(Value, '%1', '@' + AttributeValue + '*');

        if TaxAttributeValue.FindFirst() then
            AttributeValue := TaxAttributeValue.Value
        else
            Error(InvalidAttributeValueErr, AttributeValue);
    end;

    procedure OpenTaxTypeTableLookup(var TableID: Integer; var TableName: Text[30]; SearchText: Text; TaxType: Code[20]);
    var
        TaxEntity: Record "Tax Entity";
    begin
        TaxEntity.Reset();
        TaxEntity.SetRange("Tax Type", TaxType);
        if TableID <> 0 then begin
            TaxEntity."Table ID" := TableID;
            TaxEntity.Find('<>=');
        end else
            if SearchText <> '' then begin
                TaxEntity."Table Name" := CopyStr(SearchText, 1, 30);
                TaxEntity.Find('<>=');
            end;

        if Page.RunModal(Page::"Tax Entities", TaxEntity) = ACTION::LookupOK then begin
            TableID := TaxEntity."Table ID";
            TableName := TaxEntity."Table Name";
        end;
    end;

    procedure OpenTaxTypeTransactionTableLookup(var TableID: Integer; var TableName: Text[30]; SearchText: Text; TaxType: Code[20]);
    var
        TaxEntity: Record "Tax Entity";
    begin
        TaxEntity.Reset();
        TaxEntity.SetRange("Tax Type", TaxType);
        TaxEntity.SetRange("Entity Type", TaxEntity."Entity Type"::Transaction);
        if TableID <> 0 then begin
            TaxEntity."Table ID" := TableID;
            TaxEntity.Find('<>=');
        end else
            if SearchText <> '' then begin
                TaxEntity."Table Name" := CopyStr(SearchText, 1, 30);
                TaxEntity.Find('<>=');
            end;

        if Page.RunModal(Page::"Tax Entities", TaxEntity) = ACTION::LookupOK then begin
            TableID := TaxEntity."Table ID";
            TableName := TaxEntity."Table Name";
        end;
    end;

    procedure CreateComponentFormula(TaxTypeCode: Code[20]; ID: Integer): Guid;
    var
        TaxComponentFormula: Record "Tax Component Formula";
    begin
        TaxComponentFormula.Init();
        TaxComponentFormula."Tax Type" := TaxTypeCode;
        TaxComponentFormula.ID := CreateGuid();
        TaxComponentFormula."Component ID" := ID;
        TaxComponentFormula.Insert(true);

        Exit(TaxComponentFormula.ID);
    end;

    procedure DeleteComponentFormula(ID: Guid);
    var
        TaxComponentFormula: Record "Tax Component Formula";
    begin
        TaxComponentFormula.Get(ID);
        TaxComponentFormula.Delete(true);
    end;

    procedure OpenComponentFormulaDialog(ID: Guid);
    var
        TaxComponentFormula: Record "Tax Component Formula";
        TaxComponentFormulaDialog: Page "Tax Component Formula Dialog";
    begin
        TaxComponentFormula.Get(ID);
        TaxComponentFormulaDialog.SetCurrentRecord(TaxComponentFormula);
        TaxComponentFormulaDialog.RunModal();
    end;

    procedure EnableSelectedTaxTypes(var TaxType: Record "Tax Type")
    begin
        if TaxType.FindSet() then
            repeat
                TaxType.Validate(Enabled, true);
                TaxType.Modify(true);
            until TaxType.Next() = 0;
    end;

    procedure DisableSelectedTaxTypes(var TaxType: Record "Tax Type")
    begin
        if TaxType.FindSet() then
            repeat
                TaxType.Validate(Enabled, false);
                TaxType.Modify(true);
            until TaxType.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Script Symbol Store", 'OnEvaluateSymbolFormula', '', false, false)]
    local procedure OnEvaluateSymbolFormula(
        SymbolType: Enum "Symbol Type";
        SymbolID: Integer;
        sender: Codeunit "Script Symbol Store";
        FormulaID: Guid;
        var Symbols: Record "Script Symbol Value";
        var Value: Variant;
        var Handled: Boolean)
    var
        TaxComponentFormula: Record "Tax Component Formula";
        TaxComponentFormulaToken: Record "Tax Component Formula Token";
        TaxComponent: Record "Tax Component";
        ScriptDataTypeMgmt: Codeunit "Script Data Type Mgmt.";
        Values: Dictionary of [Text, Decimal];
        ValueVariant: Variant;
    begin
        if not TaxComponentFormula.Get(FormulaID) then
            exit;

        TaxComponentFormulaToken.Reset();
        TaxComponentFormulaToken.SetRange("Tax Type", TaxComponentFormula."Tax Type");
        TaxComponentFormulaToken.SetRange("Formula Expr. ID", FormulaID);
        if TaxComponentFormulaToken.FindSet() then
            repeat
                if TaxComponentFormulaToken."Value Type" = TaxComponentFormulaToken."Value Type"::Component then begin
                    Symbols.Get(SymbolType, TaxComponentFormulaToken."Component ID");
                    sender.GetSymbolValue(Symbols, ValueVariant);
                end else
                    ValueVariant := TaxComponentFormulaToken.Value;

                Values.Add(TaxComponentFormulaToken.Token, ValueVariant)
            until TaxComponentFormulaToken.Next() = 0;

        Value := ScriptDataTypeMgmt.EvaluateExpression(TaxComponentFormula.Expression, Values);
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Script Symbol Lookup Dialog", 'OnValidateLookupTableName', '', false, false)]
    local procedure OnValidateLookupTableName(CaseID: Guid; ScriptID: Guid; var TableID: Integer; var TableName: Text[30]; IsTransactionTable: Boolean)
    var
        TaxUseCase: Record "Tax Use Case";
    begin
        TaxUseCase.SetRange(id, CaseID);
        TaxUseCase.FindFirst();
        SearchTaxTypeTable(TableID, TableName, TaxUseCase."Tax Type", IsTransactionTable);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Script Symbol Lookup Dialog", 'OnLookupLookupTableName', '', false, false)]
    local procedure OnLookupLookupTableName(CaseID: Guid; ScriptID: Guid; var TableID: Integer; var TableName: Text[30]; SearchText: Text)
    var
        TaxUseCase: Record "Tax Use Case";
    begin
        TaxUseCase.SetRange(id, CaseID);
        TaxUseCase.FindFirst();
        OpenTaxTypeTableLookup(TableID, TableName, SearchText, TaxUseCase."Tax Type");
    end;

    var
        InvalidTableNoErr: Label 'You cannot enter ''%1'' in TableNo.', Comment = '%1, Table No. or Table Name';
}