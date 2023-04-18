#if not CLEAN21
codeunit 2380 "O365 Email Customer Data"
{
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    trigger OnRun()
    begin
    end;

    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        CustomerInformationTxt: Label 'Account Information';
        ContactInformationTxt: Label 'Contact Information';
        SentInvoicesTxt: Label 'Sent Invoices';
        SentInvoiceLinesTxt: Label 'Sent Invoices Details';
        TransactionsTxt: Label 'Transactions';
        DraftInvoicesTxt: Label 'Draft Invoices';
        DraftInvoiceLinesTxt: Label 'Draft Invoices Details';
        QuotesTxt: Label 'Estimates';
        QuoteLinesTxt: Label 'Estimate Details';
        EmailSubjectTxt: Label 'Please find the data we have on file on you in the attached Excel book.', Comment = '%1 = Start Date, %2 =End Date';
        ExportedMsg: Label 'The customer''s data was successfully sent.';
        VATTxt: Label 'VAT Amount';
        SendingEmailMsg: Label 'Sending email...';
        TempLineNumberBuffer: Record "Line Number Buffer" temporary;
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupLoaded: Boolean;
        NotImplementedErr: Label 'No handler implemented for table no. %1.', Comment = '%1 = a number. The text will never be shown to a user. Serves as an internal test.';

    [Scope('OnPrem')]
    procedure ExportDataToExcelAndEmail(var Customer: Record Customer; SendToEmail: Text)
    var
        TempEmailItem: Record "Email Item" temporary;
        Window: Dialog;
        EmailSuccess: Boolean;
        ServerFileName: Text;
        File: File;
        Instream: Instream;
    begin
        ServerFileName := CreateExcelBook(Customer);

        CODEUNIT.Run(CODEUNIT::"O365 Setup Email");

        Window.Open(SendingEmailMsg);
        TempEmailItem.Validate("Send to", CopyStr(SendToEmail, 1, MaxStrLen(TempEmailItem."Send to")));
        TempEmailItem.Validate(Subject, EmailSubjectTxt);
        TempEmailItem.SetBodyText(EmailSubjectTxt);
        File.Open(ServerFileName);
        File.CreateInStream(InStream);
        TempEmailItem.AddAttachment(InStream, StrSubstNo('%1.xlsx', GetDocumentName(Customer)));
        File.Close();
        EmailSuccess := TempEmailItem.Send(true);
        Window.Close();
        if EmailSuccess then
            Message(ExportedMsg);
    end;

    [Scope('OnPrem')]
    procedure CreateExcelBook(var Customer: Record Customer): Text
    var
        FileManagement: Codeunit "File Management";
        ServerFileName: Text;
    begin
        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
        Clear(TempExcelBuffer);

        InsertCustomerData(Customer);

        ServerFileName := FileManagement.ServerTempFileName('xlsx');
        TempExcelBuffer.CreateBook(ServerFileName, CustomerInformationTxt);
        TempExcelBuffer.WriteSheet(CustomerInformationTxt, CompanyName, UserId);
        SetColumnWidts(1, 2, 30);

        InsertContactData(Customer);
        InsertSalesInvoices(Customer);
        InsertSalesInvoiceLines(Customer);
        InsertLedgerEntries(Customer);
        InsertDraftInvoices(Customer);
        InsertDraftInvoiceLines(Customer);
        InsertEstimates(Customer);
        InsertEstimateLines(Customer);

        TempExcelBuffer.CloseBook();
        exit(ServerFileName);
    end;

    local procedure AddColumnToList(var ColNo: Integer; FieldNo: Integer; CustomCaption: Text[80])
    begin
        OnBeforeAddColumnToList(ColNo, FieldNo, CustomCaption);
        ColNo += 1;
        TempLineNumberBuffer."Old Line Number" := ColNo;
        TempLineNumberBuffer."New Line Number" := FieldNo;
        TempLineNumberBuffer.Insert();
        if FieldNo < 0 then begin
            TempNameValueBuffer.ID := FieldNo;
            TempNameValueBuffer.Name := CustomCaption;
            TempNameValueBuffer.Insert();
        end;
    end;

    local procedure AddColumnToListIfNotEmpty(var ColNo: Integer; FieldNo: Integer; Value: Variant; CustomCaption: Text[80])
    var
        NumValue: Decimal;
        DateValue: Date;
        DateTimeValue: DateTime;
    begin
        if DelChr(Format(Value)) = '' then
            exit;
        case true of
            Value.IsInteger, Value.IsDecimal:
                begin
                    NumValue := Value;
                    if NumValue = 0 then
                        exit;
                end;
            Value.IsDate:
                begin
                    DateValue := Value;
                    if DateValue = 0D then
                        exit;
                end;
            Value.IsDateTime:
                begin
                    DateTimeValue := Value;
                    if DateTimeValue = 0DT then
                        exit;
                end;
        end;
        AddColumnToList(ColNo, FieldNo, CustomCaption);
    end;

    local procedure AddRemainingColumnsToList(var ColNo: Integer; TableNo: Integer)
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, TableNo);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        if Field.FindSet() then
            repeat
                if ShouldFieldBeExported(TableNo, Field."No.") then
                    if not FieldExistsInBuffer(Field."No.") then
                        AddColumnToList(ColNo, Field."No.", '');
            until Field.Next() = 0;
    end;

    local procedure AddRemainingColumnsToListIfNotEmpty(var ColNo: Integer; RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            if ShouldFieldBeExported(RecRef.Number, FieldRef.Number) then
                if not FieldExistsInBuffer(FieldRef.Number) then
                    AddColumnToListIfNotEmpty(ColNo, FieldRef.Number, FieldRef.Value, '');
        end;
    end;

    local procedure FieldExistsInBuffer(FieldNo: Integer): Boolean
    var
        Found: Boolean;
    begin
        TempLineNumberBuffer.SetRange("New Line Number", FieldNo);
        Found := not TempLineNumberBuffer.IsEmpty();
        TempLineNumberBuffer.SetRange("New Line Number");
        exit(Found);
    end;

    local procedure ShouldFieldBeExported(TableNo: Integer; FieldNo: Integer): Boolean
    var
        "Field": Record "Field";
        DataSensitivity: Record "Data Sensitivity";
    begin
        if not Field.Get(TableNo, FieldNo) then
            exit(false);
        if Field.DataClassification in [Field.DataClassification::AccountData, Field.DataClassification::SystemMetadata] then
            exit(false);
        if Field.ObsoleteState <> Field.ObsoleteState::No then
            exit(false);
        if Field.Class <> Field.Class::Normal then
            exit(false);
        if DataSensitivity.Get(CompanyName, TableNo, FieldNo) then
            if DataSensitivity."Data Sensitivity" = DataSensitivity."Data Sensitivity"::"Company Confidential" then
                exit(false);
        exit(not (Field.Type in [Field.Type::BLOB, Field.Type::GUID, Field.Type::Media, Field.Type::MediaSet, Field.Type::RecordID]));
    end;

    local procedure WriteHeaderFields(RowNo: Integer; TableNo: Integer)
    var
        "Field": Record "Field";
    begin
        if TempLineNumberBuffer.FindSet() then
            repeat
                if TempLineNumberBuffer."New Line Number" > 0 then begin
                    Field.Get(TableNo, TempLineNumberBuffer."New Line Number");
                    EnterCell(RowNo, TempLineNumberBuffer."Old Line Number", Field."Field Caption", true);
                end else begin
                    TempNameValueBuffer.Get(TempLineNumberBuffer."New Line Number");
                    EnterCell(RowNo, TempLineNumberBuffer."Old Line Number", TempNameValueBuffer.Name, true);
                end;
            until TempLineNumberBuffer.Next() = 0;
    end;

    local procedure WriteHeaderFieldsAsColumn(ColNo: Integer; TableNo: Integer)
    var
        "Field": Record "Field";
    begin
        if TempLineNumberBuffer.FindSet() then
            repeat
                if TempLineNumberBuffer."New Line Number" > 0 then begin
                    Field.Get(TableNo, TempLineNumberBuffer."New Line Number");
                    EnterCell(TempLineNumberBuffer."Old Line Number", ColNo, Field."Field Caption", true);
                end else begin
                    TempNameValueBuffer.Get(TempLineNumberBuffer."New Line Number");
                    EnterCell(TempLineNumberBuffer."Old Line Number", ColNo, TempNameValueBuffer.Name, true);
                end;
            until TempLineNumberBuffer.Next() = 0;
    end;

    local procedure WriteDataFields(RowNo: Integer; RecRef: RecordRef)
    var
        FieldRef: FieldRef;
    begin
        if TempLineNumberBuffer.FindSet() then
            repeat
                if TempLineNumberBuffer."New Line Number" > 0 then begin
                    FieldRef := RecRef.Field(TempLineNumberBuffer."New Line Number");
                    if (FieldRef.Class = FieldClass::FlowField) or (FieldRef.Type = FieldType::BLOB) then
                        FieldRef.CalcField();
                    EnterCell(RowNo, TempLineNumberBuffer."Old Line Number", FieldRef.Value, false);
                end else
                    EnterCell(
                      RowNo, TempLineNumberBuffer."Old Line Number",
                      GetCustomValue(RecRef, TempLineNumberBuffer."New Line Number"), false);
            until TempLineNumberBuffer.Next() = 0;
    end;

    local procedure WriteDataFieldsAsColumn(ColNo: Integer; RecRef: RecordRef)
    var
        FieldRef: FieldRef;
    begin
        if TempLineNumberBuffer.FindSet() then
            repeat
                if TempLineNumberBuffer."New Line Number" > 0 then begin
                    FieldRef := RecRef.Field(TempLineNumberBuffer."New Line Number");
                    if (FieldRef.Class = FieldClass::FlowField) or (FieldRef.Type = FieldType::BLOB) then
                        FieldRef.CalcField();
                    EnterCell(TempLineNumberBuffer."Old Line Number", ColNo, FieldRef.Value, false);
                end else
                    EnterCell(
                      TempLineNumberBuffer."Old Line Number", ColNo,
                      GetCustomValue(RecRef, TempLineNumberBuffer."New Line Number"), false);
            until TempLineNumberBuffer.Next() = 0;
    end;

    local procedure WriteToSheet(var RecRef: RecordRef; SheetName: Text)
    var
        RowNo: Integer;
    begin
        EnterCell(1, 1, SheetName, true);
        RowNo := 3;
        WriteHeaderFields(RowNo, RecRef.Number);
        // Fields
        repeat
            RowNo += 1;
            WriteDataFields(RowNo, RecRef);
        until RecRef.Next() = 0;

        TempExcelBuffer.SelectOrAddSheet(SheetName);
        TempExcelBuffer.WriteAllToCurrentSheet(TempExcelBuffer);
        SetColumnWidts(1, TempLineNumberBuffer.Count, 25);
    end;

    local procedure ClearBuffers()
    begin
        TempExcelBuffer.DeleteAll();
        TempLineNumberBuffer.DeleteAll();
        TempNameValueBuffer.DeleteAll();
    end;

    local procedure GetCustomValue(var RecRef: RecordRef; CustomFieldNo: Integer) Result: Text
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustomValue(RecRef, CustomFieldNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case RecRef.Number of
            DATABASE::"Sales Invoice Header":
                exit(GetCustomValueForSalesInvoiceHeader(RecRef, CustomFieldNo));
            DATABASE::"Sales Invoice Line":
                exit(GetCustomValueForSalesInvoiceLine(RecRef, CustomFieldNo));
            DATABASE::"Sales Header":
                exit(GetCustomValueForUnpostedSalesHeader(RecRef, CustomFieldNo));
            DATABASE::"Sales Line":
                exit(GetCustomValueForUnpostedSalesLine(RecRef, CustomFieldNo));
            else
                Error(NotImplementedErr, RecRef.Number)
        end;
    end;

    local procedure GetCustomValueForSalesInvoiceHeader(var RecRef: RecordRef; CustomFieldNo: Integer): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        RecRef.SetTable(SalesInvoiceHeader);
        case CustomFieldNo of
            -1: // VAT
                begin
                    SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
                    exit(Format(SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount));
                end;
            -2: // WorkDescription
                exit(SalesInvoiceHeader.GetWorkDescription());
        end;
    end;

    local procedure GetCustomValueForSalesInvoiceLine(var RecRef: RecordRef; CustomFieldNo: Integer): Text
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        RecRef.SetTable(SalesInvoiceLine);
        case CustomFieldNo of
            -1: // VAT
                exit(Format(SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount));
        end;
    end;

    local procedure GetCustomValueForUnpostedSalesHeader(var RecRef: RecordRef; CustomFieldNo: Integer): Text
    var
        SalesHeader: Record "Sales Header";
    begin
        RecRef.SetTable(SalesHeader);
        case CustomFieldNo of
            -1: // VAT
                begin
                    SalesHeader.CalcFields(Amount, "Amount Including VAT");
                    exit(Format(SalesHeader."Amount Including VAT" - SalesHeader.Amount));
                end;
            -2: // WorkDescription
                exit(SalesHeader.GetWorkDescription());
        end;
    end;

    local procedure GetCustomValueForUnpostedSalesLine(var RecRef: RecordRef; CustomFieldNo: Integer): Text
    var
        SalesLine: Record "Sales Line";
    begin
        RecRef.SetTable(SalesLine);
        case CustomFieldNo of
            -1: // VAT
                exit(Format(SalesLine."Amount Including VAT" - SalesLine.Amount));
        end;
    end;

    local procedure InsertCustomerData(var Customer: Record Customer)
    var
        RecRef: RecordRef;
        RowNo: Integer;
    begin
        ClearBuffers();

        with Customer do begin
            // Header
            EnterCell(1, 1, CustomerInformationTxt, true);

            RowNo := 2;
            // Fields
            AddColumnToListIfNotEmpty(RowNo, FieldNo("No."), "No.", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo(Name), Name, '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Name 2"), "Name 2", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo(Address), Address, '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Address 2"), "Address 2", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo(City), City, '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Post Code"), "Post Code", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo(County), County, '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Country/Region Code"), "Country/Region Code", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo(Contact), Contact, '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Phone No."), "Phone No.", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("E-Mail"), "E-Mail", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Home Page"), "Home Page", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Currency Code"), "Currency Code", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Language Code"), "Language Code", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Payment Terms Code"), "Payment Terms Code", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Payment Method Code"), "Payment Method Code", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Fax No."), "Fax No.", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("VAT Registration No."), "VAT Registration No.", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo(GLN), GLN, '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Tax Area Code"), "Tax Area Code", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Tax Liable"), "Tax Liable", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Last Modified Date Time"), "Last Modified Date Time", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Bill-to Customer No."), "Bill-to Customer No.", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Primary Contact No."), "Primary Contact No.", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Contact Type"), "Contact Type", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Balance (LCY)"), "Balance (LCY)", '');
        end;
        RecRef.GetTable(Customer);
        AddRemainingColumnsToListIfNotEmpty(RowNo, RecRef);
        WriteHeaderFieldsAsColumn(1, DATABASE::Customer);
        WriteDataFieldsAsColumn(2, RecRef);
    end;

    local procedure InsertContactData(var Customer: Record Customer)
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        RecRef: RecordRef;
        RowNo: Integer;
    begin
        ClearBuffers();

        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        if not ContactBusinessRelation.FindFirst() then
            exit;
        // NB. There can only be one contact for one customer
        with Contact do begin
            if not Get(ContactBusinessRelation."Contact No.") then
                exit;

            // Header
            EnterCell(1, 1, ContactInformationTxt, true);
            RowNo := 2;
            // Fields
            AddColumnToListIfNotEmpty(RowNo, FieldNo("No."), "No.", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo(Name), Name, '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Name 2"), "Name 2", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo(Address), Address, '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Address 2"), "Address 2", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo(City), City, '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Post Code"), "Post Code", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo(County), County, '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Country/Region Code"), "Country/Region Code", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Phone No."), "Phone No.", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("E-Mail"), "E-Mail", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Home Page"), "Home Page", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Currency Code"), GetCurrencyCode("Currency Code"), '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Language Code"), "Language Code", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Fax No."), "Fax No.", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("VAT Registration No."), "VAT Registration No.", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo(Type), Type, '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("First Name"), "First Name", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Middle Name"), "Middle Name", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo(Surname), Surname, '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Job Title"), "Job Title", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Mobile Phone No."), "Mobile Phone No.", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("E-Mail 2"), "E-Mail 2", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Last Date Modified"), "Last Date Modified", '');
            AddColumnToListIfNotEmpty(RowNo, FieldNo("Last Time Modified"), "Last Time Modified", '');
        end;
        RecRef.GetTable(Contact);
        AddRemainingColumnsToListIfNotEmpty(RowNo, RecRef);
        WriteHeaderFieldsAsColumn(1, DATABASE::Contact);
        WriteDataFieldsAsColumn(2, RecRef);
        SetColumnWidts(1, 2, 30);
    end;

    local procedure InsertSalesInvoices(var Customer: Record Customer)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RecRef: RecordRef;
        ColNo: Integer;
    begin
        ClearBuffers();

        with SalesInvoiceHeader do begin
            SetRange("Sell-to Customer No.", Customer."No.");
            if not FindFirst() then
                exit;

            AddColumnToList(ColNo, FieldNo("No."), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Customer No."), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Name"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Name 2"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Address"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Address 2"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to City"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to County"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Country/Region Code"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Contact"), '');
            AddColumnToList(ColNo, FieldNo("VAT Registration No."), '');
            AddColumnToList(ColNo, FieldNo("Tax Area Code"), '');
            AddColumnToList(ColNo, FieldNo("Tax Liable"), '');
            AddColumnToList(ColNo, FieldNo("Document Date"), '');
            AddColumnToList(ColNo, FieldNo("Posting Date"), '');
            AddColumnToList(ColNo, FieldNo("Due Date"), '');
            AddColumnToList(ColNo, FieldNo("Payment Terms Code"), '');
            AddColumnToList(ColNo, -2, FieldCaption("Work Description"));
            AddColumnToList(ColNo, FieldNo("Currency Code"), '');
            AddColumnToList(ColNo, FieldNo(Amount), '');
            AddColumnToList(ColNo, -1, VATTxt);
            AddColumnToList(ColNo, FieldNo("Amount Including VAT"), '');
            AddColumnToList(ColNo, FieldNo("Invoice Discount Amount"), '');
            AddColumnToList(ColNo, FieldNo("Posting Description"), '');
            AddColumnToList(ColNo, FieldNo(Cancelled), '');
            AddRemainingColumnsToList(ColNo, DATABASE::"Sales Invoice Header");
        end;

        RecRef.GetTable(SalesInvoiceHeader);
        WriteToSheet(RecRef, SentInvoicesTxt);
    end;

    local procedure InsertSalesInvoiceLines(var Customer: Record Customer)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        RecRef: RecordRef;
        ColNo: Integer;
    begin
        ClearBuffers();

        with SalesInvoiceLine do begin
            SetRange("Sell-to Customer No.", Customer."No.");
            if not FindFirst() then
                exit;

            AddColumnToList(ColNo, FieldNo("Posting Date"), '');
            AddColumnToList(ColNo, FieldNo("Document No."), '');
            AddColumnToList(ColNo, FieldNo("No."), '');
            AddColumnToList(ColNo, FieldNo(Description), '');
            AddColumnToList(ColNo, FieldNo(Quantity), '');
            AddColumnToList(ColNo, FieldNo("Unit of Measure"), '');
            AddColumnToList(ColNo, FieldNo("Unit Price"), '');
            AddColumnToList(ColNo, FieldNo("Line Discount Amount"), '');
            AddColumnToList(ColNo, FieldNo("Line Amount"), '');
            AddColumnToList(ColNo, FieldNo(Amount), '');
            AddColumnToList(ColNo, -1, VATTxt);
            AddColumnToList(ColNo, FieldNo("Amount Including VAT"), '');
            AddColumnToList(ColNo, FieldNo("Description 2"), '');
            AddColumnToList(ColNo, FieldNo("Tax Group Code"), '');
            AddColumnToList(ColNo, FieldNo("VAT %"), '');
            AddColumnToList(ColNo, FieldNo("VAT Clause Code"), '');
            AddColumnToList(ColNo, FieldNo("VAT Base Amount"), '');
            AddColumnToList(ColNo, FieldNo("Tax Category"), '');
            AddColumnToList(ColNo, FieldNo("Tax Area Code"), '');
            AddColumnToList(ColNo, FieldNo("Tax Liable"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Customer No."), '');
            AddColumnToList(ColNo, FieldNo("Sell-to Customer No."), '');
            AddColumnToList(ColNo, FieldNo("Price description"), '');
            AddRemainingColumnsToList(ColNo, DATABASE::"Sales Invoice Line");
        end;

        RecRef.GetTable(SalesInvoiceLine);
        WriteToSheet(RecRef, SentInvoiceLinesTxt);
    end;

    local procedure InsertLedgerEntries(var Customer: Record Customer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
        ColNo: Integer;
    begin
        ClearBuffers();

        with CustLedgerEntry do begin
            SetRange("Customer No.", Customer."No.");
            if not FindFirst() then
                exit;

            AddColumnToList(ColNo, FieldNo("Document Date"), '');
            AddColumnToList(ColNo, FieldNo("Document No."), '');
            AddColumnToList(ColNo, FieldNo("Document Type"), '');
            AddColumnToList(ColNo, FieldNo(Description), '');
            AddColumnToList(ColNo, FieldNo("Currency Code"), '');
            AddColumnToList(ColNo, FieldNo(Amount), '');
            AddColumnToList(ColNo, FieldNo("Due Date"), '');
            AddColumnToList(ColNo, FieldNo("Remaining Amount"), '');
            AddColumnToList(ColNo, FieldNo(Open), '');
            AddColumnToList(ColNo, FieldNo("Posting Date"), '');
            AddColumnToList(ColNo, FieldNo("Closed at Date"), '');
            AddColumnToList(ColNo, FieldNo("Closed by Amount"), '');
            AddColumnToList(ColNo, FieldNo("Payment Method Code"), '');
            AddColumnToList(ColNo, FieldNo("Sell-to Customer No."), '');
            AddRemainingColumnsToList(ColNo, DATABASE::"Cust. Ledger Entry");
        end;

        RecRef.GetTable(CustLedgerEntry);
        WriteToSheet(RecRef, TransactionsTxt);
    end;

    local procedure InsertDraftInvoices(var Customer: Record Customer)
    begin
        InsertUnpostedSalesHeaders(Customer, "Sales Document Type"::Invoice, DraftInvoicesTxt);
    end;

    local procedure InsertDraftInvoiceLines(var Customer: Record Customer)
    begin
        InsertUnpostedSalesLines(Customer, "Sales Document Type"::Invoice, DraftInvoiceLinesTxt);
    end;

    local procedure InsertEstimates(var Customer: Record Customer)
    var
        DummySalesHeader: Record "Sales Header";
    begin
        InsertUnpostedSalesHeaders(Customer, DummySalesHeader."Document Type"::Quote, QuotesTxt);
    end;

    local procedure InsertEstimateLines(var Customer: Record Customer)
    begin
        InsertUnpostedSalesLines(Customer, "Sales Document Type"::Quote, QuoteLinesTxt);
    end;

    local procedure InsertUnpostedSalesHeaders(var Customer: Record Customer; DocumentType: Enum "Sales Document Type"; SheetName: Text)
    var
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
        ColNo: Integer;
    begin
        ClearBuffers();

        with SalesHeader do begin
            SetRange("Document Type", DocumentType);
            SetRange("Sell-to Customer No.", Customer."No.");
            if not FindFirst() then
                exit;

            AddColumnToList(ColNo, FieldNo("No."), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Customer No."), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Name"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Name 2"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Address"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Address 2"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to City"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to County"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Country/Region Code"), '');
            AddColumnToList(ColNo, FieldNo("Bill-to Contact"), '');
            AddColumnToList(ColNo, FieldNo("VAT Registration No."), '');
            AddColumnToList(ColNo, FieldNo("Tax Area Code"), '');
            AddColumnToList(ColNo, FieldNo("Tax Liable"), '');
            AddColumnToList(ColNo, FieldNo("Document Date"), '');
            AddColumnToList(ColNo, FieldNo("Posting Date"), '');
            AddColumnToList(ColNo, FieldNo("Due Date"), '');
            AddColumnToList(ColNo, FieldNo("Payment Terms Code"), '');
            AddColumnToList(ColNo, -2, FieldCaption("Work Description"));
            AddColumnToList(ColNo, FieldNo("Currency Code"), '');
            AddColumnToList(ColNo, FieldNo(Amount), '');
            AddColumnToList(ColNo, -1, VATTxt);
            AddColumnToList(ColNo, FieldNo("Amount Including VAT"), '');
            AddColumnToList(ColNo, FieldNo("Invoice Discount Amount"), '');
            AddColumnToList(ColNo, FieldNo("Posting Description"), '');
            AddColumnToList(ColNo, FieldNo(Status), '');
            AddColumnToList(ColNo, FieldNo("Last Email Sent Time"), '');
            AddColumnToList(ColNo, FieldNo("Last Email Sent Status"), '');
            AddRemainingColumnsToList(ColNo, DATABASE::"Sales Header");
        end;

        RecRef.GetTable(SalesHeader);
        WriteToSheet(RecRef, SheetName);
    end;

    local procedure InsertUnpostedSalesLines(var Customer: Record Customer; DocumentType: Enum "Sales Document Type"; SheetName: Text)
    var
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
        Colno: Integer;
    begin
        ClearBuffers();

        with SalesLine do begin
            SetRange("Sell-to Customer No.", Customer."No.");
            SetRange("Document Type", DocumentType);
            if not FindFirst() then
                exit;

            AddColumnToList(Colno, FieldNo("Posting Date"), '');
            AddColumnToList(Colno, FieldNo("Document No."), '');
            AddColumnToList(Colno, FieldNo("No."), '');
            AddColumnToList(Colno, FieldNo(Description), '');
            AddColumnToList(Colno, FieldNo(Quantity), '');
            AddColumnToList(Colno, FieldNo("Unit of Measure"), '');
            AddColumnToList(Colno, FieldNo("Unit Price"), '');
            AddColumnToList(Colno, FieldNo("Line Discount Amount"), '');
            AddColumnToList(Colno, FieldNo("Line Amount"), '');
            AddColumnToList(Colno, FieldNo("Tax Group Code"), '');
            AddColumnToList(Colno, FieldNo("VAT %"), '');
            AddColumnToList(Colno, FieldNo("Currency Code"), '');
            AddColumnToList(Colno, FieldNo(Amount), '');
            AddColumnToList(Colno, -1, VATTxt);
            AddColumnToList(Colno, FieldNo("Amount Including VAT"), '');
            AddColumnToList(Colno, FieldNo("Tax Category"), '');
            AddColumnToList(Colno, FieldNo("Tax Liable"), '');
            AddColumnToList(Colno, FieldNo("VAT Calculation Type"), '');
            AddColumnToList(Colno, FieldNo("VAT Identifier"), '');
            AddColumnToList(Colno, FieldNo("VAT Base Amount"), '');
            AddColumnToList(Colno, FieldNo("Sell-to Customer No."), '');
            AddColumnToList(Colno, FieldNo("Bill-to Customer No."), '');
            AddColumnToList(Colno, FieldNo("Line No."), '');
            AddColumnToList(Colno, FieldNo("Unit of Measure Code"), '');
            AddColumnToList(Colno, FieldNo("Description 2"), '');
            AddColumnToList(Colno, FieldNo("Price description"), '');
            AddRemainingColumnsToList(Colno, DATABASE::"Sales Line");
        end;

        RecRef.GetTable(SalesLine);
        WriteToSheet(RecRef, SheetName);
    end;

    local procedure EnterCell(RowNo: Integer; ColumnNo: Integer; CellValue: Variant; IsBold: Boolean)
    begin
        TempExcelBuffer.EnterCell(TempExcelBuffer, RowNo, ColumnNo, CellValue, IsBold, false, false);
    end;

    local procedure SetColumnWidts(StartColNo: Integer; NoOfCols: Integer; NewWidth: Decimal)
    var
        DummyExcelBuffer: Record "Excel Buffer";
        i: Integer;
    begin
        if (StartColNo < 1) or (NoOfCols < 1) or (NewWidth < 1) then
            exit;
        for i := StartColNo to StartColNo + NoOfCols - 1 do begin
            DummyExcelBuffer.Validate("Column No.", i);
            TempExcelBuffer.SetColumnWidth(DummyExcelBuffer.xlColID, NewWidth);
        end;
    end;

    local procedure GetDocumentName(var Customer: Record Customer): Text
    begin
        if Customer.Name <> '' then
            exit(Customer.Name);
        exit(CustomerInformationTxt);
    end;

    local procedure GetCurrencyCode(DocCurrencyCode: Code[10]): Code[10]
    begin
        if DocCurrencyCode <> '' then
            exit(DocCurrencyCode);

        if not GeneralLedgerSetupLoaded then
            GeneralLedgerSetup.Get();
        GeneralLedgerSetupLoaded := true;
        exit(GeneralLedgerSetup."LCY Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustomValue(var RecRef: RecordRef; CustomFieldNo: Integer; var Result: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddColumnToList(var ColNo: Integer; var FieldNo: Integer; var CustomCaption: Text[80])
    begin
    end;
}
#endif

