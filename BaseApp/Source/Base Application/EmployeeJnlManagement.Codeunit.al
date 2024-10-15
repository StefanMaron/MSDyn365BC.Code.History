codeunit 17380 EmployeeJnlManagement
{
    Permissions = TableData "Employee Journal Template" = imd,
                  TableData "Employee Journal Batch" = imd;

    trigger OnRun()
    begin
    end;

    var
        OldEmployeeNo: Code[20];
        OpenFromBatch: Boolean;
        Text001: Label '%1 journal';
        Text003: Label 'DEFAULT';
        Text004: Label 'Default Journal';

    [Scope('OnPrem')]
    procedure TemplateSelection(FormID: Integer; FormTemplate: Option Salary,Vacation; var EmplJnlLine: Record "Employee Journal Line"; var JnlSelected: Boolean)
    var
        EmplJnlTemplate: Record "Employee Journal Template";
    begin
        JnlSelected := true;

        EmplJnlTemplate.Reset();

        case EmplJnlTemplate.Count of
            0:
                begin
                    EmplJnlTemplate.Init();
                    EmplJnlTemplate.Type := FormTemplate;
                    EmplJnlTemplate.Name := DelChr(Format(EmplJnlTemplate.Type, MaxStrLen(EmplJnlTemplate.Name)));
                    EmplJnlTemplate.Description := StrSubstNo(Text001, EmplJnlTemplate.Type);
                    EmplJnlTemplate.Validate(Type);
                    EmplJnlTemplate.Insert();
                    Commit();
                end;
            1:
                EmplJnlTemplate.FindFirst;
            else
                JnlSelected := PAGE.RunModal(0, EmplJnlTemplate) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            EmplJnlLine.FilterGroup := 2;
            EmplJnlLine.SetRange("Journal Template Name", EmplJnlTemplate.Name);
            EmplJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                EmplJnlLine."Journal Template Name" := '';
                PAGE.Run(EmplJnlTemplate."Page ID", EmplJnlLine);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure TemplateSelectionFromBatch(var EmplJnlBatch: Record "Employee Journal Batch")
    var
        EmplJnlLine: Record "Employee Journal Line";
        EmplJnlTemplate: Record "Employee Journal Template";
    begin
        OpenFromBatch := true;
        EmplJnlTemplate.Get(EmplJnlBatch."Journal Template Name");
        EmplJnlTemplate.TestField("Page ID");
        EmplJnlBatch.TestField(Name);

        EmplJnlLine.FilterGroup := 2;
        EmplJnlLine.SetRange("Journal Template Name", EmplJnlTemplate.Name);
        EmplJnlLine.FilterGroup := 0;

        EmplJnlLine."Journal Template Name" := '';
        EmplJnlLine."Journal Batch Name" := EmplJnlBatch.Name;
        PAGE.Run(EmplJnlTemplate."Page ID", EmplJnlLine);
    end;

    [Scope('OnPrem')]
    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var EmplJnlLine: Record "Employee Journal Line")
    begin
        CheckTemplateName(EmplJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        EmplJnlLine.FilterGroup := 2;
        EmplJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        EmplJnlLine.FilterGroup := 0;
    end;

    [Scope('OnPrem')]
    procedure OpenJnlBatch(var EmplJnlBatch: Record "Employee Journal Batch")
    var
        EmplJnlTemplate: Record "Employee Journal Template";
        JnlSelected: Boolean;
    begin
        if EmplJnlBatch.GetFilter("Journal Template Name") <> '' then
            exit;
        EmplJnlBatch.FilterGroup(2);
        if EmplJnlBatch.GetFilter("Journal Template Name") <> '' then begin
            EmplJnlBatch.FilterGroup(0);
            exit;
        end;
        EmplJnlBatch.FilterGroup(0);

        EmplJnlBatch.Find('-');
        JnlSelected := true;
        if EmplJnlBatch.GetFilter("Journal Template Name") <> '' then
            EmplJnlTemplate.SetRange(Name, EmplJnlBatch.GetFilter("Journal Template Name"));
        case EmplJnlTemplate.Count of
            1:
                EmplJnlTemplate.FindFirst;
            else
                JnlSelected := PAGE.RunModal(0, EmplJnlTemplate) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        EmplJnlBatch.FilterGroup(2);
        EmplJnlBatch.SetRange("Journal Template Name", EmplJnlTemplate.Name);
        EmplJnlBatch.FilterGroup(0);
    end;

    [Scope('OnPrem')]
    procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        EmplJnlBatch: Record "Employee Journal Batch";
    begin
        EmplJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        if not EmplJnlBatch.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            if not EmplJnlBatch.FindFirst then begin
                EmplJnlBatch.Init();
                EmplJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
                EmplJnlBatch.SetupNewBatch;
                EmplJnlBatch.Name := Text003;
                EmplJnlBatch.Description := Text004;
                EmplJnlBatch.Insert(true);
                Commit();
            end;
            CurrentJnlBatchName := EmplJnlBatch.Name
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckName(CurrentJnlBatchName: Code[10]; var EmplJnlLine: Record "Employee Journal Line")
    var
        EmplJnlBatch: Record "Employee Journal Batch";
    begin
        EmplJnlBatch.Get(EmplJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
    end;

    [Scope('OnPrem')]
    procedure SetName(CurrentJnlBatchName: Code[10]; var EmplJnlLine: Record "Employee Journal Line")
    begin
        EmplJnlLine.FilterGroup := 2;
        EmplJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        EmplJnlLine.FilterGroup := 0;
        if EmplJnlLine.Find('-') then;
    end;

    [Scope('OnPrem')]
    procedure LookupName(var CurrentJnlBatchName: Code[10]; var EmplJnlLine: Record "Employee Journal Line")
    var
        EmplJnlBatch: Record "Employee Journal Batch";
    begin
        Commit();
        EmplJnlBatch."Journal Template Name" := EmplJnlLine.GetRangeMax("Journal Template Name");
        EmplJnlBatch.Name := EmplJnlLine.GetRangeMax("Journal Batch Name");
        EmplJnlBatch.FilterGroup(2);
        EmplJnlBatch.SetRange("Journal Template Name", EmplJnlBatch."Journal Template Name");
        EmplJnlBatch.FilterGroup(0);
        if PAGE.RunModal(0, EmplJnlBatch) = ACTION::LookupOK then begin
            CurrentJnlBatchName := EmplJnlBatch.Name;
            SetName(CurrentJnlBatchName, EmplJnlLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure GetEmployee(EmployeeNo: Code[20]; var EmployeeName: Text[50])
    var
        Employee: Record Employee;
    begin
        if EmployeeNo <> OldEmployeeNo then begin
            EmployeeName := '';
            if EmployeeNo <> '' then
                if Employee.Get(EmployeeNo) then
                    EmployeeName := Employee.GetFullName;
            OldEmployeeNo := EmployeeNo;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetAccounts(EmplJnlLine: Record "Employee Journal Line"; var EmployeeName: Text[100]; var ElementName: Text[100])
    var
        Employee: Record Employee;
        PayrollElement: Record "Payroll Element";
    begin
        EmployeeName := '';
        if Employee.Get(EmplJnlLine."Employee No.") then
            EmployeeName := Employee.GetFullNameOnDate(EmplJnlLine."Starting Date");

        ElementName := '';
        if PayrollElement.Get(EmplJnlLine."Element Code") then
            ElementName := PayrollElement.Description;
    end;
}

