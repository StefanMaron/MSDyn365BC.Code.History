report 17357 "HR Generic Report"
{
    ApplicationArea = Basic, Suite;
    Caption = 'HR Generic Report';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(HeaderGroups; "HR Field Group")
        {
            DataItemTableView = SORTING("Print Order");
            RequestFilterFields = "Code";
            dataitem(GroupColumn; "HR Field Group Line")
            {
                DataItemLink = "Field Group Code" = FIELD(Code);
                DataItemTableView = SORTING("Field Group Code", "Field Print Order No.", "Table No.", "Field No.");

                trigger OnAfterGetRecord()
                begin
                    if "Field Report Caption" = '' then begin
                        CalcFields("Field Name");
                        PrintRecordColumns(HeaderCellColumn, RecordCounter, "Table Name" + ': ' + "Field Name")
                    end else
                        PrintRecordColumns(HeaderCellColumn, RecordCounter, "Field Report Caption");
                end;

                trigger OnPostDataItem()
                begin
                    ExcelMgt.BoldRow(RecordCounter);
                end;
            }

            trigger OnPostDataItem()
            begin
                ExcelMgt.BoldRow(RecordCounter);
                LastLinePointer := RecordCounter;
            end;

            trigger OnPreDataItem()
            begin
                HeaderCellColumn := 'A';
            end;
        }
        dataitem(Person; Person)
        {
            RequestFilterFields = "No.";
            dataitem(Employee; Employee)
            {
                DataItemLink = "Person No." = FIELD("No.");
                RequestFilterFields = "No.";

                trigger OnAfterGetRecord()
                var
                    HRFieldGroup: Record "HR Field Group";
                begin
                    EmployeeRecordRef.GetTable(Employee);

                    HRFieldGroup.CopyFilters(HeaderGroups);
                    PrintFieldGroups(HRFieldGroup, true);
                    RowCellColumn := 'A';
                    RecordCounter := LastLinePointer + 1;

                    if ExtendPersonInfo then
                        EmployeeLineCounter := FillTableInfo(DATABASE::Employee, EmployeeLineCounter, LastLinePointer);
                end;

                trigger OnPostDataItem()
                var
                    HRFieldGroup: Record "HR Field Group";
                begin
                    // if no employee and some filters on employee exist
                    // then print info only with that employee
                    // unless ->
                    if Employee.IsEmpty and (Employee.GetFilters = '') then begin
                        HRFieldGroup.CopyFilters(HeaderGroups);
                        PrintFieldGroups(HRFieldGroup, false);
                    end;

                    if ExtendPersonInfo then
                        PersonLineCounter := FillTableInfo(DATABASE::Person, PersonLineCounter, LastLinePointer);
                end;

                trigger OnPreDataItem()
                begin
                    EmployeeLineCounter := PersonLineCounter;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                RowCellColumn := 'A';
                RecordCounter := LastLinePointer + 1;
                PersonRecordRef.GetTable(Person);
            end;

            trigger OnPreDataItem()
            begin
                PersonLineCounter := 2;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ExtendPersonInfo; ExtendPersonInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fill Person Info for all Lines';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        ExcelMgt.DownloadBook('HR Generic report.xlsx');
    end;

    trigger OnPreReport()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;

        ExcelMgt.CreateBook;
        ExcelMgt.OpenSheetByNumber(1);

        RecordCounter := 1;
    end;

    var
        ExcelMgt: Codeunit "Excel Management";
        LastLinePointer: Integer;
        RecordCounter: Integer;
        HeaderCellColumn: Code[10];
        PersonRecordRef: RecordRef;
        EmployeeRecordRef: RecordRef;
        RowCellColumn: Code[10];
        ExtendPersonInfo: Boolean;
        PersonLineCounter: Integer;
        EmployeeLineCounter: Integer;

    [Scope('OnPrem')]
    procedure PrintRecordColumns(var CellColumn: Code[10]; RowCounter: Integer; FieldCaption: Text[62])
    begin
        ExcelMgt.FillCellWithTextFormat(CellColumn + Format(RowCounter), FieldCaption);
        ExcelMgt.SetColumnSize(CellColumn + Format(RowCounter), 15);
        CellColumn := ExcelMgt.GetNextColumn(CellColumn, 1);
    end;

    [Scope('OnPrem')]
    procedure PrintValue(CellColumn: Code[10]; RowCounter: Integer; xFieldRef: FieldRef)
    begin
        ExcelMgt.FillCellWithTextFormat(CellColumn + Format(RowCounter), Format(xFieldRef));
    end;

    [Scope('OnPrem')]
    procedure PrintRelatedTable(TableId: Integer; FieldId: Integer; BaseRecRef: RecordRef; CellColumn: Code[10]; RowCounter: Integer)
    var
        xRelatedRecordRef: RecordRef;
        FieldInPk: Boolean;
    begin
        xRelatedRecordRef.Open(TableId);

        FieldInPk := not ((DATABASE::Employee = BaseRecRef.Number) and
                          ((DATABASE::"Employee Ledger Entry" = TableId) or (DATABASE::"Employee Job Entry" = TableId)));

        SetFiltersToRelatedTable(BaseRecRef, xRelatedRecordRef, FieldInPk);

        PrintTableToExcel(xRelatedRecordRef, FieldId, RowCellColumn, RecordCounter);

        xRelatedRecordRef.Close;
    end;

    [Scope('OnPrem')]
    procedure PrintTableToExcel(xRelatedRecordRef: RecordRef; FieldId: Integer; CellColumn: Code[10]; RowCounter: Integer)
    var
        xFieldRef: FieldRef;
    begin
        if xRelatedRecordRef.FindSet then
            repeat
                xFieldRef := xRelatedRecordRef.Field(FieldId);
                PrintValue(CellColumn, RowCounter, xFieldRef);
                RowCounter += 1;
            until xRelatedRecordRef.Next = 0;

        if RowCounter - 1 > LastLinePointer then
            LastLinePointer := RowCounter - 1;
    end;

    [Scope('OnPrem')]
    procedure PrintFieldGroups(var HRFieldGroup: Record "HR Field Group"; PrintEmployeeInfo: Boolean)
    var
        HRFieldGroupLine: Record "HR Field Group Line";
    begin
        HRFieldGroup.SetCurrentKey("Print Order");
        if HRFieldGroup.FindSet then
            repeat
                HRFieldGroupLine.Reset;
                HRFieldGroupLine.SetCurrentKey("Field Group Code", "Field Print Order No.", "Table No.", "Field No.");
                HRFieldGroupLine.SetRange("Field Group Code", HRFieldGroup.Code);
                if HRFieldGroupLine.FindSet then
                    repeat
                        PrintFieldGroupLine(HRFieldGroupLine, PrintEmployeeInfo);
                        RowCellColumn := ExcelMgt.GetNextColumn(RowCellColumn, 1);
                    until HRFieldGroupLine.Next = 0;

                if RecordCounter > LastLinePointer then
                    LastLinePointer := RecordCounter;

            until HRFieldGroup.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure PrintFieldGroupLine(var HRFieldGroupLine: Record "HR Field Group Line"; PrintEmployeeInfo: Boolean)
    var
        xFieldRef: FieldRef;
    begin
        with HRFieldGroupLine do
            // Person and employee is in Cartesian product
            // other tables printed as lists for product entry
            case "Table No." of
                DATABASE::Person:
                    begin
                        xFieldRef := PersonRecordRef.Field("Field No.");
                        PrintValue(RowCellColumn, RecordCounter, xFieldRef);
                    end;
                DATABASE::Employee:
                    if PrintEmployeeInfo then begin
                        xFieldRef := EmployeeRecordRef.Field("Field No.");
                        PrintValue(RowCellColumn, RecordCounter, xFieldRef);
                    end;
                else
                    if IsTableRelated(DATABASE::Employee, "Table No.") then begin
                        if PrintEmployeeInfo then
                            PrintRelatedTable("Table No.", "Field No.", EmployeeRecordRef, RowCellColumn, RecordCounter)
                    end else
                        if IsTableRelated(DATABASE::Person, "Table No.") then
                            PrintRelatedTable("Table No.", "Field No.", PersonRecordRef, RowCellColumn, RecordCounter)
            end;
    end;

    [Scope('OnPrem')]
    procedure SetFiltersToRelatedTable(xBaseRecordRef: RecordRef; var xRelatedRecordRef: RecordRef; OnlyPKFields: Boolean): Boolean
    var
        FieldTable: Record "Field";
        xBaseFieldRef: FieldRef;
        xFieldRef: FieldRef;
        RelationFieldId: Integer;
    begin
        FieldTable.SetRange(TableNo, xRelatedRecordRef.Number);
        FieldTable.SetRange(RelationTableNo, xBaseRecordRef.Number);
        FieldTable.SetFilter(ObsoleteState, '<>%1', FieldTable.ObsoleteState::Removed);
        if FieldTable.FindSet then
            repeat
                if (not OnlyPKFields) or IsPrimaryKeyContainsField(FieldTable.TableNo, FieldTable."No.") then begin
                    if FieldTable.RelationFieldNo = 0 then
                        RelationFieldId := GetFirstPrimaryKeyField(xBaseRecordRef.Number)
                    else
                        RelationFieldId := FieldTable.RelationFieldNo;

                    xBaseFieldRef := xBaseRecordRef.Field(RelationFieldId);
                    xFieldRef := xRelatedRecordRef.Field(FieldTable."No.");

                    xFieldRef.SetRange(xBaseFieldRef.Value);
                end;
            until FieldTable.Next = 0
        else
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure IsTableRelated(BaseRecordId: Integer; RelatedRecordId: Integer): Boolean
    var
        FieldTable: Record "Field";
    begin
        FieldTable.SetRange(TableNo, RelatedRecordId);
        FieldTable.SetRange(RelationTableNo, BaseRecordId);
        FieldTable.SetFilter(ObsoleteState, '<>%1', FieldTable.ObsoleteState::Removed);
        exit(not FieldTable.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure GetFirstPrimaryKeyField(TableId: Integer): Integer
    var
        xKeyRef: KeyRef;
        xFieldRef: FieldRef;
        xRecordRef: RecordRef;
    begin
        xRecordRef.Open(TableId);
        xKeyRef := xRecordRef.KeyIndex(1);
        xFieldRef := xKeyRef.FieldIndex(1);
        exit(xFieldRef.Number);
    end;

    [Scope('OnPrem')]
    procedure IsPrimaryKeyContainsField(TableId: Integer; FieldId: Integer): Boolean
    var
        xKeyRef: KeyRef;
        xFieldRef: FieldRef;
        xRecordRef: RecordRef;
        I: Integer;
    begin
        xRecordRef.Open(TableId);
        xKeyRef := xRecordRef.KeyIndex(1);

        for I := 1 to xKeyRef.FieldCount do begin
            xFieldRef := xKeyRef.FieldIndex(I);

            if xFieldRef.Number = FieldId then
                exit(true);
        end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure FillExcelRowsWithTableInfo(TableNo: Integer; var HRFieldGroup: Record "HR Field Group"; SourceRow: Integer; DestStartingRow: Integer; DestEndingRow: Integer)
    var
        HRFieldGroupLine: Record "HR Field Group Line";
        ColumnCode: Code[10];
    begin
        ColumnCode := 'A';
        HRFieldGroup.SetCurrentKey("Print Order");
        if HRFieldGroup.FindSet then
            repeat
                HRFieldGroupLine.Reset;
                HRFieldGroupLine.SetCurrentKey("Field Group Code", "Field Print Order No.", "Table No.", "Field No.");
                HRFieldGroupLine.SetRange("Field Group Code", HRFieldGroup.Code);
                if HRFieldGroupLine.FindSet then
                    repeat
                        if HRFieldGroupLine."Table No." = TableNo then
                            ExcelMgt.CopyCellRangeTo(ColumnCode + Format(SourceRow),
                              ColumnCode + Format(DestStartingRow), ColumnCode + Format(DestEndingRow));
                        ColumnCode := ExcelMgt.GetNextColumn(ColumnCode, 1);
                    until HRFieldGroupLine.Next = 0;
            until HRFieldGroup.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure FillTableInfo(TableNo: Integer; LineCounter: Integer; LastLinePointer: Integer): Integer
    var
        HRFieldGroup: Record "HR Field Group";
    begin
        if LineCounter + 1 <= LastLinePointer then begin
            HRFieldGroup.Reset;
            HRFieldGroup.CopyFilters(HeaderGroups);
            FillExcelRowsWithTableInfo(TableNo, HRFieldGroup,
              LineCounter, LineCounter + 1, LastLinePointer);
        end;

        exit(LastLinePointer + 1);
    end;
}

