page 5513 "Time Registration Entity"
{
    Caption = 'timeRegistrationEntries', Locked = true;
    DelayedInsert = true;
    EntityName = 'timeRegistrationEntry';
    EntitySetName = 'timeRegistrationEntries';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = "Employee Time Reg Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(employeeId; "Employee Id")
                {
                    ApplicationArea = All;
                    Caption = 'employeeId', Locked = true;

                    trigger OnValidate()
                    begin
                        if "Employee Id" = BlankGUID then begin
                            "Employee No" := '';
                            exit;
                        end;

                        Employee.SetRange(Id, "Employee Id");
                        if not Employee.FindFirst then
                            Error(EmployeeIdDoesNotMatchAnEmployeeErr);

                        "Employee No" := Employee."No.";
                    end;
                }
                field(employeeNumber; "Employee No")
                {
                    ApplicationArea = All;
                    Caption = 'employeeNumber', Locked = true;

                    trigger OnValidate()
                    begin
                        if Employee."No." <> '' then begin
                            if Employee."No." <> "Employee No" then
                                Error(EmployeeValuesDontMatchErr);
                            exit;
                        end;

                        if "Employee No" = '' then begin
                            "Employee Id" := BlankGUID;
                            exit;
                        end;

                        if not Employee.Get("Employee No") then
                            Error(EmployeeNumberDoesNotMatchAnEmployeeErr);

                        Validate("Employee Id", Employee.Id);
                    end;
                }
                field(date; Date)
                {
                    ApplicationArea = All;
                    Caption = 'date', Locked = true;
                }
                field(quantity; Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'quantity', Locked = true;
                }
                field(status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'status', Locked = true;
                    Editable = false;
                }
                field(unitOfMeasureId; "Unit of Measure Id")
                {
                    ApplicationArea = All;
                    Caption = 'UnitOfMeasureId', Locked = true;
                    Editable = false;
                    ToolTip = 'Specifies Unit of Measure.';
                }
                field(unitOfMeasure; UnitOfMeasureJSON)
                {
                    ApplicationArea = All;
                    Caption = 'unitOfMeasure', Locked = true;
                    Editable = false;
                    ODataEDMType = 'ITEM-UOM';
                    ToolTip = 'Specifies Unit of Measure.';
                }
                field(id; Id)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                }
                field(lastModfiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModfiedDateTime', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        UnitOfMeasureJSON := GraphMgtComplexTypes.GetUnitOfMeasureJSON("Unit of Measure Code");
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        PropagateDelete;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not LinesLoaded then begin
            LoadRecords(GetFilter(Id), GetFilter(Date), GetFilter("Employee Id"));
            if not FindFirst then
                exit(false);
            LinesLoaded := true;
        end;

        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        PropagateInsert;
        UnitOfMeasureJSON := GraphMgtComplexTypes.GetUnitOfMeasureJSON("Unit of Measure Code");
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if "Employee Id" <> xRec."Employee Id" then
            Error(CannotModifyEmployeeIdErr);

        if Date <> xRec.Date then
            Error(CannotModifyDateErr);

        PropagateModify;
    end;

    var
        CannotModifyEmployeeIdErr: Label 'The employee ID cannot be modified.', Locked = true;
        CannotModifyDateErr: Label 'The date cannot be modified.', Locked = true;
        Employee: Record Employee;
        UnitOfMeasureJSON: Text;
        LinesLoaded: Boolean;
        EmployeeValuesDontMatchErr: Label 'The employee values do not match to a specific Employee.', Locked = true;
        EmployeeIdDoesNotMatchAnEmployeeErr: Label 'The "employeeId" does not match to an Employee.', Locked = true;
        EmployeeNumberDoesNotMatchAnEmployeeErr: Label 'The "employeeNumber" does not match to an Employee.', Locked = true;
        BlankGUID: Guid;
}

