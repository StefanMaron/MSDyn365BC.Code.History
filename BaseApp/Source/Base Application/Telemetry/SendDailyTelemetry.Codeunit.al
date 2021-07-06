codeunit 1355 "Send Daily Telemetry"
{
    var
        TableInformation: Record "Table Information";
        AlCompanyActivityCategoryTxt: Label 'AL Company Activity', Locked = true;
        TraceTagTelemetryMsg: Label '%1: %2', Comment = '%1 = Record Name; %2 = Record Count';
        GLEntriesLbl: Label 'Number of G/L Entries in the Income Statement: %1', Locked = true;
        AlCompanyMasterdataCategoryTxt: Label 'AL Company Masterdata', Locked = true;
        MasterdataTelemetryMessageTxt: Label 'CompanyGUID: %1, IsEvaluationCompany: %2, IsDemoCompany: %3, Customers: %4, Vendors: %5, Items: %6, G/L Accounts: %7, Contacts: %8', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Management", 'OnSendDailyTelemetry', '', true, true)]
    local procedure SendDailyTelemetry()
    begin
        SendMasterDataTelemetry();
        SendActivityTelemetry();
        EmitCountForGLEntriesInIncomeStatement();
    end;

    local procedure SendMasterDataTelemetry()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        GLAccount: Record "G/L Account";
        Contact: Record Contact;
        Company: Record Company;
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        CustomerCount: Integer;
        VendorCount: Integer;
        ItemCount: Integer;
        GLAccountCount: Integer;
        ContactCount: Integer;
        TelemetryMsg: Text;
    begin
        if not Company.Get(CompanyName()) then
            exit;
        TableInformation.SetRange("Company Name", CompanyName());

        CustomerCount := GetNoOfRecords(Customer.TableName());
        VendorCount := GetNoOfRecords(Vendor.TableName());
        ItemCount := GetNoOfRecords(Item.TableName());
        GLAccountCount := GetNoOfRecords(GLAccount.TableName());
        ContactCount := GetNoOfRecords(Contact.TableName());

        TelemetryMsg := StrSubstNo(MasterdataTelemetryMessageTxt,
            Company.Id, Format(Company."Evaluation Company", 0, 9), Format(CompanyInformationMgt.IsDemoCompany(), 0, 9),
            CustomerCount, VendorCount, ItemCount, GLAccountCount, ContactCount);

        Session.LogMessage('000018V', TelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AlCompanyMasterdataCategoryTxt);
    end;

    local procedure SendActivityTelemetry()
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        PurchInvLine: Record "Purch. Inv. Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        Location: Record Location;
        FixedAsset: Record "Fixed Asset";
        Employee: Record Employee;
        Resource: Record Resource;
        Job: Record Job;
        ServiceItem: Record "Service Item";
        ProductionOrder: Record "Production Order";
        MachineCenter: Record "Machine Center";
        Bin: Record Bin;
        ItemTrackingCode: Record "Item Tracking Code";
        GLRegister: Record "G/L Register";
        ItemRegister: Record "Item Register";
        ResourceRegister: Record "Resource Register";
        JobRegister: Record "Job Register";
        CostRegister: Record "Cost Register";
        CreditTransferRegister: Record "Credit Transfer Register";
        DataMigratorRegistration: Record "Data Migrator Registration";
        FARegister: Record "FA Register";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        ServiceRegister: Record "Service Register";
        ServiceDocumentRegister: Record "Service Document Register";
        WarehouseRegister: Record "Warehouse Register";
        ICPartner: Record "IC Partner";
        GLBudgetName: Record "G/L Budget Name";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        UserGroup: Record "User Group";
        PermissionSetBuffer: Record "Permission Set Buffer";
        BOMComponent: Record "BOM Component";
        VATEntry: Record "VAT Entry";
    begin
        TableInformation.SetRange("Company Name", CompanyName());

        EmitTelemetryOnRecordCount(GLEntry.TableName(), '0000861');
        EmitTelemetryOnRecordCount(SalesHeader.TableName(), '0000862');
        EmitTelemetryOnRecordCount(PurchaseHeader.TableName(), '0000863');
        EmitTelemetryOnRecordCount(SalesInvoiceHeader.TableName(), '0000864');
        EmitTelemetryOnRecordCount(PurchInvHeader.TableName(), '0000865');

        EmitTelemetryOnRecordCount(SalesInvoiceLine.TableName(), '0000866');
        EmitTelemetryOnRecordCount(PurchInvLine.TableName(), '0000867');
        EmitTelemetryOnRecordCount(Dimension.TableName(), '0000868');
        EmitTelemetryOnRecordCount(DimensionValue.TableName(), '0000869');
        EmitTelemetryOnRecordCount(Location.TableName(), '000086A');
        EmitTelemetryOnRecordCount(FixedAsset.TableName(), '000086B');
        EmitTelemetryOnRecordCount(Employee.TableName(), '000086C');
        EmitTelemetryOnRecordCount(Resource.TableName(), '000086D');
        EmitTelemetryOnRecordCount(Job.TableName(), '000086E');
        EmitTelemetryOnRecordCount(ServiceItem.TableName(), '000086F');
        EmitTelemetryOnRecordCount(ProductionOrder.TableName(), '000086G');
        EmitTelemetryOnRecordCount(MachineCenter.TableName(), '000086H');
        EmitTelemetryOnRecordCount(Bin.TableName(), '000086I');
        EmitTelemetryOnRecordCount(ItemTrackingCode.TableName(), '000086J');

        EmitTelemetryOnRecordCount(GLRegister.TableName(), '000086K');
        EmitTelemetryOnRecordCount(ItemRegister.TableName(), '000086L');
        EmitTelemetryOnRecordCount(ResourceRegister.TableName(), '000086M');
        EmitTelemetryOnRecordCount(JobRegister.TableName(), '000086N');
        EmitTelemetryOnRecordCount(CostRegister.TableName(), '000086O');
        EmitTelemetryOnRecordCount(CreditTransferRegister.TableName(), '000086P');
        EmitTelemetryOnRecordCount(DataMigratorRegistration.TableName(), '000086Q');
        EmitTelemetryOnRecordCount(FARegister.TableName(), '000086R');
        EmitTelemetryOnRecordCount(RegisteredWhseActivityHdr.TableName(), '000086S');
        EmitTelemetryOnRecordCount(ServiceRegister.TableName(), '000086T');
        EmitTelemetryOnRecordCount(ServiceDocumentRegister.TableName(), '000086U');
        EmitTelemetryOnRecordCount(WarehouseRegister.TableName(), '000086V');

        EmitTelemetryOnRecordCount(ICPartner.TableName(), '000086W');
        EmitTelemetryOnRecordCount(GLBudgetName.TableName(), '000086X');
        EmitTelemetryOnRecordCount(ServiceContractHeader.TableName(), '000086Y');
        EmitTelemetryOnRecordCount(ServiceHeader.TableName(), '000086Z');
        EmitTelemetryOnRecordCount(UserGroup.TableName(), '0000870');
        EmitTelemetryOnRecordCount(PermissionSetBuffer.TableName(), '0000871');
        EmitTelemetryOnRecordCount(BOMComponent.TableName(), '0000872');
        EmitTelemetryOnRecordCount(VATEntry.TableName(), '0000BGB');
    end;

    local procedure EmitCountForGLEntriesInIncomeStatement()
    var
        GLEntry: Record "G/L Entry";
        GLAccount: Record "G/L Account";
        GLEntryCount: Integer;
    begin
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        if GLAccount.FindSet() then
            repeat
                GLEntry.SetRange("G/L Account No.", GLAccount."No.");

                GLEntryCount += GLEntry.Count();
            until GLAccount.Next() = 0;

        Session.LogMessage('0000F0M', StrSubstNo(GLEntriesLbl, GLEntryCount), Verbosity::Normal,
            DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'CompanyName', CompanyName());
    end;

    local procedure GetNoOfRecords(TableName: Text): Integer
    begin
        TableInformation.SetRange("Table Name", CopyStr(TableName, 1, MaxStrLen(TableInformation."Table Name")));
        if TableInformation.FindFirst() then
            exit(TableInformation."No. of Records");
        exit(-1);
    end;

    local procedure EmitTraceTag(RecordCount: Integer; RecordName: Text; Tag: Text)
    var
        TraceTagMessage: Text;
    begin
        TraceTagMessage := StrSubstNo(TraceTagTelemetryMsg, RecordName, RecordCount);
        Session.LogMessage(Tag, TraceTagMessage, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AlCompanyActivityCategoryTxt);
    end;

    internal procedure EmitTelemetryOnRecordCount(RecordName: Text; Tag: Text)
    var
        RecordCount: Integer;
    begin
        RecordCount := GetNoOfRecords(RecordName);
        EmitTraceTag(RecordCount, RecordName, Tag);
    end;
}

