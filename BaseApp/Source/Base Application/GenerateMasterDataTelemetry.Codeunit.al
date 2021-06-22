codeunit 1353 "Generate Master Data Telemetry"
{

    trigger OnRun()
    begin
        OnMasterDataTelemetry;
    end;

    var
        AlCompanyMasterdataCategoryTxt: Label 'AL Company Masterdata', Locked = true;
        MasterdataTelemetryMessageTxt: Label 'CompanyGUID: %1, IsEvaluationCompany: %2, IsDemoCompany: %3, Customers: %4, Vendors: %5, Items: %6, G/L Accounts: %7, Contacts: %8', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, 1353, 'OnMasterDataTelemetry', '', true, true)]
    local procedure SendTelemetryOnMasterDataTelemetry()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        GLAccount: Record "G/L Account";
        Contact: Record Contact;
        Company: Record Company;
        TableInformation: Record "Table Information";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        CustomerCount: Integer;
        VendorCount: Integer;
        ItemCount: Integer;
        GLAccountCount: Integer;
        ContactCount: Integer;
        TelemetryMsg: Text;
    begin
        if Company.Get(CompanyName) then;
        TableInformation.SetRange("Company Name", CompanyName);

        CustomerCount := GetNoOfRecords(TableInformation, Customer.TableName);
        VendorCount := GetNoOfRecords(TableInformation, Vendor.TableName);
        ItemCount := GetNoOfRecords(TableInformation, Item.TableName);
        GLAccountCount := GetNoOfRecords(TableInformation, GLAccount.TableName);
        ContactCount := GetNoOfRecords(TableInformation, Contact.TableName);

        TelemetryMsg := StrSubstNo(MasterdataTelemetryMessageTxt,
            Company.Id, Format(Company."Evaluation Company", 0, 9), Format(CompanyInformationMgt.IsDemoCompany, 0, 9),
            CustomerCount, VendorCount, ItemCount, GLAccountCount, ContactCount);

        SendTraceTag('000018V', AlCompanyMasterdataCategoryTxt, VERBOSITY::Normal, TelemetryMsg, DATACLASSIFICATION::SystemMetadata);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMasterDataTelemetry()
    begin
    end;

    local procedure GetNoOfRecords(TableInformation: Record "Table Information"; TableName: Text[30]): Integer
    begin
        TableInformation.SetRange("Table Name", TableName);
        if TableInformation.FindFirst then
            exit(TableInformation."No. of Records");
        exit(-1);
    end;
}

