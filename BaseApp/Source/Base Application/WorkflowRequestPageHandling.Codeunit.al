codeunit 1522 "Workflow Request Page Handling"
{

    trigger OnRun()
    begin
    end;

    var
        PurchaseDocumentCodeTxt: Label 'PURCHDOC', Locked = true;
        PurchaseDocumentDescTxt: Label 'Purchase Document';
        SalesDocumentCodeTxt: Label 'SALESDOC', Locked = true;
        SalesDocumentDescTxt: Label 'Sales Document';
        IncomingDocumentCodeTxt: Label 'INCOMINGDOC', Locked = true;
        IncomingDocumentDescTxt: Label 'Incoming Document';

    procedure CreateEntitiesAndFields()
    begin
        InsertRequestPageEntities;
        InsertRequestPageFields;
    end;

    procedure AssignEntitiesToWorkflowEvents()
    begin
        AssignEntityToWorkflowEvent(DATABASE::"Purchase Header", PurchaseDocumentCodeTxt);
        AssignEntityToWorkflowEvent(DATABASE::"Sales Header", SalesDocumentCodeTxt);
        AssignEntityToWorkflowEvent(DATABASE::"Incoming Document Attachment", IncomingDocumentCodeTxt);
        AssignEntityToWorkflowEvent(DATABASE::"Incoming Document", IncomingDocumentCodeTxt);
    end;

    local procedure InsertRequestPageEntities()
    begin
        InsertReqPageEntity(
          PurchaseDocumentCodeTxt, PurchaseDocumentDescTxt, DATABASE::"Purchase Header", DATABASE::"Purchase Line");
        InsertReqPageEntity(
          SalesDocumentCodeTxt, SalesDocumentDescTxt, DATABASE::"Sales Header", DATABASE::"Sales Line");
        InsertReqPageEntity(
          IncomingDocumentCodeTxt, IncomingDocumentDescTxt, DATABASE::"Incoming Document Attachment", DATABASE::"Incoming Document");
        InsertReqPageEntity(
          IncomingDocumentCodeTxt, IncomingDocumentDescTxt, DATABASE::"Incoming Document", DATABASE::"Incoming Document Attachment");
    end;

    local procedure InsertReqPageEntity(Name: Code[20]; Description: Text[100]; TableId: Integer; RelatedTableId: Integer)
    begin
        if not FindReqPageEntity(Name, TableId, RelatedTableId) then
            CreateReqPageEntity(Name, Description, TableId, RelatedTableId);
    end;

    local procedure FindReqPageEntity(Name: Code[20]; TableId: Integer; RelatedTableId: Integer): Boolean
    var
        DynamicRequestPageEntity: Record "Dynamic Request Page Entity";
    begin
        DynamicRequestPageEntity.SetRange(Name, Name);
        DynamicRequestPageEntity.SetRange("Table ID", TableId);
        DynamicRequestPageEntity.SetRange("Related Table ID", RelatedTableId);
        exit(DynamicRequestPageEntity.FindFirst);
    end;

    local procedure CreateReqPageEntity(Name: Code[20]; Description: Text[100]; TableId: Integer; RelatedTableId: Integer)
    var
        DynamicRequestPageEntity: Record "Dynamic Request Page Entity";
    begin
        DynamicRequestPageEntity.Init();
        DynamicRequestPageEntity.Name := Name;
        DynamicRequestPageEntity.Description := Description;
        DynamicRequestPageEntity.Validate("Table ID", TableId);
        DynamicRequestPageEntity.Validate("Related Table ID", RelatedTableId);
        DynamicRequestPageEntity.Insert(true);
    end;

    local procedure InsertRequestPageFields()
    begin
        InsertIncomingDocumentReqPageFields;

        InsertPurchaseHeaderReqPageFields;
        InsertPurchaseLineReqPageFields;

        InsertSalesHeaderReqPageFields;
        InsertSalesLineReqPageFields;

        InsertCustomerReqPageFields;
        InsertVendorReqPageFields;

        InsertItemReqPageFields;
        InsertGeneralJournalBatchReqPageFields;
        InsertGeneralJournalLineReqPageFields;

        InsertApprovalEntryReqPageFields;
    end;

    local procedure InsertIncomingDocumentReqPageFields()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        InsertReqPageField(DATABASE::"Incoming Document", IncomingDocument.FieldNo("Created By User ID"));
        InsertReqPageField(DATABASE::"Incoming Document", IncomingDocument.FieldNo(Posted));
        InsertReqPageField(DATABASE::"Incoming Document", IncomingDocument.FieldNo(Status));
    end;

    local procedure InsertPurchaseHeaderReqPageFields()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        InsertReqPageField(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        InsertReqPageField(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Payment Terms Code"));
        InsertReqPageField(DATABASE::"Purchase Header", PurchaseHeader.FieldNo(Amount));
        InsertReqPageField(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Currency Code"));
    end;

    local procedure InsertPurchaseLineReqPageFields()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        InsertReqPageField(DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type));
        InsertReqPageField(DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."));
        InsertReqPageField(DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity));
        InsertReqPageField(DATABASE::"Purchase Line", PurchaseLine.FieldNo("Direct Unit Cost"));
    end;

    local procedure InsertSalesHeaderReqPageFields()
    var
        SalesHeader: Record "Sales Header";
    begin
        InsertReqPageField(DATABASE::"Sales Header", SalesHeader.FieldNo("Sell-to Customer No."));
        InsertReqPageField(DATABASE::"Sales Header", SalesHeader.FieldNo("Payment Terms Code"));
        InsertReqPageField(DATABASE::"Sales Header", SalesHeader.FieldNo(Amount));
        InsertReqPageField(DATABASE::"Sales Header", SalesHeader.FieldNo("Currency Code"));
    end;

    local procedure InsertSalesLineReqPageFields()
    var
        SalesLine: Record "Sales Line";
    begin
        InsertReqPageField(DATABASE::"Sales Line", SalesLine.FieldNo(Type));
        InsertReqPageField(DATABASE::"Sales Line", SalesLine.FieldNo("No."));
        InsertReqPageField(DATABASE::"Sales Line", SalesLine.FieldNo(Quantity));
        InsertReqPageField(DATABASE::"Sales Line", SalesLine.FieldNo("Unit Cost"));
    end;

    local procedure InsertCustomerReqPageFields()
    var
        Customer: Record Customer;
    begin
        InsertReqPageField(DATABASE::Customer, Customer.FieldNo("No."));
        InsertReqPageField(DATABASE::Customer, Customer.FieldNo(Blocked));
        InsertReqPageField(DATABASE::Customer, Customer.FieldNo("Credit Limit (LCY)"));
        InsertReqPageField(DATABASE::Customer, Customer.FieldNo("Payment Method Code"));
        InsertReqPageField(DATABASE::Customer, Customer.FieldNo("Gen. Bus. Posting Group"));
        InsertReqPageField(DATABASE::Customer, Customer.FieldNo("Customer Posting Group"));
    end;

    local procedure InsertItemReqPageFields()
    var
        Item: Record Item;
    begin
        InsertReqPageField(DATABASE::Item, Item.FieldNo("No."));
        InsertReqPageField(DATABASE::Item, Item.FieldNo("Item Category Code"));
        InsertReqPageField(DATABASE::Item, Item.FieldNo("Unit Price"));
    end;

    local procedure InsertGeneralJournalBatchReqPageFields()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        InsertReqPageField(DATABASE::"Gen. Journal Batch", GenJournalBatch.FieldNo(Name));
        InsertReqPageField(DATABASE::"Gen. Journal Batch", GenJournalBatch.FieldNo("Template Type"));
        InsertReqPageField(DATABASE::"Gen. Journal Batch", GenJournalBatch.FieldNo(Recurring));
    end;

    local procedure InsertGeneralJournalLineReqPageFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        InsertReqPageField(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Document Type"));
        InsertReqPageField(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Account Type"));
        InsertReqPageField(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("Account No."));
        InsertReqPageField(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo(Amount));
    end;

    local procedure InsertApprovalEntryReqPageFields()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        InsertReqPageField(DATABASE::"Approval Entry", ApprovalEntry.FieldNo("Pending Approvals"));
    end;

    local procedure InsertReqPageField(TableId: Integer; FieldId: Integer)
    var
        DynamicRequestPageField: Record "Dynamic Request Page Field";
    begin
        if not DynamicRequestPageField.Get(TableId, FieldId) then
            CreateReqPageField(TableId, FieldId);
    end;

    local procedure CreateReqPageField(TableId: Integer; FieldId: Integer)
    var
        DynamicRequestPageField: Record "Dynamic Request Page Field";
    begin
        DynamicRequestPageField.Init();
        DynamicRequestPageField.Validate("Table ID", TableId);
        DynamicRequestPageField.Validate("Field ID", FieldId);
        DynamicRequestPageField.Insert();
    end;

    local procedure AssignEntityToWorkflowEvent(TableID: Integer; DynamicReqPageEntityName: Code[20])
    var
        WorkflowEvent: Record "Workflow Event";
    begin
        WorkflowEvent.SetRange("Table ID", TableID);
        if not WorkflowEvent.IsEmpty then
            WorkflowEvent.ModifyAll("Dynamic Req. Page Entity Name", DynamicReqPageEntityName);
    end;

    local procedure InsertVendorReqPageFields()
    var
        Vendor: Record Vendor;
    begin
        InsertReqPageField(DATABASE::Vendor, Vendor.FieldNo("No."));
    end;
}

