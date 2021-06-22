codeunit 1387 "Employee Templ. Mgt."
{
    trigger OnRun()
    begin
    end;

    procedure InsertEmployeeFromTemplate(var Employee: Record Employee): Boolean
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        if not IsEnabled() then
            exit(false);

        if not SelectEmployeeTemplate(EmployeeTempl) then
            exit(false);

        Employee.Init();
        Employee.Insert(true);

        ApplyEmployeeTemplate(Employee, EmployeeTempl);

        exit(true);
    end;

    local procedure ApplyTemplate(var Employee: Record Employee; EmployeeTempl: Record "Employee Templ.")
    begin
        Employee.City := EmployeeTempl.City;
        Employee."Post Code" := EmployeeTempl."Post Code";
        Employee.County := EmployeeTempl.County;
        Employee.Gender := EmployeeTempl.Gender;
        Employee."Country/Region Code" := EmployeeTempl."Country/Region Code";
        Employee."Statistics Group Code" := EmployeeTempl."Statistics Group Code";
        Employee."Employee Posting Group" := EmployeeTempl."Employee Posting Group";
        Employee."Application Method" := EmployeeTempl."Application Method".AsInteger();
        Employee."Cost Center Code" := EmployeeTempl."Cost Center Code";
        Employee."Cost Object Code" := EmployeeTempl."Cost Object Code";
        Employee.Modify(true);
    end;

    procedure SelectEmployeeTemplateFromContact(var EmployeeTempl: Record "Employee Templ."): Boolean
    begin
        exit(SelectEmployeeTemplate(EmployeeTempl));
    end;

    local procedure SelectEmployeeTemplate(var EmployeeTempl: Record "Employee Templ."): Boolean
    var
        SelectEmployeeTemplList: Page "Select Employee Templ. List";
    begin
        if EmployeeTempl.Count = 1 then begin
            EmployeeTempl.FindFirst();
            exit(true);
        end;

        if (EmployeeTempl.Count > 1) and GuiAllowed then begin
            SelectEmployeeTemplList.SetTableView(EmployeeTempl);
            SelectEmployeeTemplList.LookupMode(true);
            if SelectEmployeeTemplList.RunModal() = Action::LookupOK then begin
                SelectEmployeeTemplList.GetRecord(EmployeeTempl);
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure InsertDimensions(EmployeeNo: Code[20]; EmployeeTemplCode: Code[20])
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        SourceDefaultDimension.SetRange("Table ID", Database::"Employee Templ.");
        SourceDefaultDimension.SetRange("No.", EmployeeTemplCode);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", Database::Employee);
                DestDefaultDimension.Validate("No.", EmployeeNo);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                if not DestDefaultDimension.Get(DestDefaultDimension."Table ID", DestDefaultDimension."No.", DestDefaultDimension."Dimension Code") then
                    DestDefaultDimension.Insert(true);
            until SourceDefaultDimension.Next() = 0;
    end;

    procedure TemplatesAreNotEmpty(): Boolean
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        if not IsEnabled() then
            exit(false);

        exit(not EmployeeTempl.IsEmpty);
    end;

    procedure ApplyEmployeeTemplate(var Employee: Record Employee; EmployeeTempl: Record "Employee Templ.")
    begin
        ApplyTemplate(Employee, EmployeeTempl);
        InsertDimensions(Employee."No.", EmployeeTempl.Code);
    end;

    [Obsolete('Replaced by ApplyEmployeeTemplate with different set of parameters', '18.0')]
    procedure ApplyContactEmployeeTemplate(var Employee: Record Employee)
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        if not IsEnabled() then
            exit;

        if not SelectEmployeeTemplate(EmployeeTempl) then
            exit;

        ApplyEmployeeTemplate(Employee, EmployeeTempl);
    end;

    procedure IsEnabled() Result: Boolean
    var
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        Result := TemplateFeatureMgt.IsEnabled();

        OnAfterIsEnabled(Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;
}