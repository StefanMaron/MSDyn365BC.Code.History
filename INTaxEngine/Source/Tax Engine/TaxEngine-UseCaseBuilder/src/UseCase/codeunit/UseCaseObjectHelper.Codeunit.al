codeunit 20295 "Use Case Object Helper"
{
    procedure GetUseCaseID(UseCaseName: Text[2000]): Guid;
    var
        UseCase: Record "Tax Use Case";
        InvalidParentUseCaseErr: Label 'Parent Use Case :%1 does not exist', Comment = '%1= Parent Use Case Description';
    begin
        if UseCaseName = '' then
            Exit(EmptyGuid);

        UseCase.SetRange(Description, UseCaseName);
        if not UseCase.FindFirst() then
            Error(InvalidParentUseCaseErr, UseCaseName);

        exit(UseCase.ID);
    end;

    procedure GetUseCaseName(CaseID: Guid): Text[2000];
    var
        UseCase: Record "Tax Use Case";
    begin
        if IsNullGuid(CaseID) then
            Exit('');

        UseCase.SetRange(ID, CaseID);
        if UseCase.FindFirst() then
            Exit(UseCase.Description);

        exit('');
    end;

    procedure IsTableRelationEmpty(CaseId: Guid; ID: Guid): Boolean
    var
        UseCaseFieldLink: Record "Use Case Field Link";
    begin
        if IsNullGuid(Id) then
            exit(true);

        UseCaseFieldLink.SetRange("Case ID", CaseId);
        UseCaseFieldLink.SetRange("Table Filter ID", ID);
        exit(UseCaseFieldLink.IsEmpty());
    end;

    var
        EmptyGuid: Guid;
}