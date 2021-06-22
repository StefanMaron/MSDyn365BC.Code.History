codeunit 2130 "O365 Excel Import Management"
{

    trigger OnRun()
    begin
    end;

    var
        ValueIsNotValidDecimalErr: Label '%1 is not a valid decimal.', Comment = '%1 - some value which should be converted to decimal.';

    procedure ImportData(var ExcelBuffer: Record "Excel Buffer"; var O365FieldExcelMapping: Record "O365 Field Excel Mapping"; StartRowNo: Integer; ObjectType: Option Customer,Item): Integer
    begin
        ExcelBuffer.Reset();
        case ObjectType of
            ObjectType::Customer:
                exit(ImportCustomers(ExcelBuffer, O365FieldExcelMapping, StartRowNo));
            ObjectType::Item:
                exit(ImportItems(ExcelBuffer, O365FieldExcelMapping, StartRowNo));
        end;
    end;

    local procedure ImportCustomers(var ExcelBuffer: Record "Excel Buffer"; var O365FieldExcelMapping: Record "O365 Field Excel Mapping"; StartRowNo: Integer): Integer
    var
        TempCustomer: Record Customer temporary;
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.GetTable(TempCustomer);

        for i := StartRowNo to GetLastRowNo(ExcelBuffer) do begin
            ExcelBuffer.SetRange("Row No.", i);
            InitNewCustomerRecordRef(RecRef, i);
            FillRecordRefFromExcelBuffer(ExcelBuffer, O365FieldExcelMapping, RecRef);
            RecRef.Insert();
        end;

        CreateCustomersFromBuffer(TempCustomer);
        exit(TempCustomer.Count);
    end;

    local procedure ImportItems(var ExcelBuffer: Record "Excel Buffer"; var O365FieldExcelMapping: Record "O365 Field Excel Mapping"; StartRowNo: Integer): Integer
    var
        TempItem: Record Item temporary;
        RecRef: RecordRef;
        i: Integer;
    begin
        RecRef.GetTable(TempItem);

        for i := StartRowNo to GetLastRowNo(ExcelBuffer) do begin
            ExcelBuffer.SetRange("Row No.", i);
            InitNewItemRecordRef(RecRef, i);
            FillRecordRefFromExcelBuffer(ExcelBuffer, O365FieldExcelMapping, RecRef);
            RecRef.Insert();
        end;

        CreateItemsFromBuffer(TempItem);
        exit(TempItem.Count);
    end;

    local procedure GetLastRowNo(var ExcelBuffer: Record "Excel Buffer"): Integer
    begin
        ExcelBuffer.Reset();
        ExcelBuffer.FindLast;
        exit(ExcelBuffer."Row No.");
    end;

    local procedure AddFieldValueToRecordRef(ExcelBuffer: Record "Excel Buffer"; var O365FieldExcelMapping: Record "O365 Field Excel Mapping"; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
    begin
        O365FieldExcelMapping.SetRange("Excel Column No.", ExcelBuffer."Column No.");
        if O365FieldExcelMapping.FindFirst then begin
            FieldRef := RecRef.Field(O365FieldExcelMapping."Field ID");
            if FieldRef.Type = FieldType::Decimal then
                TryEvaluateTextToDecimal(ExcelBuffer."Cell Value as Text");
            FieldRef.Value := CopyStr(ExcelBuffer."Cell Value as Text", 1, FieldRef.Length);
        end;
    end;

    local procedure TryEvaluateTextToDecimal(ValueAsText: Text)
    var
        DecimalValue: Decimal;
    begin
        if not Evaluate(DecimalValue, ValueAsText) then
            Error(ValueIsNotValidDecimalErr, ValueAsText);
    end;

    local procedure InitNewCustomerRecordRef(var RecRef: RecordRef; RowNo: Integer)
    var
        DummyCustomer: Record Customer;
        FieldRef: FieldRef;
    begin
        RecRef.Init();
        FieldRef := RecRef.Field(DummyCustomer.FieldNo("No."));
        FieldRef.Value := Format(RowNo);
    end;

    local procedure InitNewItemRecordRef(var RecRef: RecordRef; RowNo: Integer)
    var
        DummyItem: Record Item;
        FieldRef: FieldRef;
    begin
        RecRef.Init();
        FieldRef := RecRef.Field(DummyItem.FieldNo("No."));
        FieldRef.Value := Format(RowNo);
    end;

    local procedure CreateCustomersFromBuffer(var TempCustomer: Record Customer temporary)
    var
        Customer: Record Customer;
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        GetCustomerConfigTemplate(ConfigTemplateHeader);

        if TempCustomer.FindSet then
            repeat
                CreateCustomerFromBuffer(TempCustomer, Customer);
                UpdateRecordFromTemplate(ConfigTemplateHeader, Customer);
            until TempCustomer.Next = 0;
    end;

    local procedure CreateItemsFromBuffer(var TempItem: Record Item temporary)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        Item: Record Item;
    begin
        GetItemConfigTemplate(ConfigTemplateHeader);

        if TempItem.FindSet then
            repeat
                CreateItemFromBuffer(TempItem, Item);
                UpdateRecordFromTemplate(ConfigTemplateHeader, Item);
            until TempItem.Next = 0;
    end;

    local procedure CreateCustomerFromBuffer(var TempCustomer: Record Customer temporary; var Customer: Record Customer)
    begin
        Customer.TransferFields(TempCustomer);
        Customer."No." := '';
        Customer.Insert(true);
    end;

    local procedure CreateItemFromBuffer(var TempItem: Record Item temporary; var Item: Record Item)
    begin
        Item.TransferFields(TempItem);
        Item."No." := '';
        Item.Insert(true);
    end;

    local procedure FillRecordRefFromExcelBuffer(var ExcelBuffer: Record "Excel Buffer"; var O365FieldExcelMapping: Record "O365 Field Excel Mapping"; var RecRef: RecordRef)
    begin
        if ExcelBuffer.FindSet then
            repeat
                AddFieldValueToRecordRef(ExcelBuffer, O365FieldExcelMapping, RecRef);
            until ExcelBuffer.Next = 0;
    end;

    procedure FillCustomerFieldsMappingBuffer(var O365FieldExcelMapping: Record "O365 Field Excel Mapping")
    var
        DummyCustomer: Record Customer;
    begin
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo(Name));
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo("Phone No."));
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo("E-Mail"));
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo(Address));
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo("Post Code"));
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo(City));
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo(County));
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Customer, DummyCustomer.FieldNo("Country/Region Code"));
    end;

    procedure FillItemFieldsMappingBuffer(var O365FieldExcelMapping: Record "O365 Field Excel Mapping")
    var
        DummyItem: Record Item;
    begin
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Item, DummyItem.FieldNo(Description));
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Item, DummyItem.FieldNo("Unit Price"));
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Item, DummyItem.FieldNo("Base Unit of Measure"));
        AddFieldToMapping(O365FieldExcelMapping, DATABASE::Item, DummyItem.FieldNo("Tax Group Code"));
    end;

    local procedure AddFieldToMapping(var O365FieldExcelMapping: Record "O365 Field Excel Mapping"; TableID: Integer; FieldID: Integer)
    begin
        with O365FieldExcelMapping do begin
            Init;
            "Table ID" := TableID;
            "Field ID" := FieldID;
            Insert;
        end;
    end;

    procedure AutomapColumns(var O365FieldExcelMapping: Record "O365 Field Excel Mapping"; var ExcelBuffer: Record "Excel Buffer") MappingFound: Boolean
    begin
        ExcelBuffer.SetRange("Row No.", 1);
        if ExcelBuffer.FindSet then
            repeat
                MappingFound := MappingFound or AdjustColumnMapping(O365FieldExcelMapping, ExcelBuffer);
            until ExcelBuffer.Next = 0;
    end;

    local procedure AdjustColumnMapping(var O365FieldExcelMapping: Record "O365 Field Excel Mapping"; ExcelBuffer: Record "Excel Buffer"): Boolean
    begin
        if O365FieldExcelMapping.FindSet then
            repeat
                O365FieldExcelMapping.CalcFields("Field Name");
                if LowerCase(O365FieldExcelMapping."Field Name") = LowerCase(ExcelBuffer."Cell Value as Text") then begin
                    O365FieldExcelMapping."Excel Column No." := ExcelBuffer."Column No.";
                    O365FieldExcelMapping.Modify();
                    exit(true);
                end;
            until O365FieldExcelMapping.Next = 0;

        exit(false);
    end;

    local procedure GetCustomerConfigTemplate(var ConfigTemplateHeader: Record "Config. Template Header")
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        O365SalesInitialSetup.Get();
        O365SalesInitialSetup.TestField("Default Customer Template");
        ConfigTemplateHeader.Get(O365SalesInitialSetup."Default Customer Template");
    end;

    local procedure GetItemConfigTemplate(var ConfigTemplateHeader: Record "Config. Template Header")
    var
        O365SalesInitialSetup: Record "O365 Sales Initial Setup";
    begin
        O365SalesInitialSetup.Get();
        O365SalesInitialSetup.TestField("Default Item Template");
        ConfigTemplateHeader.Get(O365SalesInitialSetup."Default Item Template");
    end;

    local procedure UpdateRecordFromTemplate(var ConfigTemplateHeader: Record "Config. Template Header"; RecVar: Variant)
    var
        ConfigTemplateMgt: Codeunit "Config. Template Management";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        ConfigTemplateMgt.UpdateRecord(ConfigTemplateHeader, RecRef);
    end;
}

