codeunit 20292 "Use Case Entity Mgmt."
{
    procedure GetSourceTable(CaseID: Guid): Integer;
    var
        UseCase: Record "Tax Use Case";
    begin
        UseCase.GET(CaseID);
        Exit(UseCase."Tax Table ID");
    end;

    /// Table Linking
    procedure CreateTableLinking(CaseID: Guid; TableID: Integer; LookupTableID: Integer): Guid;
    var
        UseCaseEventTableLink: Record "Use Case Event Table Link";
    begin
        UseCaseEventTableLink.Init();
        UseCaseEventTableLink."Case ID" := CaseID;
        UseCaseEventTableLink.ID := CreateGuid();
        UseCaseEventTableLink."Table ID" := TableID;
        UseCaseEventTableLink."Lookup Table ID" := LookupTableID;
        UseCaseEventTableLink.Insert(true);
        Commit();
        Exit(UseCaseEventTableLink.ID);
    end;

    procedure DeleteTableLinking(CaseID: Guid; var ID: Guid): Guid;
    var
        UseCaseEventTableLink: Record "Use Case Event Table Link";
    begin
        if IsNullGuid(ID) then
            Exit;

        UseCaseEventTableLink.GET(CaseID, ID);
        UseCaseEventTableLink.Delete(true);
        ID := EmptyGuid;
    end;

    /// Rate Column Relation

    procedure CreateRateColumnRelation(CaseID: Guid): Guid;
    var
        UseCaseRateColumnRelation: Record "Use Case Rate Column Relation";
    begin
        UseCaseRateColumnRelation.Init();
        UseCaseRateColumnRelation."Case ID" := CaseID;
        UseCaseRateColumnRelation.ID := CreateGuid();
        UseCaseRateColumnRelation.Insert(true);

        Exit(UseCaseRateColumnRelation.ID);
    end;

    procedure DeleteRateColumnRelation(CaseID: Guid; ID: Guid);
    var
        UseCaseRateColumnRelation: Record "Use Case Rate Column Relation";
    begin
        if IsNullGuid(ID) then
            Exit;

        UseCaseRateColumnRelation.GET(CaseID, ID);
        UseCaseRateColumnRelation.Delete(true);
    end;
    /// Use Case line

    procedure CreateUseCaseAttributeMapping(CaseID: Guid): Guid;
    var
        UseCaseAttributeMapping: Record "Use Case Attribute Mapping";
    begin
        UseCaseAttributeMapping.Init();
        UseCaseAttributeMapping."Case ID" := CaseID;
        UseCaseAttributeMapping.ID := CREATEGUID();
        UseCaseAttributeMapping.Insert(true);

        Exit(UseCaseAttributeMapping.ID);
    end;

    procedure DeleteUseCaseAttributeMapping(CaseID: Guid; ID: Guid);
    var
        UseCaseAttributeMapping: Record "Use Case Attribute Mapping";
    begin
        if IsNullGuid(ID) then
            Exit;

        UseCaseAttributeMapping.GET(CaseID, ID);
        UseCaseAttributeMapping.Delete(true);
    end;

    /// Component Calculation

    procedure CreateComponentCalculation(CaseID: Guid): Guid;
    var
        UseCaseComponentCalculation: Record "Use Case Component Calculation";
    begin
        UseCaseComponentCalculation.Init();
        UseCaseComponentCalculation."Case ID" := CaseID;
        UseCaseComponentCalculation.ID := CREATEGUID();
        UseCaseComponentCalculation.Insert(true);

        Exit(UseCaseComponentCalculation.ID);
    end;

    procedure DeleteComponentCalculation(CaseID: Guid; ID: Guid);
    var
        UseCaseComponentCalculation: Record "Use Case Component Calculation";
    begin
        if IsNullGuid(ID) then
            Exit;

        UseCaseComponentCalculation.GET(CaseID, ID);
        UseCaseComponentCalculation.Delete(true);
    end;

    procedure CreateComponentExpression(CaseID: Guid; ID: Integer): Guid;
    var
        TaxComponentExpression: Record "Tax Component Expression";
    begin
        TaxComponentExpression.Init();
        TaxComponentExpression."Case ID" := CaseID;
        TaxComponentExpression.ID := CreateGuid();
        TaxComponentExpression."Component ID" := ID;
        TaxComponentExpression.Insert(true);

        Exit(TaxComponentExpression.ID);
    end;

    procedure DeleteTaxComponentExpression(CaseID: Guid; ID: Guid);
    var
        TaxComponentExpression: Record "Tax Component Expression";
    begin
        TaxComponentExpression.Get(CaseID, ID);
        TaxComponentExpression.Delete(true);
    end;

    /// TableRelation Functions

    procedure CreateTableRelation(CaseID: Guid): Guid;
    var
        TaxTableRelation: Record "Tax Table Relation";
    begin
        TaxTableRelation.Init();
        TaxTableRelation."Case ID" := CaseID;
        TaxTableRelation.ID := CreateGuid();
        TaxTableRelation.Insert(true);
        Exit(TaxTableRelation.ID);
    end;

    procedure DeleteTableRelation(CaseID: Guid; var ID: Guid);
    var
        TaxTableRelation: Record "Tax Table Relation";
    begin
        if IsNullGuid(ID) then
            Exit;

        TaxTableRelation.GET(CaseID, ID);
        TaxTableRelation.Delete(true);

        ID := EmptyGuid;
    end;

    local procedure ValidateUseCase(CaseId: Guid)
    var
        TaxUseCase: Record "Tax Use Case";
        CompanyInformation: Record "Company Information";
    begin
        if not CompanyInformation.Get() then
            exit;

        if not TaxUseCase.Get(CaseId) then
            exit;

        if TaxUseCase.Status = TaxUseCase.Status::Released then
            Error(CannotChangeReleasedUseCaseErr, TaxUseCase.Description);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tax Type", 'OnBeforeDeleteTaxType', '', false, false)]
    local procedure OnAfterDeleteTaxType(TaxTypeCode: Code[20])
    var
        TaxUseCase: Record "Tax Use Case";
    begin
        TaxUseCase.SetRange("Tax Type", TaxTypeCode);
        if not TaxUseCase.IsEmpty() then
            TaxUseCase.DeleteAll(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Script Symbol Store", 'OnBeforeValidateIfUpdateIsAllowed', '', false, false)]
    procedure OnBeforeValidateIfUpdateIsAllowed(CaseID: Guid)
    begin
        ValidateUseCase(CaseID);
    end;

    var
        CannotChangeReleasedUseCaseErr: Label 'You cannot change configuration on Released use case : %1', Comment = '%1 = use case name';
        EmptyGuid: Guid;
}