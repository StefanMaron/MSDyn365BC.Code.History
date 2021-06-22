codeunit 7354 "BaseApp ID"
{
    SingleInstance = true;

    procedure Get(): Guid
    var
        EmptyGuid: Guid;
    begin
        if Info.Id() = EmptyGuid then
            NavApp.GetCurrentModuleInfo(Info);

        exit(Info.Id());
    end;

    var
        Info: ModuleInfo;
}